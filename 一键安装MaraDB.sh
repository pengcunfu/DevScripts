#!/bin/bash
# ============================================
# 一键安装 MariaDB 脚本
# 支持: Ubuntu/Debian/CentOS/RHEL
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# MariaDB 配置
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-""}
MARIADB_PORT=${MARIADB_PORT:-3306}
MARIADB_VERSION=${MARIADB_VERSION:-"10.11"}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 root 权限运行"
        info "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        OS="unknown"
    fi
    info "检测到系统: $OS $OS_VERSION"
}

# 检查已安装的 MariaDB
check_existing_mariadb() {
    if command -v mariadb &> /dev/null || command -v mysql &> /dev/null; then
        EXISTING_VERSION=$(mariadb --version 2>/dev/null || mysql --version 2>/dev/null || echo "unknown")
        warn "检测到已安装 MariaDB/MySQL: $EXISTING_VERSION"
        warn "重新安装将删除所有数据库！"
        read -p "是否继续? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            info "取消安装"
            exit 0
        fi
        remove_existing_mariadb
    fi
}

# 卸载现有 MariaDB
remove_existing_mariadb() {
    info "卸载现有 MariaDB/MySQL..."

    # 停止服务
    systemctl stop mariadb 2>/dev/null || true
    systemctl stop mysql 2>/dev/null || true

    # 卸载
    case $OS in
        ubuntu|debian)
            apt-get remove -y mariadb-server mysql-server mariadb-client mysql-client 2>/dev/null || true
            apt-get purge -y mariadb-* mysql-* 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y mariadb-server mariadb mysql-server mysql 2>/dev/null || true
            ;;
    esac

    # 清理配置和数据
    rm -rf /var/lib/mysql
    rm -rf /etc/mysql
    rm -f /etc/my.cnf
    rm -f /etc/my.cnf.d/*.cnf
    rm -rf /var/log/mariadb
    rm -rf /var/log/mysql

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 MariaDB
install_mariadb_debian() {
    info "开始安装 MariaDB $MARIADB_VERSION (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    # 安装依赖
    apt-get install -y software-properties-common curl gnupg

    # 添加 MariaDB 官方仓库
    if [ "$OS" = "ubuntu" ]; then
        curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=$MARIADB_VERSION
    else
        # Debian
        curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=$MARIADB_VERSION --os-type=debian --os-version=$(lsb_release -sc)
    fi

    apt-get update

    # 设置非交互式安装
    export DEBIAN_FRONTEND=noninteractive

    # 安装 MariaDB
    apt-get install -y mariadb-server mariadb-client libmariadb-dev

    info "MariaDB 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 MariaDB
install_mariadb_rhel() {
    info "开始安装 MariaDB $MARIADB_VERSION (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 创建 MariaDB 仓库配置
    cat > /etc/yum.repos.d/MariaDB.repo <<EOF
[mariadb]
name = MariaDB
baseurl = https://mirrors.aliyun.com/mariadb/yum/$MARIADB_VERSION/rhel$(rpm -E %rhel)-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
enabled=1
gpgcheck=1
EOF

    # 安装 MariaDB
    yum install -y MariaDB-server MariaDB-client MariaDB-devel

    info "MariaDB 安装完成"
}

# 安全配置 MariaDB
secure_mariadb() {
    info "安全配置 MariaDB..."

    # 启动服务
    systemctl start mariadb

    if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
        # 使用密码直接配置
        mariadb -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

        # 允许远程连接
        mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" <<EOF
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

        info "Root 密码已设置"
    else
        warn "未设置 root 密码，请运行 mysql_secure_installation 手动配置"
    fi
}

# 配置 MariaDB
configure_mariadb() {
    info "配置 MariaDB..."

    # 创建配置目录
    mkdir -p /etc/mysql/conf.d

    # 创建自定义配置
    cat > /etc/mysql/conf.d/custom.cnf <<EOF
[mysqld]
# 基本设置
port = $MARIADB_PORT
datadir = /var/lib/mysql
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid

# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 网络设置
bind-address = 0.0.0.0
max_connections = 500
max_connect_errors = 100

# 缓存设置
key_buffer_size = 16M
max_allowed_packet = 64M
table_open_cache = 256
sort_buffer_size = 1M
read_buffer_size = 1M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 16M

# InnoDB 设置
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

# 日志设置
log-error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 时区
default-time-zone = '+8:00'

# SQL 模式
sql_mode = STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION

[client]
port = $MARIADB_PORT
socket = /var/run/mysqld/mysqld.sock
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4
EOF

    # 创建日志目录
    mkdir -p /var/log/mysql
    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/log/mysql
    chown mysql:mysql /var/run/mysqld

    info "MariaDB 配置完成"
}

# 启动 MariaDB
start_mariadb() {
    info "启动 MariaDB 服务..."

    # 启用并启动
    systemctl enable mariadb
    systemctl restart mariadb

    # 等待启动
    sleep 3

    # 检查状态
    if systemctl is-active --quiet mariadb; then
        info "MariaDB 服务运行正常"
    else
        error "MariaDB 服务启动失败"
        systemctl status mariadb
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    info "配置防火墙..."

    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${MARIADB_PORT}/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        info "Firewalld 规则已添加"
    elif command -v ufw &> /dev/null; then
        ufw allow ${MARIADB_PORT}/tcp 2>/dev/null || true
        info "UFW 规则已添加"
    fi
}

# 验证安装
verify_installation() {
    info "验证 MariaDB 安装..."

    mariadb --version

    # 检查服务状态
    systemctl status mariadb --no-pager -l

    # 测试连接
    if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
        if mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "SELECT VERSION();" &>/dev/null; then
            info "MariaDB 连接测试成功"
        else
            warn "MariaDB 连接测试失败，请检查密码"
        fi
    fi
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "MariaDB 安装完成！"
    echo "============================================"
    echo ""
    echo "连接信息:"
    echo "  端口: $MARIADB_PORT"
    [ -n "$MARIADB_ROOT_PASSWORD" ] && echo "  Root 密码: $MARIADB_ROOT_PASSWORD"
    echo ""
    echo "连接命令:"
    if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
        echo "  mariadb -uroot -p'$MARIADB_ROOT_PASSWORD'"
    else
        echo "  mariadb -uroot"
    fi
    echo ""
    echo "服务管理:"
    echo "  systemctl start mariadb       # 启动 MariaDB"
    echo "  systemctl stop mariadb        # 停止 MariaDB"
    echo "  systemctl restart mariadb     # 重启 MariaDB"
    echo "  systemctl status mariadb      # 查看状态"
    echo ""
    echo "安全配置:"
    echo "  mysql_secure_installation     # 运行安全配置向导"
    echo ""
}

# 交互式配置
interactive_config() {
    echo ""
    echo "请输入 MariaDB 配置 (直接回车使用默认值):"
    echo ""

    # 端口
    read -p "MariaDB 端口 [$MARIADB_PORT]: " input_port
    MARIADB_PORT=${input_port:-$MARIADB_PORT}

    # Root 密码
    echo ""
    echo "安全提示: 建议设置强密码！"
    while true; do
        read -s -p "MariaDB Root 密码 (必填): " input_password
        echo ""
        if [ -z "$input_password" ]; then
            error "密码不能为空"
            continue
        fi
        read -s -p "确认密码: " confirm_password
        echo ""
        if [ "$input_password" = "$confirm_password" ]; then
            MARIADB_ROOT_PASSWORD="$input_password"
            break
        else
            error "两次密码不一致"
        fi
    done

    echo ""
    info "配置摘要:"
    info "  端口: $MARIADB_PORT"
    info "  Root 密码: ********"
    echo ""
    read -p "确认安装? [Y/n]: " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        info "取消安装"
        exit 0
    fi
}

# 主函数
main() {
    echo "============================================"
    echo "       MariaDB 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    interactive_config
    check_existing_mariadb

    case $OS in
        ubuntu|debian)
            install_mariadb_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_mariadb_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_mariadb
    start_mariadb
    secure_mariadb
    configure_firewall
    verify_installation
    show_info
}

# 运行主函数
main "$@"

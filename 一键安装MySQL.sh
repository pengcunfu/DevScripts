#!/bin/bash
# ============================================
# 一键安装 MySQL 脚本
# 支持: Ubuntu/Debian/CentOS/RHEL
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# MySQL 配置
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-""}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_CHARSET=${MYSQL_CHARSET:-"utf8mb4"}

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
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    else
        OS="unknown"
    fi
    info "检测到系统: $OS $OS_VERSION"
}

# 检查已安装的 MySQL
check_existing_mysql() {
    if command -v mysql &> /dev/null || command -v mysqld &> /dev/null; then
        EXISTING_VERSION=$(mysql --version 2>/dev/null || echo "unknown")
        warn "检测到已安装 MySQL: $EXISTING_VERSION"
        warn "重新安装将删除所有数据库！"
        read -p "是否继续? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            info "取消安装"
            exit 0
        fi
        remove_existing_mysql
    fi
}

# 卸载现有 MySQL
remove_existing_mysql() {
    info "卸载现有 MySQL..."

    # 停止服务
    systemctl stop mysql 2>/dev/null || true
    systemctl stop mysqld 2>/dev/null || true

    # 卸载
    case $OS in
        ubuntu|debian)
            apt-get remove -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* 2>/dev/null || true
            apt-get purge -y mysql-* 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y mysql mysql-server mysql-libs 2>/dev/null || true
            ;;
    esac

    # 清理配置和数据
    rm -rf /var/lib/mysql
    rm -rf /etc/mysql
    rm -f /etc/my.cnf
    rm -f /etc/my.cnf.d/*.cnf
    rm -rf /var/log/mysql

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 MySQL
install_mysql_debian() {
    info "开始安装 MySQL (Ubuntu/Debian)..."

    # 设置非交互式安装
    export DEBIAN_FRONTEND=noninteractive

    # 预配置 root 密码
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
        echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
    fi

    # 更新包索引
    apt-get update

    # 安装 MySQL
    apt-get install -y mysql-server mysql-client libmysqlclient-dev

    info "MySQL 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 MySQL
install_mysql_rhel() {
    info "开始安装 MySQL (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 安装 MySQL 仓库
    yum install -y https://dev.mysql.com/get/mysql80-community-release-el$(rpm -E %rhel)-$(rpm -E %rhel).noarch.rpm 2>/dev/null || {
        warn "MySQL 官方仓库安装失败，使用系统默认仓库"
        yum install -y mysql-server mysql
    }

    # 安装 MySQL
    yum install -y mysql-server mysql

    info "MySQL 安装完成"
}

# 配置 MySQL
configure_mysql() {
    info "配置 MySQL..."

    # 创建配置目录
    mkdir -p /etc/mysql/conf.d

    # 创建自定义配置
    cat > /etc/mysql/conf.d/custom.cnf <<EOF
[mysqld]
# 基本设置
port = $MYSQL_PORT
datadir = /var/lib/mysql
socket = /var/run/mysqld/mysqld.sock
pid-file = /var/run/mysqld/mysqld.pid

# 字符集
character-set-server = $MYSQL_CHARSET
collation-server = $MYSQL_CHARSET_unicode_ci

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
port = $MYSQL_PORT
socket = /var/run/mysqld/mysqld.sock
default-character-set = $MYSQL_CHARSET

[mysql]
default-character-set = $MYSQL_CHARSET
EOF

    # 创建日志目录
    mkdir -p /var/log/mysql
    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/log/mysql
    chown mysql:mysql /var/run/mysqld

    # 初始化数据目录（如果不存在）
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        info "初始化 MySQL 数据目录..."
        mysqld --initialize --user=mysql 2>/dev/null || {
            # 如果初始化失败，尝试旧版方式
            mysql_install_db --user=mysql 2>/dev/null || true
        }
    fi

    info "MySQL 配置完成"
}

# 启动 MySQL
start_mysql() {
    info "启动 MySQL 服务..."

    # 启用并启动 MySQL
    systemctl daemon-reload
    systemctl enable mysql 2>/dev/null || systemctl enable mysqld
    systemctl start mysql 2>/dev/null || systemctl start mysqld

    # 等待服务启动
    sleep 5

    # 检查服务状态
    if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mysqld 2>/dev/null; then
        info "MySQL 服务运行正常"
    else
        error "MySQL 服务启动失败"
        systemctl status mysql 2>/dev/null || systemctl status mysqld
        exit 1
    fi
}

# 设置 root 密码
set_root_password() {
    info "设置 root 密码..."

    # 获取临时密码（MySQL 8.0 首次安装时会生成）
    TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysql/error.log 2>/dev/null | tail -1 | awk '{print $NF}' || echo "")

    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        if [ -n "$TEMP_PASSWORD" ]; then
            # 使用临时密码修改
            mysql -uroot -p"$TEMP_PASSWORD" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || {
                # 如果失败，尝试直接修改
                mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || true
            }
        else
            # 无临时密码，直接设置
            mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || \
            mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');" 2>/dev/null || true
        fi

        # 允许远程连接
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';" 2>/dev/null || true
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" 2>/dev/null || true
        mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" 2>/dev/null || true

        info "Root 密码已设置"
    else
        warn "未设置 root 密码，请手动设置"
        info "临时密码: $TEMP_PASSWORD"
    fi
}

# 配置防火墙
configure_firewall() {
    info "配置防火墙..."

    if command -v firewall-cmd &> /dev/null; then
        # firewalld
        firewall-cmd --permanent --add-port=${MYSQL_PORT}/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        info "Firewalld 规则已添加"
    elif command -v ufw &> /dev/null; then
        # ufw
        ufw allow ${MYSQL_PORT}/tcp 2>/dev/null || true
        info "UFW 规则已添加"
    fi
}

# 验证安装
verify_installation() {
    info "验证 MySQL 安装..."

    # 显示版本
    mysql --version

    # 检查服务状态
    systemctl status mysql 2>/dev/null || systemctl status mysqld --no-pager -l

    # 测试连接
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        if mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT VERSION();" &>/dev/null; then
            info "MySQL 连接测试成功"
        else
            warn "MySQL 连接测试失败，请检查密码"
        fi
    fi
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "MySQL 安装完成！"
    echo "============================================"
    echo ""
    echo "连接信息:"
    echo "  端口: $MYSQL_PORT"
    echo "  字符集: $MYSQL_CHARSET"
    [ -n "$MYSQL_ROOT_PASSWORD" ] && echo "  Root 密码: $MYSQL_ROOT_PASSWORD"
    echo ""
    echo "连接命令:"
    if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        echo "  mysql -uroot -p'$MYSQL_ROOT_PASSWORD'"
    else
        echo "  mysql -uroot"
    fi
    echo ""
    echo "服务管理:"
    echo "  systemctl start mysql         # 启动 MySQL"
    echo "  systemctl stop mysql          # 停止 MySQL"
    echo "  systemctl restart mysql       # 重启 MySQL"
    echo "  systemctl status mysql        # 查看状态"
    echo ""
    echo "常用 SQL 命令:"
    echo "  SHOW DATABASES;               # 查看数据库"
    echo "  CREATE DATABASE db_name;      # 创建数据库"
    echo "  DROP DATABASE db_name;        # 删除数据库"
    echo "  SHOW PROCESSLIST;             # 查看连接"
    echo ""
    echo "配置文件:"
    echo "  /etc/mysql/conf.d/custom.cnf  # 自定义配置"
    echo "  /var/lib/mysql/               # 数据目录"
    echo "  /var/log/mysql/               # 日志目录"
    echo ""
}

# 交互式配置
interactive_config() {
    echo ""
    echo "请输入 MySQL 配置 (直接回车使用默认值):"
    echo ""

    # 端口
    read -p "MySQL 端口 [$MYSQL_PORT]: " input_port
    MYSQL_PORT=${input_port:-$MYSQL_PORT}

    # Root 密码
    echo ""
    echo "安全提示: 建议设置强密码！"
    while true; do
        read -s -p "MySQL Root 密码 (必填): " input_password
        echo ""
        if [ -z "$input_password" ]; then
            error "密码不能为空"
            continue
        fi
        read -s -p "确认密码: " confirm_password
        echo ""
        if [ "$input_password" = "$confirm_password" ]; then
            MYSQL_ROOT_PASSWORD="$input_password"
            break
        else
            error "两次密码不一致"
        fi
    done

    # 字符集
    echo ""
    read -p "字符集 [$MYSQL_CHARSET]: " input_charset
    MYSQL_CHARSET=${input_charset:-$MYSQL_CHARSET}

    echo ""
    info "配置摘要:"
    info "  端口: $MYSQL_PORT"
    info "  Root 密码: ********"
    info "  字符集: $MYSQL_CHARSET"
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
    echo "       MySQL 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    interactive_config
    check_existing_mysql

    case $OS in
        ubuntu|debian)
            install_mysql_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_mysql_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_mysql
    start_mysql
    set_root_password
    configure_firewall
    verify_installation
    show_info
}

# 运行主函数
main "$@"

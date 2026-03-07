#!/bin/bash
# ============================================
# 一键安装 PostgreSQL 脚本
# 支持: PostgreSQL 12/13/14/15/16
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

# PostgreSQL 配置
PG_VERSION=${PG_VERSION:-"16"}
PG_PORT=${PG_PORT:-5432}
PG_PASSWORD=${PG_PASSWORD:-""}
PG_DATA_DIR=${PG_DATA_DIR:-"/var/lib/postgresql/${PG_VERSION}/main"}

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

# 检查已安装的 PostgreSQL
check_existing_postgres() {
    if command -v psql &> /dev/null || systemctl status postgresql 2>/dev/null | grep -q "active (running)"; then
        EXISTING_VERSION=$(psql --version 2>/dev/null || echo "unknown")
        warn "检测到已安装 PostgreSQL: $EXISTING_VERSION"
        warn "重新安装将删除所有数据库！"
        read -p "是否继续? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            info "取消安装"
            exit 0
        fi
        remove_existing_postgres
    fi
}

# 卸载现有 PostgreSQL
remove_existing_postgres() {
    info "卸载现有 PostgreSQL..."

    # 停止服务
    systemctl stop postgresql 2>/dev/null || true

    # 卸载
    case $OS in
        ubuntu|debian)
            apt-get remove -y postgresql postgresql-* 2>/dev/null || true
            apt-get purge -y postgresql-* 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y postgresql postgresql-server 2>/dev/null || true
            ;;
    esac

    # 清理数据
    rm -rf /var/lib/postgresql
    rm -rf /etc/postgresql
    rm -rf /var/log/postgresql

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 PostgreSQL
install_postgres_debian() {
    info "开始安装 PostgreSQL $PG_VERSION (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    # 安装依赖
    apt-get install -y wget gnupg

    # 添加 PostgreSQL 官方仓库
    if [ "$OS" = "ubuntu" ]; then
        sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    else
        sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    fi

    apt-get update

    # 安装 PostgreSQL
    apt-get install -y \
        postgresql-$PG_VERSION \
        postgresql-client-$PG_VERSION \
        postgresql-contrib-$PG_VERSION \
        postgresql-server-dev-$PG_VERSION

    info "PostgreSQL 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 PostgreSQL
install_postgres_rhel() {
    info "开始安装 PostgreSQL $PG_VERSION (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 安装 PostgreSQL 仓库
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/PGDG-rhel$(rpm -E %rhel)-$(echo $PG_VERSION | cut -d. -f1).noarch.rpm

    # 安装 PostgreSQL
    yum install -y \
        postgresql$PG_VERSION \
        postgresql$PG_VERSION-server \
        postgresql$PG_VERSION-contrib \
        postgresql$PG_VERSION-devel

    # 初始化数据库（如果需要）
    if [ ! -d "/var/lib/pgsql/$PG_VERSION/data" ]; then
        /usr/pgsql-$PG_VERSION/bin/postgresql-$PG_VERSION-setup initdb
    fi

    info "PostgreSQL 安装完成"
}

# 配置 PostgreSQL
configure_postgres() {
    info "配置 PostgreSQL..."

    # 查找配置目录
    if [ -d "/etc/postgresql/$PG_VERSION/main" ]; then
        PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main"
    elif [ -d "/var/lib/pgsql/$PG_VERSION/data" ]; then
        PG_CONF_DIR="/var/lib/pgsql/$PG_VERSION/data"
    else
        error "找不到 PostgreSQL 配置目录"
        return 1
    fi

    info "配置目录: $PG_CONF_DIR"

    # 备份配置
    cp "$PG_CONF_DIR/postgresql.conf" "${PG_CONF_DIR}/postgresql.conf.bak"

    # 修改 postgresql.conf
    sed -i "s/^#listen_addresses = .*/listen_addresses = '*'/" "$PG_CONF_DIR/postgresql.conf"
    sed -i "s/^port = .*/port = $PG_PORT/" "$PG_CONF_DIR/postgresql.conf"
    sed -i 's/^max_connections = .*/max_connections = 200/' "$PG_CONF_DIR/postgresql.conf"
    sed -i 's/^shared_buffers = .*/shared_buffers = 256MB/' "$PG_CONF_DIR/postgresql.conf"
    sed -i 's/^#shared_buffers = .*/shared_buffers = 256MB/' "$PG_CONF_DIR/postgresql.conf"

    # 配置 pg_hba.conf 允许远程连接
    PG_HBA="$PG_CONF_DIR/pg_hba.conf"
    cp "$PG_HBA" "${PG_HBA}.bak"

    # 添加 IPv4 认证规则
    if ! grep -q "host all all 0.0.0.0/0 md5" "$PG_HBA"; then
        echo "host    all             all             0.0.0.0/0               md5" >> "$PG_HBA"
    fi

    # 添加 IPv6 认证规则
    if ! grep -q "host all all ::/0 md5" "$PG_HBA"; then
        echo "host    all             all             ::/0                    md5" >> "$PG_HBA"
    fi

    info "PostgreSQL 配置完成"
}

# 设置 postgres 用户密码
set_postgres_password() {
    if [ -n "$PG_PASSWORD" ]; then
        info "设置 postgres 用户密码..."

        # 启动服务
        systemctl start postgresql

        # 设置密码
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PG_PASSWORD';"

        info "postgres 用户密码已设置"
    fi
}

# 启动 PostgreSQL
start_postgres() {
    info "启动 PostgreSQL 服务..."

    # 启用并启动
    systemctl enable postgresql
    systemctl restart postgresql

    # 等待启动
    sleep 3

    # 检查状态
    if systemctl is-active --quiet postgresql; then
        info "PostgreSQL 服务运行正常"
    else
        error "PostgreSQL 服务启动失败"
        systemctl status postgresql
        exit 1
    fi
}

# 配置防火墙
configure_firewall() {
    info "配置防火墙..."

    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${PG_PORT}/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        info "Firewalld 规则已添加"
    elif command -v ufw &> /dev/null; then
        ufw allow ${PG_PORT}/tcp 2>/dev/null || true
        info "UFW 规则已添加"
    fi
}

# 验证安装
verify_installation() {
    info "验证 PostgreSQL 安装..."

    psql --version

    # 检查服务状态
    systemctl status postgresql --no-pager -l

    # 测试连接
    if [ -n "$PG_PASSWORD" ]; then
        if PGPASSWORD="$PG_PASSWORD" psql -h localhost -U postgres -c "SELECT VERSION();" &>/dev/null; then
            info "PostgreSQL 连接测试成功"
        else
            warn "PostgreSQL 连接测试失败，请检查密码"
        fi
    fi
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "PostgreSQL 安装完成！"
    echo "============================================"
    echo ""
    echo "连接信息:"
    echo "  端口: $PG_PORT"
    echo "  数据目录: $PG_DATA_DIR"
    [ -n "$PG_PASSWORD" ] && echo "  postgres 密码: $PG_PASSWORD"
    echo ""
    echo "连接命令:"
    echo "  sudo -u postgres psql                           # 本地连接"
    [ -n "$PG_PASSWORD" ] && echo "  PGPASSWORD='$PG_PASSWORD' psql -h localhost -U postgres  # 远程连接"
    echo ""
    echo "服务管理:"
    echo "  systemctl start postgresql      # 启动 PostgreSQL"
    echo "  systemctl stop postgresql       # 停止 PostgreSQL"
    echo "  systemctl restart postgresql    # 重启 PostgreSQL"
    echo "  systemctl status postgresql     # 查看状态"
    echo ""
    echo "常用命令:"
    echo "  psql -U postgres                    # 连接数据库"
    echo "  createdb dbname                     # 创建数据库"
    echo "  dropdb dbname                       # 删除数据库"
    echo "  createuser username                 # 创建用户"
    echo "  pg_dump dbname > backup.sql         # 备份数据库"
    echo "  psql dbname < backup.sql            # 恢复数据库"
    echo ""
}

# 交互式配置
interactive_config() {
    echo ""
    echo "请输入 PostgreSQL 配置 (直接回车使用默认值):"
    echo ""

    # 版本选择
    echo "请选择 PostgreSQL 版本:"
    echo "  1) PostgreSQL 16 (最新稳定版，推荐)"
    echo "  2) PostgreSQL 15"
    echo "  3) PostgreSQL 14"
    echo "  4) PostgreSQL 13"
    echo "  5) PostgreSQL 12"
    echo ""
    read -p "请输入选项 [1-5] (默认: 1): " version_choice
    version_choice=${version_choice:-1}

    case $version_choice in
        1) PG_VERSION="16" ;;
        2) PG_VERSION="15" ;;
        3) PG_VERSION="14" ;;
        4) PG_VERSION="13" ;;
        5) PG_VERSION="12" ;;
    esac

    # 端口
    echo ""
    read -p "PostgreSQL 端口 [$PG_PORT]: " input_port
    PG_PORT=${input_port:-$PG_PORT}

    # 密码
    echo ""
    echo "安全提示: 建议设置强密码！"
    while true; do
        read -s -p "postgres 用户密码 (必填): " input_password
        echo ""
        if [ -z "$input_password" ]; then
            error "密码不能为空"
            continue
        fi
        read -s -p "确认密码: " confirm_password
        echo ""
        if [ "$input_password" = "$confirm_password" ]; then
            PG_PASSWORD="$input_password"
            break
        else
            error "两次密码不一致"
        fi
    done

    echo ""
    info "配置摘要:"
    info "  版本: PostgreSQL $PG_VERSION"
    info "  端口: $PG_PORT"
    info "  postgres 密码: ********"
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
    echo "       PostgreSQL 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    interactive_config
    check_existing_postgres

    case $OS in
        ubuntu|debian)
            install_postgres_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_postgres_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_postgres
    start_postgres
    set_postgres_password
    configure_firewall
    verify_installation
    show_info
}

# 运行主函数
main "$@"

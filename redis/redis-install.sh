#!/bin/bash
# ============================================
# 一键安装 Redis 脚本
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

# Redis 配置
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-""}
REDIS_MAXMEMORY=${REDIS_MAXMEMORY:-"256mb"}

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

# 检查已安装的 Redis
check_existing_redis() {
    if command -v redis-server &> /dev/null; then
        EXISTING_VERSION=$(redis-server --version | grep -oP 'v=\K[\d.]+' || echo "unknown")
        warn "检测到已安装 Redis: v=$EXISTING_VERSION"
        read -p "是否卸载并重新安装? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_existing_redis
        else
            info "保留现有安装，退出脚本"
            exit 0
        fi
    fi
}

# 卸载现有 Redis
remove_existing_redis() {
    info "卸载现有 Redis..."

    # 停止服务
    systemctl stop redis 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true

    # 卸载
    case $OS in
        ubuntu|debian)
            apt-get remove -y redis-server redis-tools 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y redis 2>/dev/null || true
            ;;
    esac

    # 清理配置和数据
    rm -rf /var/lib/redis
    rm -rf /var/log/redis
    rm -f /etc/redis/redis.conf
    rm -f /etc/redis.conf

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 Redis
install_redis_debian() {
    info "开始安装 Redis (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    # 安装 Redis
    apt-get install -y redis-server

    info "Redis 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 Redis
install_redis_rhel() {
    info "开始安装 Redis (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 添加 EPEL 仓库
    yum install -y epel-release

    # 安装 Redis
    yum install -y redis

    info "Redis 安装完成"
}

# 配置 Redis
configure_redis() {
    info "配置 Redis..."

    # 查找配置文件
    if [ -f "/etc/redis/redis.conf" ]; then
        REDIS_CONF="/etc/redis/redis.conf"
    elif [ -f "/etc/redis.conf" ]; then
        REDIS_CONF="/etc/redis.conf"
    else
        error "找不到 Redis 配置文件"
        exit 1
    fi

    info "配置文件: $REDIS_CONF"

    # 备份配置文件
    cp "$REDIS_CONF" "${REDIS_CONF}.bak"

    # 设置监听地址（允许远程连接）
    sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' "$REDIS_CONF"
    sed -i 's/^# bind 127.0.0.1/bind 0.0.0.0/' "$REDIS_CONF"

    # 设置端口
    sed -i "s/^port 6379/port $REDIS_PORT/" "$REDIS_CONF"

    # 设置密码
    if [ -n "$REDIS_PASSWORD" ]; then
        sed -i "s/^# requirepass .*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF"
        sed -i "s/^requirepass .*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF"
        info "已设置 Redis 密码"
    fi

    # 设置持久化（AOF + RDB）
    sed -i 's/^appendonly no/appendonly yes/' "$REDIS_CONF"
    sed -i 's/^# appendonly yes/appendonly yes/' "$REDIS_CONF"

    # 设置最大内存
    sed -i "s/^# maxmemory <bytes>/maxmemory $REDIS_MAXMEMORY/" "$REDIS_CONF"
    sed -i "s/^maxmemory .*/maxmemory $REDIS_MAXMEMORY/" "$REDIS_CONF"

    # 设置内存淘汰策略
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' "$REDIS_CONF"
    sed -i 's/^maxmemory-policy .*/maxmemory-policy allkeys-lru/' "$REDIS_CONF"

    # 设置日志级别
    sed -i 's/^loglevel .*/loglevel notice/' "$REDIS_CONF"

    # 设置数据目录权限
    mkdir -p /var/lib/redis
    chown redis:redis /var/lib/redis 2>/dev/null || chown redis:redis /var/lib/redis
    chmod 770 /var/lib/redis

    info "Redis 配置完成"
}

# 配置防火墙
configure_firewall() {
    info "配置防火墙..."

    if command -v firewall-cmd &> /dev/null; then
        # firewalld
        firewall-cmd --permanent --add-port=${REDIS_PORT}/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        info "Firewalld 规则已添加"
    elif command -v ufw &> /dev/null; then
        # ufw
        ufw allow ${REDIS_PORT}/tcp 2>/dev/null || true
        info "UFW 规则已添加"
    fi
}

# 启动并启用 Redis
start_redis() {
    info "启动 Redis 服务..."

    # 启用并启动 Redis
    systemctl daemon-reload
    systemctl enable redis 2>/dev/null || systemctl enable redis-server
    systemctl restart redis 2>/dev/null || systemctl restart redis-server

    # 等待服务启动
    sleep 2

    # 检查服务状态
    if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
        info "Redis 服务运行正常"
    else
        error "Redis 服务启动失败"
        systemctl status redis 2>/dev/null || systemctl status redis-server
        exit 1
    fi
}

# 验证安装
verify_installation() {
    info "验证 Redis 安装..."

    # 显示版本
    redis-server --version

    # 检查服务状态
    systemctl status redis 2>/dev/null || systemctl status redis-server --no-pager

    # 测试连接
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h 127.0.0.1 -p $REDIS_PORT -a "$REDIS_PASSWORD" ping 2>/dev/null && echo "PONG" || true
    else
        redis-cli -h 127.0.0.1 -p $REDIS_PORT ping
    fi

    info "Redis 安装验证成功！"
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "Redis 安装完成！"
    echo "============================================"
    echo ""
    echo "连接信息:"
    echo "  端口: $REDIS_PORT"
    [ -n "$REDIS_PASSWORD" ] && echo "  密码: $REDIS_PASSWORD"
    echo ""
    echo "常用命令:"
    echo "  redis-cli                      # 连接本地 Redis"
    echo "  redis-cli -h <IP> -p $REDIS_PORT  # 连接远程 Redis"
    [ -n "$REDIS_PASSWORD" ] && echo "  redis-cli -a '$REDIS_PASSWORD'      # 使用密码连接"
    echo ""
    echo "服务管理:"
    echo "  systemctl start redis          # 启动 Redis"
    echo "  systemctl stop redis           # 停止 Redis"
    echo "  systemctl restart redis        # 重启 Redis"
    echo "  systemctl status redis         # 查看状态"
    echo ""
    echo "Redis 常用操作:"
    echo "  redis-cli ping                 # 测试连接"
    echo "  redis-cli INFO                 # 查看信息"
    echo "  redis-cli DBSIZE               # 查看键数量"
    echo "  redis-cli FLUSHALL             # 清空所有数据"
    echo ""
}

# 交互式配置
interactive_config() {
    echo ""
    echo "请输入 Redis 配置 (直接回车使用默认值):"
    echo ""

    # 端口
    read -p "Redis 端口 [$REDIS_PORT]: " input_port
    REDIS_PORT=${input_port:-$REDIS_PORT}

    # 密码
    read -p "Redis 密码 (留空则不设置密码): " input_password
    REDIS_PASSWORD=$input_password

    # 最大内存
    read -p "最大内存 [$REDIS_MAXMEMORY]: " input_memory
    REDIS_MAXMEMORY=${input_memory:-$REDIS_MAXMEMORY}

    echo ""
    info "配置摘要:"
    info "  端口: $REDIS_PORT"
    [ -n "$REDIS_PASSWORD" ] && info "  密码: 已设置" || info "  密码: 未设置"
    info "  最大内存: $REDIS_MAXMEMORY"
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
    echo "       Redis 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    interactive_config
    check_existing_redis

    case $OS in
        ubuntu|debian)
            install_redis_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_redis_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_redis
    configure_firewall
    start_redis
    verify_installation
    show_info
}

# 运行主函数
main "$@"

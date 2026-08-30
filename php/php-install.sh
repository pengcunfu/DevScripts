#!/bin/bash
# ============================================
# 一键安装 PHP 脚本
# 支持: PHP 7.4 / 8.0 / 8.1 / 8.2 / 8.3
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

# 默认 PHP 版本
PHP_VERSION=${PHP_VERSION:-"8.3"}

# 常用扩展
COMMON_EXTENSIONS="mysql curl gd mbstring xml zip bcmath opcache"

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

# 检查已安装的 PHP
check_existing_php() {
    if command -v php &> /dev/null; then
        EXISTING_VERSION=$(php -v | head -n 1 || echo "unknown")
        warn "检测到已安装 PHP: $EXISTING_VERSION"
        read -p "是否卸载并重新安装? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_existing_php
        else
            info "保留现有安装，退出脚本"
            exit 0
        fi
    fi
}

# 卸载现有 PHP
remove_existing_php() {
    info "卸载现有 PHP..."

    case $OS in
        ubuntu|debian)
            apt-get remove -y php* libapache2-mod-php* 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y php* 2>/dev/null || true
            ;;
    esac

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 PHP
install_php_debian() {
    info "开始安装 PHP $PHP_VERSION (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    # 安装基础软件包
    apt-get install -y \
        software-properties-common \
        ca-certificates \
        lsb-release \
        apt-transport-https

    # 添加 Ondrej PPA (提供所有 PHP 版本)
    if [ "$OS" = "ubuntu" ]; then
        add-apt-repository -y ppa:ondrej/php
    else
        # Debian
        curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/keyrings/php.gpg
        echo "deb [signed-by=/etc/apt/keyrings/php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
    fi

    apt-get update

    # 安装 PHP 及常用扩展
    apt-get install -y \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-mongodb

    # 安装 Composer
    install_composer

    info "PHP 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 PHP
install_php_rhel() {
    info "开始安装 PHP $PHP_VERSION (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 安装 EPEL 和 Remi 仓库
    yum install -y epel-release
    yum install -y https://rpms.remirepo.net/enterprise/remi-release$(rpm -E %rhel).rpm

    # 启用指定版本的 PHP 仓库
    yum module enable -y php:remi-${PHP_VERSION}

    # 安装 PHP 及常用扩展
    yum install -y \
        php \
        php-fpm \
        php-mysqlnd \
        php-pdo \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        php-bcmath \
        php-opcache \
        php-intl \
        php-pecl-redis \
        php-pecl-mongodb

    # 安装 Composer
    install_composer

    info "PHP 安装完成"
}

# 安装 Composer
install_composer() {
    info "安装 Composer..."

    # 下载 Composer
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    # 配置国内镜像
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

    info "Composer 安装完成"
}

# 配置 PHP
configure_php() {
    info "配置 PHP..."

    # 创建自定义配置
    PHP_INI_DIR="/etc/php/${PHP_VERSION}"
    if [ ! -d "$PHP_INI_DIR" ]; then
        PHP_INI_DIR="/etc"
    fi

    # 配置 php.ini
    if [ -f "${PHP_INI_DIR}/fpm/php.ini" ]; then
        PHP_INI="${PHP_INI_DIR}/fpm/php.ini"
    elif [ -f "${PHP_INI_DIR}/apache2/php.ini" ]; then
        PHP_INI="${PHP_INI_DIR}/apache2/php.ini"
    elif [ -f "${PHP_INI_DIR}/php.ini" ]; then
        PHP_INI="${PHP_INI_DIR}/php.ini"
    else
        warn "找不到 php.ini 文件"
        return
    fi

    # 备份
    cp "$PHP_INI" "${PHP_INI}.bak"

    # 常用优化配置
    sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$PHP_INI"
    sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 100M/' "$PHP_INI"
    sed -i 's/^post_max_size = .*/post_max_size = 100M/' "$PHP_INI"
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"
    sed -i 's/^;date.timezone =.*/date.timezone = Asia\/Shanghai/' "$PHP_INI"
    sed -i 's/^opcache.enable=.*/opcache.enable=1/' "$PHP_INI"
    sed -i 's/^;opcache.enable_cli=.*/opcache.enable_cli=1/' "$PHP_INI"

    info "PHP 配置完成"
}

# 启动 PHP-FPM
start_php_fpm() {
    info "启动 PHP-FPM..."

    # 启用并启动服务
    systemctl enable php${PHP_VERSION}-fpm 2>/dev/null || systemctl enable php-fpm
    systemctl restart php${PHP_VERSION}-fpm 2>/dev/null || systemctl restart php-fpm

    # 检查状态
    if systemctl is-active --quiet php${PHP_VERSION}-fpm 2>/dev/null || systemctl is-active --quiet php-fpm 2>/dev/null; then
        info "PHP-FPM 运行正常"
    else
        warn "PHP-FPM 启动失败"
    fi
}

# 验证安装
verify_installation() {
    info "验证 PHP 安装..."

    if ! command -v php &> /dev/null; then
        error "PHP 安装失败"
        exit 1
    fi

    # 显示版本
    php -v

    # 显示已安装模块
    echo ""
    info "已安装的 PHP 模块:"
    php -m
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "PHP 安装完成！"
    echo "============================================"
    echo ""
    echo "版本信息:"
    php -v | head -n 1
    echo ""
    echo "常用命令:"
    echo "  php -v                     # 查看 PHP 版本"
    echo "  php -m                     # 查看已安装模块"
    echo "  php --ini                  # 查看 php.ini 位置"
    echo "  php -S localhost:8000      # 启动内置服务器"
    echo "  composer -v                # 查看 Composer 版本"
    echo ""
    echo "服务管理:"
    echo "  systemctl start php${PHP_VERSION}-fpm    # 启动 PHP-FPM"
    echo "  systemctl stop php${PHP_VERSION}-fpm     # 停止 PHP-FPM"
    echo "  systemctl restart php${PHP_VERSION}-fpm  # 重启 PHP-FPM"
    echo ""
    echo "配置文件:"
    echo "  PHP 配置: $PHP_INI"
    echo "  FPM 配置: /etc/php/${PHP_VERSION}/fpm/pool.d/"
    echo ""
}

# 交互式选择版本
select_version() {
    echo ""
    echo "请选择 PHP 版本:"
    echo "  1) PHP 8.3 (最新稳定版，推荐)"
    echo "  2) PHP 8.2"
    echo "  3) PHP 8.1"
    echo "  4) PHP 8.0"
    echo "  5) PHP 7.4"
    echo ""
    read -p "请输入选项 [1-5] (默认: 1): " choice
    choice=${choice:-1}

    case $choice in
        1) PHP_VERSION="8.3" ;;
        2) PHP_VERSION="8.2" ;;
        3) PHP_VERSION="8.1" ;;
        4) PHP_VERSION="8.0" ;;
        5) PHP_VERSION="7.4" ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    echo "============================================"
    echo "       PHP 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    select_version
    check_existing_php

    case $OS in
        ubuntu|debian)
            install_php_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_php_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_php
    start_php_fpm
    verify_installation
    show_info
}

# 运行主函数
main "$@"

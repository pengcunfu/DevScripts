#!/bin/bash
# ============================================
# 一键安装 Node.js 脚本
# 支持: LTS 版本 / 指定版本
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

# 默认 Node.js 版本
NODE_VERSION=${NODE_VERSION:-""}

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

# 检查已安装的 Node.js
check_existing_nodejs() {
    if command -v node &> /dev/null; then
        EXISTING_VERSION=$(node --version 2>/dev/null || echo "unknown")
        warn "检测到已安装 Node.js: $EXISTING_VERSION"
        read -p "是否卸载并重新安装? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_existing_nodejs
        else
            info "保留现有安装，退出脚本"
            exit 0
        fi
    fi
}

# 卸载现有 Node.js
remove_existing_nodejs() {
    info "卸载现有 Node.js..."

    case $OS in
        ubuntu|debian)
            apt-get remove -y nodejs npm 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y nodejs npm 2>/dev/null || true
            ;;
    esac

    # 清理残留
    rm -rf /usr/local/bin/node
    rm -rf /usr/local/bin/npm
    rm -rf /usr/local/lib/node_modules
    rm -rf /usr/local/include/node

    info "旧版本已卸载"
}

# 使用 NodeSource 仓库安装
install_nodesource() {
    local version=$1

    info "使用 NodeSource 仓库安装 Node.js $version..."

    # 添加 NodeSource 仓库
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_${version}.x | bash -
        apt-get install -y nodejs
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "rocky" ] || [ "$OS" = "almalinux" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_${version}.x | bash -
        yum install -y nodejs
    fi

    info "Node.js 安装完成"
}

# 使用 NVM 安装 (多版本管理)
install_nvm() {
    info "使用 NVM 安装 Node.js..."

    # 获取最新 LTS 版本
    if [ -z "$NODE_VERSION" ]; then
        NODE_VERSION="lts/*"
    fi

    # 安装 NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    # 加载 NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 安装 Node.js
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"

    # 创建全局链接
    if [ -d "$HOME/.nvm" ]; then
        # 为所有用户创建链接
        NVM_NODE=$(find "$HOME/.nvm/versions/node" -name "node" -type f 2>/dev/null | head -1)
        if [ -n "$NVM_NODE" ]; then
            NVM_BIN_DIR=$(dirname "$NVM_NODE")
            ln -sf "$NVM_NODE" /usr/local/bin/node
            ln -sf "$NVM_BIN_DIR/npm" /usr/local/bin/npm
            ln -sf "$NVM_BIN_DIR/npx" /usr/local/bin/npx
        fi
    fi

    info "Node.js 安装完成"
}

# 使用 Snap 安装
install_snap() {
    info "使用 Snap 安装 Node.js..."

    if ! command -v snap &> /dev/null; then
        error "Snap 未安装"
        return 1
    fi

    snap install node --classic --channel="${NODE_VERSION}/stable"

    info "Node.js 安装完成"
}

# 配置 npm 国内镜像
configure_npm_mirror() {
    info "配置 npm 国内镜像..."

    # 设置淘宝镜像
    npm config set registry https://registry.npmmirror.com

    # 安装常用工具
    npm install -g pm2 yarn pnpm

    info "npm 镜像配置完成"
    info "registry: https://registry.npmmirror.com"
}

# 验证安装
verify_installation() {
    info "验证 Node.js 安装..."

    if ! command -v node &> /dev/null; then
        error "Node.js 安装失败"
        exit 1
    fi

    # 显示版本
    node --version
    npm --version

    # 显示配置
    echo ""
    info "npm 配置:"
    npm config list
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "Node.js 安装完成！"
    echo "============================================"
    echo ""
    echo "版本信息:"
    node --version
    echo ""
    echo "常用命令:"
    echo "  node -v                    # 查看 Node.js 版本"
    echo "  npm -v                     # 查看 npm 版本"
    echo "  npm install <package>      # 安装包"
    echo "  npm install -g <package>   # 全局安装"
    echo "  npm run <script>           # 运行脚本"
    echo "  npx <command>              # 运行 npx 命令"
    echo ""
    echo "包管理器:"
    echo "  npm install                # 安装依赖"
    echo "  yarn install               # 使用 Yarn"
    echo "  pnpm install               # 使用 pnpm"
    echo ""
    echo "进程管理 (PM2):"
    echo "  pm2 start app.js           # 启动应用"
    echo "  pm2 list                   # 查看进程"
    echo "  pm2 logs                   # 查看日志"
    echo "  pm2 stop <id>              # 停止进程"
    echo ""
}

# 交互式选择版本
select_version() {
    echo ""
    echo "请选择安装方式:"
    echo "  1) NodeSource (推荐，稳定)"
    echo "  2) NVM (多版本管理)"
    echo "  3) Snap (Ubuntu 系)"
    echo ""
    read -p "请输入选项 [1-3] (默认: 1): " method_choice
    method_choice=${method_choice:-1}

    case $method_choice in
        1)
            INSTALL_METHOD="nodesource"
            ;;
        2)
            INSTALL_METHOD="nvm"
            ;;
        3)
            INSTALL_METHOD="snap"
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac

    echo ""
    echo "请选择 Node.js 版本:"
    echo "  1) Node.js 20 (LTS - 推荐)"
    echo "  2) Node.js 18 (LTS)"
    echo "  3) Node.js 16 (LTS)"
    echo "  4) 指定版本"
    echo ""
    read -p "请输入选项 [1-4] (默认: 1): " version_choice
    version_choice=${version_choice:-1}

    case $version_choice in
        1) NODE_VERSION="20" ;;
        2) NODE_VERSION="18" ;;
        3) NODE_VERSION="16" ;;
        4)
            read -p "请输入版本号 (如: 20): " NODE_VERSION
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    echo "============================================"
    echo "       Node.js 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    select_version
    check_existing_nodejs

    case $INSTALL_METHOD in
        nodesource)
            install_nodesource "$NODE_VERSION"
            ;;
        nvm)
            install_nvm
            ;;
        snap)
            install_snap
            ;;
    esac

    configure_npm_mirror
    verify_installation
    show_info
}

# 运行主函数
main "$@"

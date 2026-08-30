#!/bin/bash
# ============================================
# 一键安装 Docker Compose 脚本
# 支持: 独立安装 Docker Compose (standalone)
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 root 权限运行"
        info "请使用: sudo $0"
        exit 1
    fi
}

# 获取最新版本号
get_latest_version() {
    info "获取 Docker Compose 最新版本..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$LATEST_VERSION" ]; then
        error "无法获取最新版本信息"
        exit 1
    fi
    info "最新版本: $LATEST_VERSION"
}

# 检测系统架构
detect_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            COMPOSE_ARCH="x86_64"
            ;;
        aarch64|arm64)
            COMPOSE_ARCH="aarch64"
            ;;
        armv7l|armhf)
            COMPOSE_ARCH="armv7"
            ;;
        *)
            error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
    info "系统架构: $ARCH"
}

# 检查 Docker 是否已安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        warn "Docker 未安装，请先安装 Docker"
        info "运行: ./一键安装Docker.sh"
        exit 1
    fi
    info "Docker 已安装: $(docker --version)"
}

# 卸载旧版本 Docker Compose
uninstall_old_compose() {
    info "检查并卸载旧版本 Docker Compose..."

    # 检查 standalone 版本
    if [ -f /usr/local/bin/docker-compose ]; then
        warn "检测到旧版本 docker-compose，正在卸载..."
        rm -f /usr/local/bin/docker-compose
        info "旧版本已卸载"
    fi

    # 检查是否通过包管理器安装
    if command -v docker-compose &> /dev/null; then
        warn "检测到通过包管理器安装的 docker-compose"
        case $OS in
            ubuntu|debian)
                apt-get remove -y docker-compose 2>/dev/null || true
                ;;
            centos|rhel|rocky|almalinux)
                yum remove -y docker-compose 2>/dev/null || true
                ;;
        esac
    fi
}

# 安装 Docker Compose standalone
install_compose_standalone() {
    info "开始安装 Docker Compose standalone..."

    get_latest_version
    detect_architecture

    # 下载 URL
    DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-linux-${COMPOSE_ARCH}"

    info "下载 Docker Compose..."
    curl -SL "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose

    # 设置执行权限
    chmod +x /usr/local/bin/docker-compose

    # 创建符号链接（可选，方便使用）
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    info "Docker Compose standalone 安装完成"
}

# 安装 Docker Compose 通过 pip（备用方法）
install_compose_pip() {
    info "通过 pip 安装 Docker Compose..."

    # 检查 Python 和 pip
    if ! command -v python3 &> /dev/null; then
        error "未找到 Python3"
        exit 1
    fi

    if ! command -v pip3 &> /dev/null; then
        info "安装 pip3..."
        apt-get install -y python3-pip || yum install -y python3-pip
    fi

    # 安装/升级 docker-compose
    pip3 install --upgrade docker-compose

    info "Docker Compose 通过 pip 安装完成"
}

# 启用 Docker Compose 插件（如果使用 Docker Desktop 或新版本 Docker）
enable_compose_plugin() {
    if docker compose version &> /dev/null; then
        info "Docker Compose 插件已可用"
        docker compose version
    fi
}

# 验证安装
verify_installation() {
    info "验证 Docker Compose 安装..."

    # 检查 standalone 版本
    if [ -f /usr/local/bin/docker-compose ]; then
        docker-compose --version
        if [ $? -eq 0 ]; then
            info "Docker Compose standalone 安装成功！"
        fi
    fi

    # 检查插件版本
    if docker compose version &> /dev/null; then
        info "Docker Compose 插件也可用: $(docker compose version)"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo "============================================"
    info "Docker Compose 安装完成！"
    echo "============================================"
    echo ""
    echo "两种使用方式:"
    echo ""
    echo "1. Standalone 版本 (独立命令):"
    echo "   docker-compose --version"
    echo "   docker-compose up -d"
    echo ""
    echo "2. Docker 插件版本 (推荐):"
    echo "   docker compose version"
    echo "   docker compose up -d"
    echo ""
    echo "配置文件示例 (docker-compose.yml):"
    cat <<'EXAMPLE'
version: '3.8'
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
EXAMPLE
    echo ""
    echo "常用命令:"
    echo "  docker-compose up -d       # 后台启动服务"
    echo "  docker-compose down        # 停止并删除容器"
    echo "  docker-compose ps          # 查看运行状态"
    echo "  docker-compose logs        # 查看日志"
    echo "  docker-compose exec <service> <cmd>  # 进入容器"
    echo ""
}

# 交互式选择安装方式
select_installation_method() {
    echo ""
    echo "请选择 Docker Compose 安装方式:"
    echo "  1) Standalone (独立版本，使用 docker-compose 命令)"
    echo "  2) Docker 插件 (已包含在 Docker 中，使用 docker compose 命令)"
    echo "  3) 两者都安装"
    echo "  4) 通过 pip 安装 (备用方法)"
    echo ""
    read -p "请输入选项 [1-4] (默认: 3): " choice
    choice=${choice:-3}

    case $choice in
        1)
            install_compose_standalone
            ;;
        2)
            info "使用 Docker Compose 插件"
            enable_compose_plugin
            ;;
        3)
            install_compose_standalone
            enable_compose_plugin
            ;;
        4)
            install_compose_pip
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac
}

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
}

# 主函数
main() {
    echo "============================================"
    echo "    Docker Compose 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    check_docker
    uninstall_old_compose
    select_installation_method
    verify_installation
    show_usage
}

# 运行主函数
main "$@"

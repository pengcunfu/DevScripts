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
        info "运行: ./docker-install.sh"
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

    # 优先复用 docker-ce 自带的 compose 插件二进制做软链：
    # 无需联网，版本与插件一致，避开国内直连 github.com / api.github.com 被重置的问题
    for plugin_path in \
        /usr/libexec/docker/cli-plugins/docker-compose \
        /usr/lib/docker/cli-plugins/docker-compose \
        /usr/local/lib/docker/cli-plugins/docker-compose
    do
        if [ -x "$plugin_path" ]; then
            info "复用已安装的 Compose 插件: $plugin_path"
            ln -sf "$plugin_path" /usr/local/bin/docker-compose
            ln -sf "$plugin_path" /usr/bin/docker-compose
            info "Docker Compose standalone 安装完成（软链自插件，无需联网下载）"
            return 0
        fi
    done

    # 未找到插件时，回退到从 GitHub 下载独立二进制
    warn "未找到 Compose 插件，回退为从 GitHub 下载独立版本..."
    get_latest_version
    detect_architecture

    # 下载 URL
    DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-linux-${COMPOSE_ARCH}"

    info "下载 Docker Compose: $DOWNLOAD_URL"
    if ! curl -fSL --connect-timeout 15 --retry 2 "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose; then
        rm -f /usr/local/bin/docker-compose
        error "下载失败: $DOWNLOAD_URL"
        error "国内网络可尝试 GitHub 加速前缀，例如："
        error "  curl -fSL https://ghfast.top/$DOWNLOAD_URL -o /usr/local/bin/docker-compose"
        exit 1
    fi

    # 设置执行权限
    chmod +x /usr/local/bin/docker-compose

    # 创建符号链接（可选，方便使用）
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    info "Docker Compose standalone 安装完成"
}

# 验证安装
verify_installation() {
    info "验证 Docker Compose 安装..."

    # 检查 standalone 版本
    if [ -f /usr/local/bin/docker-compose ]; then
        # set -e 下 docker-compose 失败会直接退出，需放进 if 条件里才能走到提示
        if docker-compose --version; then
            info "Docker Compose standalone 安装成功！"
        else
            warn "docker-compose 命令存在但执行失败，请检查二进制是否完整"
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
    install_compose_standalone
    verify_installation
    show_usage
}

# 运行主函数
main "$@"

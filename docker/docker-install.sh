#!/bin/bash
# ============================================
# 一键安装 Docker 脚本
# 支持: Ubuntu/Debian/CentOS/Rocky/AlmaLinux
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

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        error "无法检测系统类型"
        exit 1
    fi
    info "检测到系统: $OS $OS_VERSION"
}

# 卸载旧版本Docker
uninstall_old_docker() {
    info "检查并卸载旧版本 Docker..."
    if command -v docker &> /dev/null; then
        warn "检测到已安装 Docker，正在卸载..."
        case $OS in
            ubuntu|debian)
                apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
                ;;
            centos|rhel|rocky|almalinux)
                yum remove -y docker \
                    docker-client \
                    docker-client-latest \
                    docker-common \
                    docker-latest \
                    docker-latest-logrotate \
                    docker-logrotate \
                    docker-engine 2>/dev/null || true
                ;;
        esac
        info "旧版本已卸载"
    else
        info "未检测到旧版本 Docker"
    fi
}

# Ubuntu/Debian 安装 Docker
install_docker_debian() {
    info "开始安装 Docker (Ubuntu/Debian)..."

    # 备份原有源配置
    [ -f /etc/apt/sources.list ] && cp /etc/apt/sources.list /etc/apt/sources.list.bak

    # 配置阿里云 APT 镜像源
    info "配置阿里云 APT 镜像源..."
    # 优先取 os-release 的 VERSION_CODENAME，避免依赖此时尚未安装的 lsb-release
    CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || true)}"
    if [ -z "$CODENAME" ]; then
        error "无法确定系统代号 (codename)，请先安装 lsb-release 后重试"
        exit 1
    fi

    if [ "$OS" = "ubuntu" ]; then
        # Ubuntu 阿里云源
        cat > /etc/apt/sources.list <<EOF
# 阿里云 Ubuntu 镜像源
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $CODENAME-backports main restricted universe multiverse
EOF
    elif [ "$OS" = "debian" ]; then
        # Debian 12 (bookworm) 起安全源套件名由 <codename>/updates 改为 <codename>-security，
        # 并新增 non-free-firmware 组件；按大版本号区分，兼容 Debian 11 及更早
        DEB_MAJOR="${OS_VERSION%%.*}"
        case "$DEB_MAJOR" in
            ''|*[!0-9]*) DEB_MAJOR=12 ;;   # 取不到版本号时按新格式兜底
        esac
        if [ "$DEB_MAJOR" -ge 12 ]; then
            DEB_COMPONENTS="main contrib non-free non-free-firmware"
            DEB_SECURITY_SUITE="${CODENAME}-security"
        else
            DEB_COMPONENTS="main contrib non-free"
            DEB_SECURITY_SUITE="${CODENAME}/updates"
        fi

        # Debian 12 起官方默认启用 deb822 格式源，需先移除避免与 sources.list 重复
        if [ -f /etc/apt/sources.list.d/debian.sources ]; then
            mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak
        fi

        cat > /etc/apt/sources.list <<EOF
# 阿里云 Debian 镜像源
deb https://mirrors.aliyun.com/debian/ $CODENAME $DEB_COMPONENTS
deb https://mirrors.aliyun.com/debian/ $CODENAME-updates $DEB_COMPONENTS
deb https://mirrors.aliyun.com/debian-security $DEB_SECURITY_SUITE $DEB_COMPONENTS
EOF
    fi

    # 更新包索引
    info "更新包索引（使用国内源）..."
    apt-get update

    # 安装依赖包
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Docker 仓库地址：官方源 download.docker.com 在国内常被重置连接，默认走阿里云镜像
    # 可用环境变量覆盖，例如：
    #   sudo DOCKER_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/docker-ce ./docker-install.sh
    DOCKER_MIRROR="${DOCKER_MIRROR:-https://mirrors.aliyun.com/docker-ce}"

    # 添加 Docker 仓库 GPG 密钥（先落盘再 dearmor，避免 curl 失败时 gpg 读到空输入）
    install -m 0755 -d /etc/apt/keyrings
    info "下载 Docker GPG 密钥: $DOCKER_MIRROR/linux/$OS/gpg"
    KEY_TMP=$(mktemp)
    if ! curl -fsSL --connect-timeout 15 --retry 2 -o "$KEY_TMP" "$DOCKER_MIRROR/linux/$OS/gpg"; then
        rm -f "$KEY_TMP"
        error "Docker GPG 密钥下载失败: $DOCKER_MIRROR/linux/$OS/gpg"
        error "可换用其他镜像后重试，例如："
        error "  sudo DOCKER_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/docker-ce $0"
        exit 1
    fi
    # 已存在的密钥文件会让 gpg 交互式询问「是否覆盖」，--batch --yes 保证非交互执行
    rm -f /etc/apt/keyrings/docker.gpg
    gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg < "$KEY_TMP"
    rm -f "$KEY_TMP"
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_MIRROR/linux/$OS \
      $CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 再次更新包索引
    apt-get update

    # 安装 Docker
    info "安装 Docker 及相关组件..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    info "Docker 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 Docker
install_docker_rhel() {
    info "开始安装 Docker (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 备份原有 YUM 源配置
    [ -f /etc/yum.repos.d/CentOS-Base.repo ] && cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak 2>/dev/null || true

    # 配置阿里云 YUM 镜像源
    info "配置阿里云 YUM 镜像源..."

    if [ "$OS" = "centos" ]; then
        # CentOS 7/8 阿里云源
        if [ -f /etc/centos-release ]; then
            CENTOS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release | cut -d. -f1)
            if [ "$CENTOS_VERSION" = "7" ]; then
                curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
            elif [ "$CENTOS_VERSION" = "8" ]; then
                curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
            fi
        fi
    elif [ "$OS" = "rocky" ] || [ "$OS" = "almalinux" ]; then
        # Rocky Linux/AlmaLinux 使用 RHEL 阿里云源
        sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/*.repo
        sed -i 's|#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' /etc/yum.repos.d/*.repo 2>/dev/null || true
    fi

    # 清理缓存并重建
    yum clean all
    yum makecache

    # 安装依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2

    # 添加 Docker 仓库（使用阿里云镜像）
    info "添加 Docker 仓库..."
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

    # 如果阿里云 Docker 仓库不可用，使用官方仓库
    if ! yum repolist | grep -q "docker-ce"; then
        warn "阿里云 Docker 仓库不可用，切换到官方源..."
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    fi

    # 安装 Docker
    info "安装 Docker 及相关组件..."
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    info "Docker 安装完成"
}

# 配置 Docker 守护进程
configure_docker() {
    info "配置 Docker 守护进程和国内镜像源..."

    # 创建配置目录
    mkdir -p /etc/docker

    # 配置 daemon.json - 使用国内镜像加速
    cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://docker.anyhub.us.kg",
    "https://dockerhub.jobcher.com",
    "https://docker.m.daocloud.io",
    "https://dockerpull.org",
    "https://docker.awsl9527.cn"
  ],
  "max-concurrent-downloads": 10,
  "max-download-attempts": 5
}
EOF

    info "Docker 配置完成"
    info "已配置以下国内镜像源:"
    info "  - https://docker.1panel.live"
    info "  - https://docker.anyhub.us.kg"
    info "  - https://dockerhub.jobcher.com"
    info "  - https://docker.m.daocloud.io"
    info "  - https://dockerpull.org"
    info "  - https://docker.awsl9527.cn"
}

# 启动并启用 Docker
start_docker() {
    info "启动 Docker 服务..."

    # 启用并启动 Docker
    systemctl daemon-reload
    systemctl enable docker
    systemctl start docker

    # 检查 Docker 状态
    if systemctl is-active --quiet docker; then
        info "Docker 服务运行正常"
    else
        error "Docker 服务启动失败"
        systemctl status docker
        exit 1
    fi
}

# 将当前用户添加到 docker 组
add_user_to_docker_group() {
    if [ -n "$SUDO_USER" ]; then
        info "将用户 $SUDO_USER 添加到 docker 组..."
        usermod -aG docker "$SUDO_USER"
        info "请注销并重新登录以使组权限生效"
        info "或运行: newgrp docker"
    fi
}

# 验证安装
verify_installation() {
    info "验证 Docker 安装..."

    docker --version
    docker compose version

    # 运行测试容器（依赖外网拉取镜像，失败只警告，不影响已完成的安装）
    info "运行测试容器..."
    if docker run --rm hello-world; then
        info "Docker 安装验证成功！"
    else
        warn "测试容器运行失败：Docker 本体已安装成功，仅镜像拉取不通"
        warn "多为国内网络无法访问 Docker Hub，请检查 /etc/docker/daemon.json 的 registry-mirrors"
        warn "修复后可执行: docker pull hello-world"
    fi
}

# 显示安装信息
show_info() {
    echo ""
    echo "============================================"
    info "Docker 安装完成！"
    echo "============================================"
    echo ""
    echo "常用命令:"
    echo "  docker --version          # 查看 Docker 版本"
    echo "  docker ps                 # 查看运行中的容器"
    echo "  docker images             # 查看镜像列表"
    echo "  docker compose version    # 查看 Docker Compose 版本"
    echo ""
    echo "Docker 服务管理:"
    echo "  systemctl start docker    # 启动 Docker"
    echo "  systemctl stop docker     # 停止 Docker"
    echo "  systemctl restart docker  # 重启 Docker"
    echo "  systemctl status docker   # 查看 Docker 状态"
    echo ""
}

# 主函数
main() {
    echo "============================================"
    echo "       Docker 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    uninstall_old_docker

    case $OS in
        ubuntu|debian)
            install_docker_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_docker_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_docker
    start_docker
    add_user_to_docker_group
    verify_installation
    show_info
}

# 运行主函数
main "$@"

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
    if [ "$OS" = "ubuntu" ]; then
        # Ubuntu 阿里云源
        cat > /etc/apt/sources.list <<EOF
# 阿里云 Ubuntu 镜像源
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
EOF
    elif [ "$OS" = "debian" ]; then
        # Debian 阿里云源
        cat > /etc/apt/sources.list <<EOF
# 阿里云 Debian 镜像源
deb https://mirrors.aliyun.com/debian/ $(lsb_release -cs) main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian/ $(lsb_release -cs)-updates main contrib non-free non-free-firmware
deb https://mirrors.aliyun.com/debian-security $(lsb_release -cs)/updates main contrib non-free non-free-firmware
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

    # 添加 Docker 官方 GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库（使用官方源，但通过国内源下载依赖）
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

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

    # 运行测试容器
    info "运行测试容器..."
    docker run --rm hello-world

    if [ $? -eq 0 ]; then
        info "Docker 安装验证成功！"
    else
        error "Docker 安装验证失败"
        exit 1
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

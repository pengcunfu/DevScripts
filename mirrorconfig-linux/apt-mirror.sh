#!/bin/bash
# ============================================
# APT 镜像源配置 (Debian / Ubuntu)
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 检测发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        error "无法检测系统类型"
        exit 1
    fi
}

# 选择镜像源
select_mirror() {
    echo ""
    echo "  APT 镜像源配置"
    echo "  ================="
    echo ""
    echo "  [1] 阿里云"
    echo "  [2] 腾讯云"
    echo "  [3] 华为云"
    echo "  [4] 清华大学"
    echo "  [5] 中科大"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-5]: " choice

    case $choice in
        1) echo "aliyun" ;;
        2) echo "tencent" ;;
        3) echo "huawei" ;;
        4) echo "tsinghua" ;;
        5) echo "ustc" ;;
        0) exit 0 ;;
        *) error "无效选项"; exit 1 ;;
    esac
}

# Ubuntu
config_ubuntu() {
    local mirror=$1
    local sources_file="/etc/apt/sources.list"
    backup_sources "$sources_file"

    local codename=$(lsb_release -cs 2>/dev/null || echo "jammy")

    case $mirror in
        aliyun)
            cat > "$sources_file" << EOF
deb http://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $codename-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        tencent)
            cat > "$sources_file" << EOF
deb http://mirrors.cloud.tencent.com/ubuntu/ $codename main restricted universe multiverse
deb http://mirrors.cloud.tencent.com/ubuntu/ $codename-security main restricted universe multiverse
deb http://mirrors.cloud.tencent.com/ubuntu/ $codename-updates main restricted universe multiverse
deb http://mirrors.cloud.tencent.com/ubuntu/ $codename-proposed main restricted universe multiverse
deb http://mirrors.cloud.tencent.com/ubuntu/ $codename-backports main restricted universe multiverse
deb-src http://mirrors.cloud.tencent.com/ubuntu/ $codename main restricted universe multiverse
deb-src http://mirrors.cloud.tencent.com/ubuntu/ $codename-security main restricted universe multiverse
deb-src http://mirrors.cloud.tencent.com/ubuntu/ $codename-updates main restricted universe multiverse
deb-src http://mirrors.cloud.tencent.com/ubuntu/ $codename-proposed main restricted universe multiverse
deb-src http://mirrors.cloud.tencent.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        tsinghua)
            cat > "$sources_file" << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
EOF
            ;;
        ustc)
            cat > "$sources_file" << EOF
deb https://mirrors.ustc.edu.cn/ubuntu/ $codename main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
EOF
            ;;
    esac
}

# Debian
config_debian() {
    local mirror=$1
    local sources_file="/etc/apt/sources.list"
    backup_sources "$sources_file"

    local codename=$(lsb_release -cs 2>/dev/null || echo "bullseye")

    case $mirror in
        aliyun)
            cat > "$sources_file" << EOF
deb http://mirrors.aliyun.com/debian/ $codename main non-free contrib
deb http://mirrors.aliyun.com/debian/ $codename-updates main non-free contrib
deb http://mirrors.aliyun.com/debian/ $codename-backports main non-free contrib
deb http://mirrors.aliyun.com/debian-security $codename/updates main non-free contrib
EOF
            ;;
        tencent)
            cat > "$sources_file" << EOF
deb http://mirrors.cloud.tencent.com/debian/ $codename main non-free contrib
deb http://mirrors.cloud.tencent.com/debian/ $codename-updates main non-free contrib
deb http://mirrors.cloud.tencent.com/debian/ $codename-backports main non-free contrib
deb http://mirrors.cloud.tencent.com/debian-security $codename/updates main non-free contrib
EOF
            ;;
        tsinghua)
            cat > "$sources_file" << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $codename/updates main contrib non-free
EOF
            ;;
        ustc)
            cat > "$sources_file" << EOF
deb https://mirrors.ustc.edu.cn/debian/ $codename main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ $codename-updates main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ $codename-backports main contrib non-free
deb https://mirrors.ustc.edu.cn/debian-security $codename/updates main contrib non-free
EOF
            ;;
    esac
}

# Main
detect_distro
mirror=$(select_mirror)

if [ "$OS" = "ubuntu" ]; then
    config_ubuntu "$mirror"
elif [ "$OS" = "debian" ]; then
    config_debian "$mirror"
else
    error "不支持的系统: $OS"
    exit 1
fi

info "更新软件包列表..."
apt-get update
success "APT 镜像源配置完成！"

#!/bin/bash
# ============================================
# Pacman 镜像源配置 (Arch Linux)
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

select_mirror() {
    echo ""
    echo "  Pacman 镜像源配置"
    echo "  ================="
    echo ""
    echo "  [1] 阿里云"
    echo "  [2] 腾讯云"
    echo "  [3] 华为云"
    echo "  [4] 清华大学"
    echo "  [5] 中科大"
    echo "  [6] 自动选择最快镜像 (reflector)"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-6]: " choice

    echo "$choice"
}

mirrorlist_file="/etc/pacman.d/mirrorlist"
backup_sources "$mirrorlist_file"

choice=$(select_mirror)

case $choice in
    1)
        sed -i 's/^/#/' "$mirrorlist_file"
        echo "## 阿里云镜像" >> "$mirrorlist_file"
        echo "Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch" >> "$mirrorlist_file"
        ;;
    2)
        sed -i 's/^/#/' "$mirrorlist_file"
        echo "## 腾讯云镜像" >> "$mirrorlist_file"
        echo "Server = https://mirrors.cloud.tencent.com/archlinux/$repo/os/$arch" >> "$mirrorlist_file"
        ;;
    3)
        sed -i 's/^/#/' "$mirrorlist_file"
        echo "## 华为云镜像" >> "$mirrorlist_file"
        echo "Server = https://mirrors.huaweicloud.com/archlinux/$repo/os/$arch" >> "$mirrorlist_file"
        ;;
    4)
        sed -i 's/^/#/' "$mirrorlist_file"
        echo "## 清华大学镜像" >> "$mirrorlist_file"
        echo "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch" >> "$mirrorlist_file"
        ;;
    5)
        sed -i 's/^/#/' "$mirrorlist_file"
        echo "## 中科大镜像" >> "$mirrorlist_file"
        echo "Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch" >> "$mirrorlist_file"
        ;;
    6)
        if command -v reflector &> /dev/null; then
            info "使用 reflector 自动选择最快镜像..."
            reflector --fastest 10 --save --sort rate
        else
            error "未安装 reflector，请先安装: pacman -S reflector"
            exit 1
        fi
        ;;
    0) exit 0 ;;
    *) error "无效选项"; exit 1 ;;
esac

info "更新软件包数据库..."
pacman -Sy
success "Pacman 镜像源配置完成！"

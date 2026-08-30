#!/bin/bash
# ============================================
# PIP 镜像源配置
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

select_mirror() {
    echo ""
    echo "  PIP 镜像源配置"
    echo "  ==============="
    echo ""
    echo "  [1] 阿里云"
    echo "  [2] 豆瓣"
    echo "  [3] 清华大学"
    echo "  [4] 中科大"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-4]: " choice

    case $choice in
        1) echo "aliyun" ;;
        2) echo "douban" ;;
        3) echo "tsinghua" ;;
        4) echo "ustc" ;;
        0) exit 0 ;;
        *) error "无效选项"; exit 1 ;;
    esac
}

# Main
mirror=$(select_mirror)

pip_config_dir="$HOME/.pip"
pip_config_file="$pip_config_dir/pip.conf"
mkdir -p "$pip_config_dir"

case $mirror in
    aliyun)
        cat > "$pip_config_file" << EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com
EOF
        ;;
    douban)
        cat > "$pip_config_file" << EOF
[global]
index-url = http://pypi.douban.com/simple/
trusted-host = pypi.douban.com
EOF
        ;;
    tsinghua)
        cat > "$pip_config_file" << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
        ;;
    ustc)
        cat > "$pip_config_file" << EOF
[global]
index-url = https://pypi.mirrors.ustc.edu.cn/simple/
trusted-host = pypi.mirrors.ustc.edu.cn
EOF
        ;;
esac

success "PIP 镜像源配置完成！"
info "配置文件: $pip_config_file"

#!/bin/bash
# ============================================
# NPM 镜像源配置
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

select_mirror() {
    echo ""
    echo "  NPM 镜像源配置"
    echo "  ==============="
    echo ""
    echo "  [1] 淘宝镜像"
    echo "  [2] 腾讯云"
    echo "  [3] 华为云"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-3]: " choice

    case $choice in
        1) echo "taobao" ;;
        2) echo "tencent" ;;
        3) echo "huawei" ;;
        0) exit 0 ;;
        *) error "无效选项"; exit 1 ;;
    esac
}

# Main
mirror=$(select_mirror)

case $mirror in
    taobao)
        npm config set registry https://registry.npmmirror.com
        ;;
    tencent)
        npm config set registry https://mirrors.cloud.tencent.com/npm/
        ;;
    huawei)
        npm config set registry https://mirrors.huaweicloud.com/repository/npm/
        ;;
esac

success "NPM 镜像源配置完成！"
info "当前镜像源: $(npm config get registry)"

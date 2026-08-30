#!/bin/bash
# ============================================
# Docker 镜像源配置
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 需要 root 权限
if [ $EUID -ne 0 ]; then
    error "Docker 镜像源配置需要 root 权限，请使用 sudo 运行"
    exit 1
fi

select_mirror() {
    echo ""
    echo "  Docker 镜像源配置"
    echo "  ================="
    echo ""
    echo "  [1] 阿里云"
    echo "  [2] 腾讯云"
    echo "  [3] 华为云"
    echo "  [4] 网易"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-4]: " choice

    case $choice in
        1) echo "aliyun" ;;
        2) echo "tencent" ;;
        3) echo "huawei" ;;
        4) echo "netease" ;;
        0) exit 0 ;;
        *) error "无效选项"; exit 1 ;;
    esac
}

# Main
mirror=$(select_mirror)

docker_config_dir="/etc/docker"
docker_config_file="$docker_config_dir/daemon.json"
mkdir -p "$docker_config_dir"

case $mirror in
    aliyun)
        cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]
}
EOF
        ;;
    tencent)
        cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
EOF
        ;;
    huawei)
        cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://registry.cn-north-4.huaweicloud.com"]
}
EOF
        ;;
    netease)
        cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"]
}
EOF
        ;;
esac

info "重启 Docker 服务..."
systemctl restart docker
success "Docker 镜像源配置完成！"

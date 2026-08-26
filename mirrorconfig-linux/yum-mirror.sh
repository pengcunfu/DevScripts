#!/bin/bash
# ============================================
# YUM/DNF 镜像源配置 (CentOS / Fedora)
# ============================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 检测包管理器
if command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
else
    error "未找到 yum 或 dnf"
    exit 1
fi

select_mirror() {
    echo ""
    echo "  YUM/DNF 镜像源配置"
    echo "  ==================="
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

config_centos() {
    local mirror=$1
    local repo_dir="/etc/yum.repos.d"
    backup_sources "${repo_dir}/CentOS-Base.repo"

    case $mirror in
        aliyun)
            if grep -q "release 7" /etc/centos-release 2>/dev/null; then
                cat > "${repo_dir}/CentOS-Base.repo" << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            else
                cat > "${repo_dir}/CentOS-Base.repo" << 'EOF'
[baseos]
name=CentOS-$releasever - Base - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever-stream/BaseOS/$basearch/os/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official

[appstream]
name=CentOS-$releasever - AppStream - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever-stream/AppStream/$basearch/os/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-Official
EOF
            fi
            ;;
        tencent)
            cat > "${repo_dir}/CentOS-Base.repo" << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.tencent.com
baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - mirrors.tencent.com
baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - mirrors.tencent.com
baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
        tsinghua)
            wget -O "${repo_dir}/CentOS-Base.repo" https://mirrors.tuna.tsinghua.edu.cn/help/centos/ 2>/dev/null || \
            curl -o "${repo_dir}/CentOS-Base.repo" https://mirrors.tuna.tsinghua.edu.cn/help/centos/ 2>/dev/null
            ;;
        ustc)
            cat > "${repo_dir}/CentOS-Base.repo" << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-Official

[updates]
name=CentOS-$releasever - Updates - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-Official

[extras]
name=CentOS-$releasever - Extras - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-Official
EOF
            ;;
    esac
}

config_fedora() {
    local mirror=$1
    case $mirror in
        tsinghua)
            info "使用清华大学镜像..."
            # Fedora metalink 自动选择最优镜像
            warn "Fedora 推荐使用默认 metalink，已自动选择最优镜像"
            ;;
        *)
            warn "Fedora 建议使用默认配置，系统会自动选择最快镜像"
            ;;
    esac
}

# Main
mirror=$(select_mirror)

if [ "$PKG_MANAGER" = "dnf" ]; then
    config_fedora "$mirror"
else
    config_centos "$mirror"
fi

info "清理缓存并重新生成..."
$PKG_MANAGER clean all
$PKG_MANAGER makecache
success "YUM/DNF 镜像源配置完成！"

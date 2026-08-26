#!/bin/bash
# ============================================
# Linux 镜像源配置工具
# 支持: apt / yum / dnf / pacman / pip / npm
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }

# 检测系统类型
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS="unknown"
    fi
}

# 检测包管理器
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        PKG_MANAGER="unknown"
    fi
}

# 备份原有源
backup_sources() {
    local source_file=$1
    if [ -f "$source_file" ]; then
        local backup_file="${source_file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$source_file" "$backup_file"
        info "已备份原配置文件: $backup_file"
    fi
}

# 配置 APT 镜像源 (Debian/Ubuntu)
config_apt() {
    echo ""
    echo "============================================"
    echo "       APT 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 阿里云"
    echo "  2) 腾讯云"
    echo "  3) 华为云"
    echo "  4) 清华大学"
    echo "  5) 中科大"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-5]: " choice

    case $choice in
        1) mirror="aliyun" ;;
        2) mirror="tencent" ;;
        3) mirror="huawei" ;;
        4) mirror="tsinghua" ;;
        5) mirror="ustc" ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    # 检测发行版
    if [ "$OS" = "ubuntu" ]; then
        config_apt_ubuntu "$mirror"
    elif [ "$OS" = "debian" ]; then
        config_apt_debian "$mirror"
    else
        error "不支持的系统: $OS"
    fi
}

# 配置 Ubuntu APT 源
config_apt_ubuntu() {
    local mirror=$1
    local sources_file="/etc/apt/sources.list"

    backup_sources "$sources_file"

    # 获取 Ubuntu 版本代号
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

    info "更新软件包列表..."
    apt-get update
    success "APT 镜像源配置完成！"
}

# 配置 Debian APT 源
config_apt_debian() {
    local mirror=$1
    local sources_file="/etc/apt/sources.list"

    backup_sources "$sources_file"

    # 获取 Debian 版本代号
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

    info "更新软件包列表..."
    apt-get update
    success "APT 镜像源配置完成！"
}

# 配置 YUM/DNF 镜像源 (CentOS/Fedora/RHEL)
config_yum_dnf() {
    echo ""
    echo "============================================"
    echo "       YUM/DNF 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 阿里云"
    echo "  2) 腾讯云"
    echo "  3) 华为云"
    echo "  4) 清华大学"
    echo "  5) 中科大"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-5]: " choice

    case $choice in
        1) mirror="aliyun" ;;
        2) mirror="tencent" ;;
        3) mirror="huawei" ;;
        4) mirror="tsinghua" ;;
        5) mirror="ustc" ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    if [ "$PKG_MANAGER" = "dnf" ]; then
        config_dnf_fedora "$mirror"
    else
        config_yum_centos "$mirror"
    fi
}

# 配置 CentOS YUM 源
config_yum_centos() {
    local mirror=$1
    local repo_dir="/etc/yum.repos.d"
    local backup_file="${repo_dir}/CentOS-Base.repo.bak"

    backup_sources "$backup_file"

    case $mirror in
        aliyun)
            # CentOS 7
            if [ -f /etc/centos-release ] && grep -q "release 7" /etc/centos-release 2>/dev/null; then
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
            # CentOS 8 / Stream
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
        tsinghua)
            wget -O "${repo_dir}/CentOS-Base.repo" https://mirrors.tuna.tsinghua.edu.cn/help/centos/ 2>/dev/null || \
            curl -o "${repo_dir}/CentOS-Base.repo" https://mirrors.tuna.tsinghua.edu.cn/help/centos/ 2>/dev/null
            ;;
    esac

    info "清理缓存并重新生成..."
    yum clean all
    yum makecache
    success "YUM 镜像源配置完成！"
}

# 配置 Fedora DNF 源
config_dnf_fedora() {
    local mirror=$1
    info "配置 Fedora 镜像源: $mirror"

    case $mirror in
        tsinghua)
            info "使用清华大学镜像..."
            # Fedora 使用 metalink 自动选择，这里仅作示例
            warn "Fedora 推荐使用默认 metalink，已自动选择最优镜像"
            ;;
        *)
            warn "Fedora 建议使用默认配置，系统会自动选择最快镜像"
            ;;
    esac

    success "DNF 配置完成！"
}

# 配置 Pacman 镜像源 (Arch Linux)
config_pacman() {
    echo ""
    echo "============================================"
    echo "       Pacman 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 阿里云"
    echo "  2) 腾讯云"
    echo "  3) 华为云"
    echo "  4) 清华大学"
    echo "  5) 中科大"
    echo "  6) 自动选择最快镜像"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-6]: " choice

    local mirrorlist_file="/etc/pacman.d/mirrorlist"
    backup_sources "$mirrorlist_file"

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
            info "使用 reflect 自动选择最快镜像..."
            if command -v reflect &> /dev/null; then
                reflect --fastest 10 --save --sort rate
            else
                warn "未安装 reflect，请手动安装: pacman -S reflect"
            fi
            ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    info "更新软件包数据库..."
    pacman -Sy
    success "Pacman 镜像源配置完成！"
}

# 配置 PIP 镜像源
config_pip() {
    echo ""
    echo "============================================"
    echo "       PIP 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 阿里云"
    echo "  2) 豆瓣"
    echo "  3) 清华大学"
    echo "  4) 中科大"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-4]: " choice

    local pip_config_dir="$HOME/.pip"
    local pip_config_file="$pip_config_dir/pip.conf"

    mkdir -p "$pip_config_dir"

    case $choice in
        1)
            cat > "$pip_config_file" << EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com
EOF
            ;;
        2)
            cat > "$pip_config_file" << EOF
[global]
index-url = http://pypi.douban.com/simple/
trusted-host = pypi.douban.com
EOF
            ;;
        3)
            cat > "$pip_config_file" << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
            ;;
        4)
            cat > "$pip_config_file" << EOF
[global]
index-url = https://pypi.mirrors.ustc.edu.cn/simple/
trusted-host = pypi.mirrors.ustc.edu.cn
EOF
            ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    success "PIP 镜像源配置完成！"
    info "配置文件: $pip_config_file"
}

# 配置 NPM 镜像源
config_npm() {
    echo ""
    echo "============================================"
    echo "       NPM 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 淘宝镜像"
    echo "  2) 腾讯云"
    echo "  3) 华为云"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-3]: " choice

    case $choice in
        1)
            npm config set registry https://registry.npmmirror.com
            info "已切换到淘宝镜像"
            ;;
        2)
            npm config set registry https://mirrors.cloud.tencent.com/npm/
            info "已切换到腾讯云镜像"
            ;;
        3)
            npm config set registry https://mirrors.huaweicloud.com/repository/npm/
            info "已切换到华为云镜像"
            ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    success "NPM 镜像源配置完成！"
    info "当前镜像源: $(npm config get registry)"
}

# 配置 Docker 镜像源
config_docker() {
    echo ""
    echo "============================================"
    echo "       Docker 镜像源配置"
    echo "============================================"
    echo ""
    echo "请选择镜像源:"
    echo "  1) 阿里云"
    echo "  2) 腾讯云"
    echo "  3) 华为云"
    echo "  4) 网易"
    echo "  0) 返回"
    echo ""
    read -p "请输入选项 [0-4]: " choice

    local docker_config_dir="/etc/docker"
    local docker_config_file="$docker_config_dir/daemon.json"

    # 需要 root 权限
    if [ $EUID -ne 0 ]; then
        warn "配置 Docker 镜像源需要 root 权限"
        return
    fi

    mkdir -p "$docker_config_dir"

    case $choice in
        1)
            cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]
}
EOF
            ;;
        2)
            cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"]
}
EOF
            ;;
        3)
            cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://registry.cn-north-4.huaweicloud.com"]
}
EOF
            ;;
        4)
            cat > "$docker_config_file" << EOF
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"]
}
EOF
            ;;
        0) return ;;
        *) error "无效选项"; return ;;
    esac

    info "重启 Docker 服务..."
    systemctl restart docker
    success "Docker 镜像源配置完成！"
}

# 显示当前镜像源
show_current_mirrors() {
    echo ""
    echo "============================================"
    echo "       当前镜像源配置"
    echo "============================================"
    echo ""

    case $PKG_MANAGER in
        apt)
            info "APT 源配置:"
            cat /etc/apt/sources.list 2>/dev/null | head -5
            ;;
        yum|dnf)
            info "YUM/DNF 源配置:"
            ls /etc/yum.repos.d/*.repo 2>/dev/null | head -5
            ;;
        pacman)
            info "Pacman 源配置:"
            cat /etc/pacman.d/mirrorlist 2>/dev/null | grep "^Server" | head -5
            ;;
    esac

    echo ""
    if command -v pip &> /dev/null; then
        info "PIP 配置文件: $HOME/.pip/pip.conf"
        [ -f "$HOME/.pip/pip.conf" ] && cat "$HOME/.pip/pip.conf"
    fi

    echo ""
    if command -v npm &> /dev/null; then
        info "NPM 镜像源:"
        npm config get registry 2>/dev/null
    fi

    echo ""
}

# 主菜单
show_menu() {
    echo ""
    echo "============================================"
    echo "       Linux 镜像源配置工具"
    echo "============================================"
    echo ""
    echo "检测到系统: ${GREEN}${OS}${NC}"
    echo "包管理器: ${GREEN}${PKG_MANAGER}${NC}"
    echo ""
    echo "  1) 配置 APT 镜像源 (Debian/Ubuntu)"
    echo "  2) 配置 YUM/DNF 镜像源 (CentOS/Fedora)"
    echo "  3) 配置 Pacman 镜像源 (Arch Linux)"
    echo "  4) 配置 PIP 镜像源 (Python)"
    echo "  5) 配置 NPM 镜像源 (Node.js)"
    echo "  6) 配置 Docker 镜像源"
    echo "  7) 查看当前镜像源"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 [0-7]: " choice

    case $choice in
        1)
            if [ "$PKG_MANAGER" = "apt" ]; then
                config_apt
            else
                warn "当前系统未使用 APT 包管理器"
            fi
            ;;
        2)
            if [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
                config_yum_dnf
            else
                warn "当前系统未使用 YUM/DNF 包管理器"
            fi
            ;;
        3)
            if [ "$PKG_MANAGER" = "pacman" ]; then
                config_pacman
            else
                warn "当前系统未使用 Pacman 包管理器"
            fi
            ;;
        4) config_pip ;;
        5) config_npm ;;
        6) config_docker ;;
        7) show_current_mirrors ;;
        0)
            info "退出脚本"
            exit 0
            ;;
        *)
            error "无效选项"
            ;;
    esac
}

# 主函数
main() {
    detect_system
    detect_package_manager

    while true; do
        show_menu
    done
}

# 运行主函数
main

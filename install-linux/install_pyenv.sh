#!/bin/bash
# ============================================
# 一键安装 Python 版本管理器脚本
# 支持: pyenv / conda
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }

# Python 版本
PYTHON_VERSION=${PYTHON_VERSION:-""}

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
    else
        OS="unknown"
    fi
    info "检测到系统: $OS $OS_VERSION"
}

# 安装依赖
install_dependencies() {
    info "安装编译依赖..."

    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y \
                build-essential \
                libssl-dev \
                zlib1g-dev \
                libbz2-dev \
                libreadline-dev \
                libsqlite3-dev \
                curl \
                git \
                libncursesw5-dev \
                xz-utils \
                tk-dev \
                libxml2-dev \
                libxmlsec1-dev \
                libffi-dev \
                liblzma-dev \
                python3-venv \
                python3-pip
            ;;
        centos|rhel|rocky|almalinux)
            yum groupinstall -y "Development Tools"
            yum install -y \
                openssl-devel \
                zlib-devel \
                bzip2-devel \
                readline-devel \
                sqlite-devel \
                curl \
                git \
                libxml2-devel \
                libxslt-devel \
                libffi-devel \
                lzma-sdk-devel \
                python3-devel
            ;;
    esac

    info "依赖安装完成"
}

# 安装 pyenv
install_pyenv() {
    info "安装 pyenv..."

    # 为当前用户安装
    INSTALL_USER=${SUDO_USER:-"root"}

    if [ "$INSTALL_USER" = "root" ]; then
        PYENV_ROOT="/root/.pyenv"
    else
        PYENV_ROOT="/home/$INSTALL_USER/.pyenv"
    fi

    # 克隆 pyenv
    if [ ! -d "$PYENV_ROOT" ]; then
        sudo -u "$INSTALL_USER" git clone https://mirrors.aliyun.com/pyenv/pyenv.git "$PYENV_ROOT" || \
        sudo -u "$INSTALL_USER" git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
    fi

    # 克隆 pyenv-virtualenv
    if [ ! -d "${PYENV_ROOT}/plugins/pyenv-virtualenv" ]; then
        sudo -u "$INSTALL_USER" git clone https://mirrors.aliyun.com/pyenv/pyenv-virtualenv.git "${PYENV_ROOT}/plugins/pyenv-virtualenv" || \
        sudo -u "$INSTALL_USER" git clone https://github.com/pyenv/pyenv-virtualenv.git "${PYENV_ROOT}/plugins/pyenv-virtualenv"
    fi

    # 配置环境变量
    if [ "$INSTALL_USER" != "root" ]; then
        USER_HOME="/home/$INSTALL_USER"
        BASHRC="$USER_HOME/.bashrc"

        # 添加到 .bashrc
        if ! grep -q "pyenv" "$BASHRC" 2>/dev/null; then
            cat >> "$BASHRC" <<'EOF'

# pyenv 配置
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
        fi
    fi

    # 为 root 配置
    if ! grep -q "pyenv" /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc <<'EOF'

# pyenv 配置
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
    fi

    # 创建全局配置
    cat > /etc/profile.d/pyenv.sh <<'EOF'
# pyenv 全局配置
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if [ -d "$PYENV_ROOT" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
EOF

    # 立即生效
    export PYENV_ROOT="$PYENV_ROOT"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

    success "pyenv 安装完成"
}

# 安装 Miniconda
install_miniconda() {
    info "安装 Miniconda..."

    INSTALL_USER=${SUDO_USER:-"root"}

    if [ "$INSTALL_USER" = "root" ]; then
        CONDA_DIR="/root/miniconda3"
    else
        CONDA_DIR="/home/$INSTALL_USER/miniconda3"
    fi

    # 下载 Miniconda
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CONDA_URL="https://mirrors.aliyun.com/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
            ;;
        aarch64|arm64)
            CONDA_URL="https://mirrors.aliyun.com/anaconda/miniconda/Miniconda3-latest-Linux-aarch64.sh"
            ;;
        *)
            error "不支持的架构: $ARCH"
            return 1
            ;;
    esac

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    info "下载 Miniconda..."
    curl -LO "$CONDA_URL"

    # 安装
    sudo -u "$INSTALL_USER" bash Miniconda3-latest-Linux-*.sh -b -p "$CONDA_DIR"

    # 清理
    cd /
    rm -rf "$TMP_DIR"

    # 配置环境变量
    if [ "$INSTALL_USER" != "root" ]; then
        USER_HOME="/home/$INSTALL_USER"
        BASHRC="$USER_HOME/.bashrc"

        if ! grep -q "miniconda3" "$BASHRC" 2>/dev/null; then
            cat >> "$BASHRC" <<EOF

# Miniconda 配置
export PATH="$CONDA_DIR/bin:\$PATH"
EOF
        fi
    fi

    # 配置 conda 源
    "$CONDA_DIR/bin/conda" config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free/
    "$CONDA_DIR/bin/conda" config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main/
    "$CONDA_DIR/bin/conda" config --set show_channel_urls yes

    success "Miniconda 安装完成"
}

# 安装 Python 版本
install_python_version() {
    if [ -z "$PYTHON_VERSION" ]; then
        info "未指定 Python 版本，跳过安装"
        return
    fi

    info "安装 Python $PYTHON_VERSION..."

    if command -v pyenv &> /dev/null; then
        # 配置镜像加速
        export PYTHON_BUILD_MIRROR_URL="https://mirrors.huaweicloud.com/python"

        # 安装 Python
        pyenv install "$PYTHON_VERSION"

        # 设置全局版本
        pyenv global "$PYTHON_VERSION"

        success "Python $PYTHON_VERSION 安装完成"
    else
        warn "pyenv 未安装，无法安装指定版本"
    fi
}

# 配置 pip 国内镜像
configure_pip_mirror() {
    info "配置 pip 国内镜像..."

    # 创建 pip 配置
    mkdir -p /root/.pip
    cat > /root/.pip/pip.conf <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com

[install]
trusted-host = mirrors.aliyun.com
EOF

    # 为其他用户配置
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        mkdir -p "$USER_HOME/.pip"
        cat > "$USER_HOME/.pip/pip.conf" <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com

[install]
trusted-host = mirrors.aliyun.com
EOF
        chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.pip"
    fi

    success "pip 镜像配置完成"
}

# 验证安装
verify_installation() {
    info "验证安装..."

    if command -v pyenv &> /dev/null; then
        pyenv --version
        echo ""
        info "已安装的 Python 版本:"
        pyenv versions || echo "无"
    fi

    if command -v conda &> /dev/null; then
        conda --version
    fi

    python3 --version 2>/dev/null || python --version
    pip3 --version 2>/dev/null || pip --version
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    success "Python 环境安装完成！"
    echo "============================================"
    echo ""
    echo "pyenv 命令:"
    echo "  pyenv versions                    # 查看已安装版本"
    echo "  pyenv install <version>           # 安装 Python 版本"
    echo "  pyenv uninstall <version>         # 卸载版本"
    echo "  pyenv global <version>            # 设置全局版本"
    echo "  pyenv local <version>             # 设置当前目录版本"
    echo "  pyenv shell <version>             # 设置当前会话版本"
    echo ""
    echo "conda 命令:"
    echo "  conda create -n <name> python=3.x # 创建环境"
    echo "  conda activate <name>             # 激活环境"
    echo "  conda deactivate                  # 退出环境"
    echo "  conda env list                    # 查看环境列表"
    echo "  conda remove -n <name> --all      # 删除环境"
    echo ""
    echo "pip 命令:"
    echo "  pip install <package>             # 安装包"
    echo "  pip install -r requirements.txt   # 安装依赖"
    echo "  pip list                          # 查看已安装包"
    echo "  pip freeze > requirements.txt     # 导出依赖"
    echo ""
    echo "虚拟环境:"
    echo "  python3 -m venv <name>            # 创建虚拟环境"
    echo "  source <name>/bin/activate        # 激活环境"
    echo "  deactivate                        # 退出环境"
    echo ""
    echo "请执行以下命令使环境变量生效:"
    echo "  source ~/.bashrc"
    echo "  或重新登录系统"
    echo ""
}

# 交互式选择
interactive_select() {
    echo ""
    echo "请选择 Python 版本管理器:"
    echo "  1) pyenv (推荐，轻量级)"
    echo "  2) Miniconda (适合数据科学)"
    echo "  3) 两者都安装"
    echo ""
    read -p "请输入选项 [1-3] (默认: 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            INSTALL_PYENV=true
            INSTALL_CONDA=false
            ;;
        2)
            INSTALL_PYENV=false
            INSTALL_CONDA=true
            ;;
        3)
            INSTALL_PYENV=true
            INSTALL_CONDA=true
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac

    if [ "$INSTALL_PYENV" = true ]; then
        echo ""
        echo "常用 Python 版本:"
        echo "  3.12.0  (最新稳定版)"
        echo "  3.11.7"
        echo "  3.10.13"
        echo "  3.9.18"
        echo "  3.8.18"
        echo ""
        read -p "请输入要安装的 Python 版本 (留空跳过): " PYTHON_VERSION
    fi
}

# 主函数
main() {
    echo "============================================"
    echo "       Python 版本管理器一键安装"
    echo "============================================"
    echo ""

    check_root
    detect_os
    interactive_select
    install_dependencies

    if [ "$INSTALL_PYENV" = true ]; then
        install_pyenv
        install_python_version
    fi

    if [ "$INSTALL_CONDA" = true ]; then
        install_miniconda
    fi

    configure_pip_mirror
    verify_installation
    show_info
}

# 运行主函数
main "$@"

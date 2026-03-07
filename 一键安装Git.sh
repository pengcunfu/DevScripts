#!/bin/bash
# ============================================
# 一键安装 Git 脚本
# 支持: Ubuntu/Debian/CentOS/RHEL
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

# 默认配置
GIT_USER_NAME=""
GIT_USER_EMAIL=""
GIT_EDITOR="vim"

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
    else
        OS="unknown"
    fi
    info "检测到系统: $OS $OS_VERSION"
}

# 检查已安装的 Git
check_existing_git() {
    if command -v git &> /dev/null; then
        EXISTING_VERSION=$(git --version 2>/dev/null || echo "unknown")
        warn "检测到已安装 Git: $EXISTING_VERSION"
        read -p "是否卸载并重新安装? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_existing_git
        else
            info "保留现有安装，退出脚本"
            exit 0
        fi
    fi
}

# 卸载现有 Git
remove_existing_git() {
    info "卸载现有 Git..."

    # 停止相关服务
    git daemon --stop 2>/dev/null || true

    # 卸载
    case $OS in
        ubuntu|debian)
            apt-get remove -y git git-svn 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            yum remove -y git 2>/dev/null || true
            ;;
    esac

    info "旧版本已卸载"
}

# Ubuntu/Debian 安装 Git
install_git_debian() {
    info "开始安装 Git (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    # 安装依赖
    apt-get install -y \
        curl \
        gettext \
        libcurl4-openssl-dev \
        libexpat1-dev \
        libz-dev \
        libssl-dev \
        build-essential \
        gcc

    # 安装 Git
    apt-get install -y git

    info "Git 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 Git
install_git_rhel() {
    info "开始安装 Git (CentOS/RHEL/Rocky/AlmaLinux)..."

    # 安装依赖
    yum install -y \
        curl \
        gettext \
        libcurl-devel \
        expat-devel \
        zlib-devel \
        openssl-devel \
        gcc \
        perl-ExtUtils-MakeMaker

    # 安装 Git
    yum install -y git

    info "Git 安装完成"
}

# 从源码编译安装最新版 Git (可选)
install_git_from_source() {
    info "从源码编译安装最新版 Git..."

    # 获取最新版本
    GIT_VERSION=$(curl -s https://api.github.com/repos/git/git/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

    if [ -z "$GIT_VERSION" ]; then
        error "无法获取 Git 最新版本"
        return 1
    fi

    info "最新版本: v$GIT_VERSION"

    # 安装编译依赖
    case $OS in
        ubuntu|debian)
            apt-get install -y \
                libcurl4-openssl-dev \
                libexpat1-dev \
                libz-dev \
                libssl-dev \
                build-essential \
                gcc \
                make
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y \
                libcurl-devel \
                expat-devel \
                zlib-devel \
                openssl-devel \
                gcc \
                make
            ;;
    esac

    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    # 下载源码
    info "下载 Git v$GIT_VERSION 源码..."
    curl -LO https://mirrors.edge.kernel.org/pub/software/scm/git/git-$GIT_VERSION.tar.xz || \
    curl -LO https://github.com/git/git/archive/refs/tags/v$GIT_VERSION.tar.gz

    # 解压
    if [ -f "git-$GIT_VERSION.tar.xz" ]; then
        tar -xf git-$GIT_VERSION.tar.xz
        cd git-$GIT_VERSION
    elif [ -f "v$GIT_VERSION.tar.gz" ]; then
        tar -xf v$GIT_VERSION.tar.gz
        cd git-$GIT_VERSION
    else
        error "下载失败"
        return 1
    fi

    # 编译安装
    info "编译 Git (可能需要几分钟)..."
    make configure
    ./configure --prefix=/usr/local
    make -j$(nproc)
    make install

    # 清理
    cd /
    rm -rf "$TMP_DIR"

    info "Git v$GIT_VERSION 编译安装完成"
}

# 配置 Git
configure_git() {
    info "配置 Git..."

    # 创建全局配置目录
    mkdir -p /etc/gitconfig

    # 配置默认编辑器
    git config --system core.editor "$GIT_EDITOR"

    # 配置默认分支名
    git config --system init.defaultBranch main

    # 配置拉取策略
    git config --system pull.rebase false

    # 配置推送策略
    git config --system push.default simple

    # 配置重命名检测
    git config --system diff.renames true

    # 配置颜色输出
    git config --system color.ui true

    # 配置凭证存储
    git config --system credential.helper store

    # 配置 SSL 验证（某些情况下需要）
    # git config --system http.sslVerify false

    # 配置大文件支持
    git config --system http.postBuffer 524288000

    info "Git 全局配置完成"
}

# 配置国内镜像加速
configure_git_mirror() {
    info "配置国内镜像加速..."

    # 为当前用户配置
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)

        # 配置 GitHub 加速
        sudo -u "$SUDO_USER" git config --global url."https://mirror.ghproxy.com/".insteadOf "https://github.com/"
        sudo -u "$SUDO_USER" git config --global url."https://ghproxy.com/https://github.com/".insteadOf "https://github.com/"

        info "已配置 GitHub 镜像加速"
        info "  - mirror.ghproxy.com"
    fi
}

# 配置用户信息
configure_user_info() {
    if [ -z "$GIT_USER_NAME" ] && [ -z "$GIT_USER_EMAIL" ]; then
        info "跳过用户信息配置（未提供）"
        return
    fi

    # 为当前用户配置
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)

        if [ -n "$GIT_USER_NAME" ]; then
            sudo -u "$SUDO_USER" git config --global user.name "$GIT_USER_NAME"
            info "设置用户名: $GIT_USER_NAME"
        fi

        if [ -n "$GIT_USER_EMAIL" ]; then
            sudo -u "$SUDO_USER" git config --global user.email "$GIT_USER_EMAIL"
            info "设置邮箱: $GIT_USER_EMAIL"
        fi
    fi
}

# 生成 SSH 密钥
generate_ssh_key() {
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        SSH_KEY="$USER_HOME/.ssh/id_ed25519"

        if [ -f "$SSH_KEY" ]; then
            warn "SSH 密钥已存在: $SSH_KEY"
            read -p "是否生成新的 SSH 密钥? [y/N]: " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                return
            fi
        fi

        info "生成 SSH 密钥 (ED25519)..."
        sudo -u "$SUDO_USER" ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$SSH_KEY" -N ""

        info "SSH 密钥已生成"
        echo ""
        echo "公钥内容:"
        echo "----------------------------------------"
        cat "${SSH_KEY}.pub"
        echo "----------------------------------------"
        echo ""
        info "请将公钥添加到:"
        info "  GitHub: https://github.com/settings/keys"
        info "  Gitee: https://gitee.com/profile/sshkeys"
        info "  GitLab: https://gitlab.com/-/profile/keys"
    fi
}

# 验证安装
verify_installation() {
    info "验证 Git 安装..."

    if ! command -v git &> /dev/null; then
        error "Git 安装失败"
        exit 1
    fi

    # 显示版本
    git --version

    # 显示系统配置
    echo ""
    info "Git 系统配置:"
    git config --system --list

    # 显示用户配置
    if [ -n "$SUDO_USER" ]; then
        echo ""
        info "Git 用户配置:"
        sudo -u "$SUDO_USER" git config --global --list 2>/dev/null || echo "无用户配置"
    fi
}

# 显示常用命令
show_commands() {
    echo ""
    echo "============================================"
    success "Git 安装完成！"
    echo "============================================"
    echo ""
    echo "常用命令:"
    echo ""
    echo "基础操作:"
    echo "  git init                      # 初始化仓库"
    echo "  git clone <url>               # 克隆仓库"
    echo "  git status                    # 查看状态"
    echo "  git add <file>                # 添加文件"
    echo "  git commit -m \"message\"       # 提交更改"
    echo "  git push                      # 推送到远程"
    echo "  git pull                      # 拉取更新"
    echo ""
    echo "分支操作:"
    echo "  git branch                    # 查看分支"
    echo "  git checkout <branch>         # 切换分支"
    echo "  git checkout -b <new>         # 创建并切换分支"
    echo "  git merge <branch>            # 合并分支"
    echo "  git branch -d <branch>        # 删除分支"
    echo ""
    echo "查看历史:"
    echo "  git log                       # 查看提交历史"
    echo "  git log --oneline             # 简洁显示"
    echo "  git diff                      # 查看差异"
    echo "  git show                      # 查看提交详情"
    echo ""
    echo "远程操作:"
    echo "  git remote -v                 # 查看远程仓库"
    echo "  git remote add <name> <url>   # 添加远程仓库"
    echo "  git push -u origin <branch>   # 推送并设置上游"
    echo ""
    echo "用户配置:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your@email.com\""
    echo "  git config --list             # 查看所有配置"
    echo ""
}

# 交互式配置用户信息
interactive_user_config() {
    echo ""
    echo "============================================"
    echo "       配置 Git 用户信息"
    echo "============================================"
    echo ""
    echo "Git 提交时需要用户信息，请输入:"
    echo ""

    # 用户名
    while true; do
        read -p "请输入用户名: " input_name
        if [ -n "$input_name" ]; then
            GIT_USER_NAME="$input_name"
            break
        fi
        warn "用户名不能为空"
    done

    # 邮箱
    while true; do
        read -p "请输入邮箱: " input_email
        if [ -n "$input_email" ]; then
            GIT_USER_EMAIL="$input_email"
            break
        fi
        warn "邮箱不能为空"
    done

    # 是否生成 SSH 密钥
    echo ""
    read -p "是否生成 SSH 密钥? [Y/n]: " gen_ssh
    if [[ ! $gen_ssh =~ ^[Nn]$ ]]; then
        GENERATE_SSH="true"
    fi
}

# 交互式菜单
show_menu() {
    echo ""
    echo "============================================"
    echo "       Git 一键安装脚本"
    echo "============================================"
    echo ""
    echo "请选择安装方式:"
    echo "  1) 使用包管理器安装 (推荐，快速)"
    echo "  2) 从源码编译安装 (最新版本)"
    echo ""
    read -p "请输入选项 [1-2] (默认: 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            INSTALL_METHOD="package"
            ;;
        2)
            INSTALL_METHOD="source"
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac

    # 询问是否配置用户信息
    echo ""
    read -p "是否配置 Git 用户信息? [Y/n]: " config_user
    if [[ ! $config_user =~ ^[Nn]$ ]]; then
        interactive_user_config
    fi
}

# 主函数
main() {
    echo "============================================"
    echo "       Git 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    show_menu
    check_existing_git

    # 根据选择安装 Git
    case $INSTALL_METHOD in
        source)
            install_git_from_source
            ;;
        package)
            case $OS in
                ubuntu|debian)
                    install_git_debian
                    ;;
                centos|rhel|rocky|almalinux)
                    install_git_rhel
                    ;;
                *)
                    error "不支持的系统: $OS"
                    exit 1
                    ;;
            esac
            ;;
    esac

    configure_git
    configure_git_mirror
    configure_user_info

    if [ "$GENERATE_SSH" = "true" ]; then
        generate_ssh_key
    fi

    verify_installation
    show_commands
}

# 运行主函数
main "$@"

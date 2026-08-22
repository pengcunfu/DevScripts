#!/bin/bash
# ============================================
# 一键安装 Go 语言脚本
# 支持: Linux (x86_64/arm64/aarch64)
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 默认 Go 版本（留空自动获取最新版）
GO_VERSION=${GO_VERSION:-""}

# 安装目录
INSTALL_DIR=${INSTALL_DIR:-"/usr/local"}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 root 权限运行"
        info "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统架构
detect_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            GO_ARCH="amd64"
            ;;
        aarch64|arm64)
            GO_ARCH="arm64"
            ;;
        armv7l|armhf)
            GO_ARCH="armv6l"
            ;;
        i386|i686)
            GO_ARCH="386"
            ;;
        *)
            error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
    info "系统架构: $ARCH (Go: $GO_ARCH)"
}

# 获取 Go 最新版本
get_latest_version() {
    if [ -n "$GO_VERSION" ]; then
        info "使用指定版本: $GO_VERSION"
        VERSION="$GO_VERSION"
        return
    fi

    info "获取 Go 最新版本..."
    VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n 1)

    if [ -z "$VERSION" ]; then
        error "无法获取 Go 最新版本"
        exit 1
    fi

    # 去掉 'go' 前缀，只保留版本号
    VERSION_NUMBER=$(echo "$VERSION" | sed 's/^go//')
    info "最新版本: $VERSION"
}

# 检查是否已安装 Go
check_existing_go() {
    if command -v go &> /dev/null; then
        EXISTING_VERSION=$(go version 2>/dev/null || echo "unknown")
        warn "检测到已安装 Go: $EXISTING_VERSION"
        read -p "是否卸载旧版本并重新安装? [y/N]: " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            remove_existing_go
        else
            info "保留现有安装，退出脚本"
            exit 0
        fi
    fi
}

# 卸载现有 Go
remove_existing_go() {
    info "卸载现有 Go..."

    # 删除 Go 安装目录
    if [ -d "$INSTALL_DIR/go" ]; then
        rm -rf "$INSTALL_DIR/go"
        info "已删除 $INSTALL_DIR/go"
    fi

    # 删除环境变量配置
    rm -f /etc/profile.d/go.sh
    rm -f /etc/bashrc.d/go.sh

    info "旧版本已卸载"
}

# 安装 Go（使用国内镜像）
install_go() {
    get_latest_version
    detect_architecture

    # 构建下载 URL
    FILENAME="go${VERSION_NUMBER}.linux-${GO_ARCH}.tar.gz"
    DOWNLOAD_URL="https://go.dev/dl/${FILENAME}"

    # 国内镜像源（阿里云）
    MIRROR_URL="https://mirrors.aliyun.com/golang/${FILENAME}"

    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    info "准备下载 Go $VERSION_NUMBER for $GO_ARCH..."

    # 优先使用国内镜像
    info "尝试从阿里云镜像下载..."
    if curl -L -f --max-time 300 -o "$FILENAME" "$MIRROR_URL"; then
        info "下载成功 (阿里云镜像)"
    else
        warn "阿里云镜像下载失败，切换到官方源..."
        if curl -L -f --max-time 600 -o "$FILENAME" "$DOWNLOAD_URL"; then
            info "下载成功 (官方源)"
        else
            error "下载失败，请检查网络连接"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    fi

    # 验证文件
    if [ ! -f "$FILENAME" ]; then
        error "下载文件不存在"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    FILE_SIZE=$(du -h "$FILENAME" | cut -f1)
    info "文件大小: $FILE_SIZE"

    # 解压到安装目录
    info "解压 Go 到 $INSTALL_DIR..."
    tar -C "$INSTALL_DIR" -xzf "$FILENAME"

    # 清理临时文件
    rm -rf "$TMP_DIR"

    info "Go 安装完成"
}

# 配置环境变量
configure_go_env() {
    info "配置 Go 环境变量..."

    # 创建环境变量配置文件
    cat > /etc/profile.d/go.sh <<'EOF'
# Go 环境变量
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# 国内代理设置（可选，下载依赖更快）
# export GOPROXY=https://goproxy.cn,direct
# export GOSUMDB=off
EOF

    # 为所有用户添加到 bashrc
    for user_home in /root /home/*; do
        if [ -d "$user_home" ] && [ -f "$user_home/.bashrc" ]; then
            if ! grep -q "GOROOT" "$user_home/.bashrc" 2>/dev/null; then
                cat >> "$user_home/.bashrc" <<'EOF'

# Go 环境变量
export GOROOT=/usr/local/go
export PATH=$GOROOT/bin:$PATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
EOF
            fi
        fi
    done 2>/dev/null || true

    # 立即生效
    export GOROOT=$INSTALL_DIR/go
    export PATH=$GOROOT/bin:$PATH
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH

    info "环境变量配置完成"
}

# 配置 Go 国内代理
configure_go_proxy() {
    info "配置 Go 国内代理..."

    # 创建全局 Go 配置
    cat > /etc/profile.d/go-proxy.sh <<'EOF'
# Go 国内代理配置
export GOPROXY=https://goproxy.cn,https://goproxy.io,direct
export GOSUMDB=off
export GO111MODULE=on
EOF

    # 配置 go env
    if command -v go &> /dev/null; then
        go env -w GOPROXY=https://goproxy.cn,https://goproxy.io,direct
        go env -w GOSUMDB=off
        go env -w GO111MODULE=on
    fi

    info "Go 代理配置完成"
    info "GOPROXY: https://goproxy.cn,https://goproxy.io,direct"
}

# 验证安装
verify_installation() {
    info "验证 Go 安装..."

    # 重新加载环境变量
    source /etc/profile.d/go.sh 2>/dev/null || true

    if ! command -v go &> /dev/null; then
        export PATH=$INSTALL_DIR/go/bin:$PATH
    fi

    # 显示 Go 版本
    go version
    if [ $? -ne 0 ]; then
        error "Go 验证失败"
        exit 1
    fi

    # 显示 Go 环境
    echo ""
    info "Go 环境信息:"
    go env GOROOT GOPATH GO111MODULE GOPROXY

    # 测试编译
    info "测试 Go 编译..."
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    cat > hello.go <<'EOF'
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
EOF

    go run hello.go
    if [ $? -eq 0 ]; then
        info "Go 编译测试成功！"
    else
        warn "Go 编译测试失败"
    fi

    rm -rf "$TEST_DIR"
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "Go 语言安装完成！"
    echo "============================================"
    echo ""
    echo "版本信息:"
    go version
    echo ""
    echo "环境变量:"
    echo "  GOROOT: $INSTALL_DIR/go"
    echo "  GOPATH: \$HOME/go"
    echo ""
    echo "常用命令:"
    echo "  go version              # 查看 Go 版本"
    echo "  go env                 # 查看 Go 环境变量"
    echo "  go help                # 查看帮助"
    echo "  go run <file.go>       # 运行 Go 程序"
    echo "  go build <file.go>     # 编译 Go 程序"
    echo "  go mod init <name>     # 初始化模块"
    echo "  go get <package>       # 下载依赖包"
    echo ""
    echo "国内代理:"
    echo "  GOPROXY: https://goproxy.cn,https://goproxy.io,direct"
    echo ""
    echo "Hello World 示例:"
    cat <<'EXAMPLE'
cat > hello.go <<'END'
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
END

go run hello.go
EXAMPLE
    echo ""
    echo "请执行以下命令使环境变量生效:"
    echo "  source /etc/profile.d/go.sh"
    echo "  或重新登录系统"
    echo ""
}

# 交互式选择版本
select_version() {
    echo ""
    echo "请选择 Go 安装方式:"
    echo "  1) 安装最新稳定版 (推荐)"
    echo "  2) 安装指定版本"
    echo "  3) 查看可用版本列表"
    echo ""
    read -p "请输入选项 [1-3] (默认: 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            # 使用默认空值，自动获取最新版
            ;;
        2)
            read -p "请输入 Go 版本 (如: 1.21.5): " input_version
            if [ -n "$input_version" ]; then
                GO_VERSION="$input_version"
            fi
            ;;
        3)
            info "获取可用版本列表..."
            curl -s https://go.dev/dl/ | grep -oP 'go\d+\.\d+\.\d+' | sort -u | tail -20
            echo ""
            read -p "请输入要安装的版本 (如: 1.21.5): " input_version
            if [ -n "$input_version" ]; then
                GO_VERSION="$input_version"
            fi
            ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    echo "============================================"
    echo "        Go 语言一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    select_version
    check_existing_go
    install_go
    configure_go_env
    configure_go_proxy
    verify_installation
    show_info
}

# 运行主函数
main "$@"

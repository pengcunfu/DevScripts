#!/bin/bash
# ============================================
# 一键安装 Java (JDK) 脚本
# 支持: OpenJDK 8/11/17/21
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印信息函数
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 默认 Java 版本
JAVA_VERSION=${JAVA_VERSION:-"21"}

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

# 检查已安装的 Java
check_existing_java() {
    if command -v java &> /dev/null; then
        EXISTING_VERSION=$(java -version 2>&1 | head -n 1)
        warn "检测到已安装 Java: $EXISTING_VERSION"
        read -p "是否继续安装? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            info "退出安装"
            exit 0
        fi
    fi
}

# Ubuntu/Debian 安装 Java
install_java_debian() {
    info "开始安装 Java $JAVA_VERSION (Ubuntu/Debian)..."

    # 更新包索引
    apt-get update

    case $JAVA_VERSION in
        8)
            apt-get install -y openjdk-8-jdk
            ;;
        11)
            apt-get install -y openjdk-11-jdk
            ;;
        17)
            apt-get install -y openjdk-17-jdk
            ;;
        21)
            apt-get install -y openjdk-21-jdk
            ;;
        *)
            error "不支持的 Java 版本: $JAVA_VERSION"
            error "支持的版本: 8, 11, 17, 21"
            exit 1
            ;;
    esac

    info "Java 安装完成"
}

# CentOS/RHEL/Rocky/AlmaLinux 安装 Java
install_java_rhel() {
    info "开始安装 Java $JAVA_VERSION (CentOS/RHEL/Rocky/AlmaLinux)..."

    case $JAVA_VERSION in
        8)
            yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
            ;;
        11)
            yum install -y java-11-openjdk java-11-openjdk-devel
            ;;
        17)
            yum install -y java-17-openjdk java-17-openjdk-devel
            ;;
        21)
            yum install -y java-21-openjdk java-21-openjdk-devel
            ;;
        *)
            error "不支持的 Java 版本: $JAVA_VERSION"
            error "支持的版本: 8, 11, 17, 21"
            exit 1
            ;;
    esac

    info "Java 安装完成"
}

# 配置环境变量
configure_java_env() {
    info "配置 Java 环境变量..."

    # 查找 JAVA_HOME
    if [ -d "/usr/lib/jvm/java-$JAVA_VERSION-openjdk" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/java-$JAVA_VERSION-openjdk"
    elif [ -d "/usr/lib/jvm/java-1.$JAVA_VERSION.0-openjdk" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/java-1.$JAVA_VERSION.0-openjdk"
    elif [ -d "/usr/lib/jvm/default-java" ]; then
        JAVA_HOME_PATH="/usr/lib/jvm/default-java"
    else
        # 自动查找
        JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))
    fi

    info "JAVA_HOME: $JAVA_HOME_PATH"

    # 创建环境变量配置
    cat > /etc/profile.d/java.sh <<EOF
# Java 环境变量
export JAVA_HOME=$JAVA_HOME_PATH
export JRE_HOME=\$JAVA_HOME/jre
export CLASSPATH=\$JAVA_HOME/lib:\$JRE_HOME/lib:\$CLASSPATH
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

    # 为所有用户添加到 bashrc
    for user_home in /root /home/*; do
        if [ -d "$user_home" ] && [ -f "$user_home/.bashrc" ]; then
            if ! grep -q "JAVA_HOME" "$user_home/.bashrc" 2>/dev/null; then
                cat >> "$user_home/.bashrc" <<EOF

# Java 环境变量
export JAVA_HOME=$JAVA_HOME_PATH
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
            fi
        fi
    done 2>/dev/null || true

    info "环境变量配置完成"
}

# 验证安装
verify_installation() {
    info "验证 Java 安装..."

    if command -v java &> /dev/null; then
        java -version
        echo ""
        javac -version
        echo ""
        info "JAVA_HOME: $JAVA_HOME_PATH"
    else
        error "Java 验证失败"
        exit 1
    fi
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "Java 安装完成！"
    echo "============================================"
    echo ""
    echo "版本信息:"
    java -version 2>&1 | head -n 1
    echo ""
    echo "环境变量:"
    echo "  JAVA_HOME: $JAVA_HOME_PATH"
    echo ""
    echo "常用命令:"
    echo "  java -version              # 查看 Java 版本"
    echo "  javac -version             # 查看 Java 编译器版本"
    echo "  java -jar app.jar          # 运行 JAR 包"
    echo "  javac HelloWorld.java      # 编译 Java 文件"
    echo ""
    echo "请执行以下命令使环境变量生效:"
    echo "  source /etc/profile.d/java.sh"
    echo "  或重新登录系统"
    echo ""
}

# 交互式选择版本
select_version() {
    echo ""
    echo "请选择 Java 版本:"
    echo "  1) Java 8  (LTS - 长期支持版)"
    echo "  2) Java 11 (LTS - 长期支持版)"
    echo "  3) Java 17 (LTS - 长期支持版)"
    echo "  4) Java 21 (LTS - 最新长期支持版，推荐)"
    echo ""
    read -p "请输入选项 [1-4] (默认: 4): " choice
    choice=${choice:-4}

    case $choice in
        1) JAVA_VERSION="8" ;;
        2) JAVA_VERSION="11" ;;
        3) JAVA_VERSION="17" ;;
        4) JAVA_VERSION="21" ;;
        *)
            error "无效选项"
            exit 1
            ;;
    esac

    info "选择版本: Java $JAVA_VERSION"
}

# 主函数
main() {
    echo "============================================"
    echo "       Java (JDK) 一键安装脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    select_version
    check_existing_java

    case $OS in
        ubuntu|debian)
            install_java_debian
            ;;
        centos|rhel|rocky|almalinux)
            install_java_rhel
            ;;
        *)
            error "不支持的系统: $OS"
            exit 1
            ;;
    esac

    configure_java_env
    verify_installation
    show_info
}

# 运行主函数
main "$@"

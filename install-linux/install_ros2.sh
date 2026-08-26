#!/bin/bash
# ============================================
# 一键安装 ROS2 脚本
# 支持: Ubuntu 20.04/22.04/24.04
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

# ROS2 发行版配置
declare -A ROS2_DISTROS=(
    ["24.04"]="jazzy"
    ["22.04"]="humble"
    ["20.04"]="foxy"
)

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

# 检查系统支持
check_supported() {
    if [ "$OS" != "ubuntu" ]; then
        error "ROS2 仅支持 Ubuntu 系统"
        exit 1
    fi

    if [ -z "${ROS2_DISTROS[$OS_VERSION]}" ]; then
        error "不支持的 Ubuntu 版本: $OS_VERSION"
        error "支持的版本: 20.04, 22.04, 24.04"
        exit 1
    fi

    ROS2_DISTRO=${ROS2_DISTROS[$OS_VERSION]}
    info "将安装 ROS2 $ROS2_DISTRO"
}

# 添加 ROS2 软件源
add_ros2_repository() {
    info "添加 ROS2 软件源..."

    # 安装依赖
    apt-get update
    apt-get install -y \
        software-properties-common \
        curl \
        gnupg \
        lsb-release

    # 添加 GPG 密钥
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

    # 添加软件源
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://mirrors.aliyun.com/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | \
        tee /etc/apt/sources.list.d/ros2.list > /dev/null

    # 配置阿里云镜像（如果官方源不可用）
    if ! apt-get update 2>/dev/null; then
        warn "阿里云镜像不可用，切换到官方源"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | \
            tee /etc/apt/sources.list.d/ros2.list > /dev/null
        apt-get update
    fi

    info "ROS2 软件源添加完成"
}

# 安装 ROS2
install_ros2() {
    info "开始安装 ROS2 $ROS2_DISTRO..."

    # 更新包索引
    apt-get update

    # 升级系统
    apt-get upgrade -y

    # 安装 ROS2 桌面版（包含 ROS、RViz、演示、教程）
    info "安装 ROS2 桌面版..."
    apt-get install -y ros-${ROS2_DISTRO}-desktop

    # 安装开发工具
    info "安装 ROS2 开发工具..."
    apt-get install -y \
        ros-dev-tools \
        python3-rosdep \
        python3-colcon-common-extensions

    info "ROS2 安装完成"
}

# 初始化 rosdep
initialize_rosdep() {
    info "初始化 rosdep..."

    # 安装 rosdep
    apt-get install -y python3-rosdep

    # 初始化 rosdep
    if [ ! -d "/etc/ros/rosdep" ]; then
        rosdep init || true
    fi

    # 更新 rosdep
    info "更新 rosdep 数据 (可能需要几分钟)..."
    su - "$SUDO_USER" -c "rosdep update" || warn "rosdep update 失败，请稍后手动执行"

    info "rosdep 初始化完成"
}

# 配置环境变量
configure_environment() {
    info "配置 ROS2 环境变量..."

    # 为所有用户配置
    cat > /etc/profile.d/ros2.sh <<EOF
# ROS2 环境变量
source /opt/ros/${ROS2_DISTRO}/setup.bash
EOF

    # 为当前用户配置
    if [ -n "$SUDO_USER" ]; then
        USER_HOME=$(eval echo ~$SUDO_USER)
        BASHRC="$USER_HOME/.bashrc"

        if ! grep -q "ros/${ROS2_DISTRO}/setup.bash" "$BASHRC" 2>/dev/null; then
            cat >> "$BASHRC" <<EOF

# ROS2 环境变量
source /opt/ros/${ROS2_DISTRO}/setup.bash

# ROS2 工作空间 (可选)
# source ~/ros2_ws/install/setup.bash
EOF
        fi
    fi

    # 立即生效
    source /opt/ros/${ROS2_DISTRO}/setup.bash

    info "环境变量配置完成"
}

# 安装 colcon cd (可选工具)
install_colcon_cd() {
    info "安装 colcon_cd..."

    if [ -n "$SUDO_USER" ]; then
        su - "$SUDO_USER" -c "mkdir -p ~/ros2_ws/src"
        cd ~/ros2_ws

        # 安装 colcon_cd
        su - "$SUDO_USER" -c "pip install colcon-common-extensions"

        info "colcon_cd 安装完成"
    fi
}

# 安装 ROS2 示例和教程
install_examples() {
    info "安装 ROS2 示例和教程..."

    # 安装示例
    apt-get install -y \
        ros-${ROS2_DISTRO}-demo-nodes-cpp \
        ros-${ROS2_DISTRO}-demo-nodes-python \
        ros-${ROS2_DISTRO}-examples-rclpy \
        ros-${ROS2_DISTRO}-examples-rclcpp

    # 安装教程
    apt-get install -y \
        ros-${ROS2_DISTRO}-launch-xml \
        ros-${ROS2_DISTRO}-launch-yaml

    info "示例和教程安装完成"
}

# 验证安装
verify_installation() {
    info "验证 ROS2 安装..."

    # 加载环境变量
    source /opt/ros/${ROS2_DISTRO}/setup.bash

    # 检查 ROS2 版本
    if command -v ros2 &> /dev/null; then
        echo ""
        info "ROS2 命令行工具:"
        ros2 --version
    fi

    # 检查可用包
    echo ""
    info "已安装的 ROS2 包数量:"
    if command -v ros2 &> /dev/null; then
        ros2 pkg list | wc -l
    fi
}

# 运行测试节点
run_test() {
    echo ""
    echo "============================================"
    info "运行测试节点"
    echo "============================================"
    echo ""
    info "准备运行 turtlesim 演示..."
    echo ""
    warn "请在两个终端窗口中分别执行以下命令:"
    echo ""
    echo "终端 1 (启动 turtlesim):"
    echo "  source /opt/ros/${ROS2_DISTRO}/setup.bash"
    echo "  ros2 run turtlesim turtlesim_node"
    echo ""
    echo "终端 2 (控制小乌龟):"
    echo "  source /opt/ros/${ROS2_DISTRO}/setup.bash"
    echo "  ros2 run turtlesim turtle_teleop_key"
    echo ""
}

# 显示使用说明
show_info() {
    echo ""
    echo "============================================"
    info "ROS2 安装完成！"
    echo "============================================"
    echo ""
    echo "安装信息:"
    echo "  ROS2 发行版: $ROS2_DISTRO"
    echo "  安装路径: /opt/ros/$ROS2_DISTRO"
    echo ""
    echo "环境配置:"
    echo "  全局配置: /etc/profile.d/ros2.sh"
    echo "  用户配置: ~/.bashrc"
    echo ""
    echo "常用命令:"
    echo "  ros2 --version               # 查看 ROS2 版本"
    echo "  ros2 pkg list                # 列出所有包"
    echo "  ros2 node list               # 列出所有节点"
    echo "  ros2 topic list              # 列出所有话题"
    echo "  ros2 topic echo <topic>      # 查看话题内容"
    echo "  ros2 run <package> <node>    # 运行节点"
    echo "  ros2 launch <package> <file> # 启动文件"
    echo ""
    echo "工作空间:"
    echo "  mkdir -p ~/ros2_ws/src       # 创建工作空间"
    echo "  cd ~/ros2_ws"
    echo "  colcon build                 # 编译工作空间"
    echo "  source install/setup.bash    # 加载工作空间"
    echo ""
    echo "演示示例:"
    echo "  ros2 run turtlesim turtlesim_node        # 启动小乌龟"
    echo "  ros2 run turtlesim turtle_teleop_key     # 控制小乌龟"
    echo "  ros2 launch turtlesim turtlesim_rviz_launch.py  # RViz 演示"
    echo ""
    echo "请执行以下命令使环境变量生效:"
    echo "  source ~/.bashrc"
    echo "  或重新登录系统"
    echo ""
    echo "文档资源:"
    echo "  官方文档: https://docs.ros.org/"
    echo "  中文教程: https://fishros.com/"
    echo ""
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择安装选项:"
    echo "  1) 完整安装 (ROS2 桌面版 + 开发工具 + 示例)"
    echo "  2) 最小安装 (仅 ROS2 核心功能)"
    echo "  3) 自定义安装"
    echo ""
    read -p "请输入选项 [1-3] (默认: 1): " choice
    choice=${choice:-1}

    case $choice in
        1)
            INSTALL_TYPE="full"
            ;;
        2)
            INSTALL_TYPE="minimal"
            ;;
        3)
            INSTALL_TYPE="custom"
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
    echo "       ROS2 一键安装脚本"
    echo "============================================"
    echo ""
    warn "注意: ROS2 安装需要较长时间和网络连接"
    echo ""

    check_root
    detect_os
    check_supported
    show_menu

    # 确认安装
    echo ""
    info "安装摘要:"
    info "  系统: Ubuntu $OS_VERSION"
    info "  ROS2 版本: $ROS2_DISTRO"
    info "  安装类型: $INSTALL_TYPE"
    echo ""
    read -p "确认安装? [Y/n]: " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        info "取消安装"
        exit 0
    fi

    # 开始安装
    add_ros2_repository

    case $INSTALL_TYPE in
        full)
            install_ros2
            install_examples
            ;;
        minimal)
            apt-get update
            apt-get install -y ros-${ROS2_DISTRO}-ros-base
            ;;
        custom)
            echo ""
            info "可用包:"
            echo "  ros-${ROS2_DISTRO}-ros-base          # 最小安装"
            echo "  ros-${ROS2_DISTRO}-desktop          # 桌面版"
            echo "  ros-${ROS2_DISTRO}-desktop-misc     # 桌面版+更多工具"
            echo ""
            read -p "请输入要安装的包名: " custom_packages
            apt-get update
            apt-get install -y $custom_packages
            ;;
    esac

    initialize_rosdep
    configure_environment
    verify_installation
    run_test
    show_info
}

# 运行主函数
main "$@"

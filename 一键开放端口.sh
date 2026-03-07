#!/bin/bash
# ============================================
# 一键开放端口脚本
# 支持: firewalld / ufw / iptables
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

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要 root 权限运行"
        info "请使用: sudo $0"
        exit 1
    fi
}

# 检测防火墙类型
detect_firewall() {
    FIREWALL_TYPE=""

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALL_TYPE="firewalld"
        info "检测到防火墙: firewalld (运行中)"
    elif command -v ufw &> /dev/null; then
        FIREWALL_TYPE="ufw"
        info "检测到防火墙: ufw"
    elif command -v iptables &> /dev/null; then
        FIREWALL_TYPE="iptables"
        info "检测到防火墙: iptables"
    else
        warn "未检测到常见防火墙工具"
        info "将尝试安装 firewalld..."
        install_firewall
    fi
}

# 安装防火墙
install_firewall() {
    # 检测系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi

    case $OS in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y firewalld
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y firewalld
            ;;
        *)
            error "不支持的系统，无法自动安装防火墙"
            exit 1
            ;;
    esac

    # 启动防火墙
    systemctl enable firewalld
    systemctl start firewalld

    FIREWALL_TYPE="firewalld"
    info "firewalld 已安装并启动"
}

# 使用 firewalld 开放端口
open_port_firewalld() {
    local port=$1
    local protocol=$2
    local description=$3

    info "使用 firewalld 开放端口 ${port}/${protocol}..."

    # 添加端口
    firewall-cmd --permanent --add-port=${port}/${protocol} 2>/dev/null

    if [ $? -eq 0 ]; then
        success "端口 ${port}/${protocol} 已添加"
    else
        error "添加端口 ${port}/${protocol} 失败"
        return 1
    fi
}

# 使用 ufw 开放端口
open_port_ufw() {
    local port=$1
    local protocol=$2
    local description=$3

    info "使用 ufw 开放端口 ${port}/${protocol}..."

    # 添加端口
    ufw allow ${port}/${protocol} 2>/dev/null

    if [ $? -eq 0 ]; then
        success "端口 ${port}/${protocol} 已添加"
    else
        error "添加端口 ${port}/${protocol} 失败"
        return 1
    fi
}

# 使用 iptables 开放端口
open_port_iptables() {
    local port=$1
    local protocol=$2
    local description=$3

    info "使用 iptables 开放端口 ${port}/${protocol}..."

    # 添加规则
    iptables -I INPUT -p ${protocol} --dport ${port} -j ACCEPT

    # 保存规则
    if command -v iptables-save &> /dev/null; then
        # 尝试使用不同的保存方式
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
            iptables-save > /etc/iptables.rules 2>/dev/null || \
            info "请安装 iptables-persistent 以永久保存规则"
        elif [ -f /etc/redhat-release ]; then
            # RHEL/CentOS
            service iptables save 2>/dev/null || \
            iptables-save > /etc/sysconfig/iptables 2>/dev/null || \
            info "请手动保存 iptables 规则"
        fi
    fi

    success "端口 ${port}/${protocol} 已添加"
}

# 开放端口（主函数）
open_port() {
    local port=$1
    local protocol=$2
    local description=$3

    case $FIREWALL_TYPE in
        firewalld)
            open_port_firewalld "$port" "$protocol" "$description"
            ;;
        ufw)
            open_port_ufw "$port" "$protocol" "$description"
            ;;
        iptables)
            open_port_iptables "$port" "$protocol" "$description"
            ;;
        *)
            error "未知的防火墙类型"
            return 1
            ;;
    esac
}

# 重载防火墙
reload_firewall() {
    info "重载防火墙规则..."

    case $FIREWALL_TYPE in
        firewalld)
            firewall-cmd --reload
            info "firewalld 规则已重载"
            ;;
        ufw)
            ufw reload 2>/dev/null || info "ufw 无需重载"
            ;;
        iptables)
            info "iptables 规则已生效"
            ;;
    esac
}

# 显示已开放的端口
show_opened_ports() {
    echo ""
    echo "============================================"
    info "当前已开放的端口"
    echo "============================================"
    echo ""

    case $FIREWALL_TYPE in
        firewalld)
            info "firewalld 活动规则:"
            firewall-cmd --list-ports
            echo ""
            info "所有防火墙规则:"
            firewall-cmd --list-all
            ;;
        ufw)
            info "ufw 状态:"
            ufw status numbered
            ;;
        iptables)
            info "iptables INPUT 链规则:"
            iptables -L INPUT -n --line-numbers | grep -E "dpt:|Chain INPUT"
            ;;
    esac
    echo ""
}

# 常用端口快捷方式
show_common_ports() {
    echo ""
    echo "============================================"
    info "常用服务端口参考"
    echo "============================================"
    echo ""
    echo "服务名称            端口      协议"
    echo "--------------------------------------------"
    echo "SSH                22        tcp"
    echo "HTTP               80        tcp"
    echo "HTTPS              443       tcp"
    echo "FTP                21        tcp"
    echo "MySQL              3306      tcp"
    echo "PostgreSQL         5432      tcp"
    echo "Redis              6379      tcp"
    echo "MongoDB            27017     tcp"
    echo "Docker Registry    5000      tcp"
    echo "RabbitMQ           5672      tcp"
    echo "RabbitMQ Mgmt      15672     tcp"
    echo "Kafka              9092      tcp"
    echo "ZooKeeper          2181      tcp"
    echo "Elasticsearch      9200      tcp"
    echo "Kibana             5601      tcp"
    echo "Nginx              80/443    tcp"
    echo "Tomcat             8080      tcp"
    echo "Jenkins            8080      tcp"
    echo "GitLab             80/443    tcp"
    echo ""
}

# 交互式添加端口
interactive_add_port() {
    echo ""
    echo "============================================"
    echo "       添加端口规则"
    echo "============================================"
    echo ""

    # 输入端口号
    while true; do
        read -p "请输入端口号 (1-65535): " port

        # 验证端口号
        if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
            break
        elif [[ "$port" =~ ^[0-9]+-[0-9]+$ ]]; then
            # 端口范围
            break
        else
            error "无效的端口号，请输入 1-65535 之间的数字或端口范围 (如: 8080-8090)"
        fi
    done

    # 选择协议
    echo ""
    echo "请选择协议:"
    echo "  1) TCP"
    echo "  2) UDP"
    echo "  3) TCP + UDP"
    echo ""
    read -p "请输入选项 [1-3] (默认: 1): " protocol_choice
    protocol_choice=${protocol_choice:-1}

    case $protocol_choice in
        1)
            protocols=("tcp")
            ;;
        2)
            protocols=("udp")
            ;;
        3)
            protocols=("tcp" "udp")
            ;;
        *)
            error "无效选项"
            return 1
            ;;
    esac

    # 输入描述（可选）
    echo ""
    read -p "请输入描述 (可选，直接回车跳过): " description

    # 开放端口
    for protocol in "${protocols[@]}"; do
        open_port "$port" "$protocol" "$description"
    done

    # 重载防火墙
    reload_firewall
}

# 批量添加端口
batch_add_ports() {
    echo ""
    echo "============================================"
    echo "       批量添加端口"
    echo "============================================"
    echo ""
    echo "请输入端口号，多个端口用空格分隔 (支持端口范围)"
    echo "示例: 80 443 8080-8090 3306"
    echo ""
    read -p "端口列表: " ports_input

    if [ -z "$ports_input" ]; then
        error "端口列表不能为空"
        return 1
    fi

    # 选择协议
    echo ""
    read -p "协议 [tcp/udp/both] (默认: tcp): " protocol
    protocol=${protocol:-"tcp"}

    case $protocol in
        tcp)
            protocols=("tcp")
            ;;
        udp)
            protocols=("udp")
            ;;
        both|"")
            protocols=("tcp" "udp")
            ;;
        *)
            error "无效的协议"
            return 1
            ;;
    esac

    # 解析并添加端口
    for port_item in $ports_input; do
        for proto in "${protocols[@]}"; do
            open_port "$port_item" "$proto" ""
        done
    done

    # 重载防火墙
    reload_firewall
}

# 删除端口规则
delete_port() {
    echo ""
    echo "============================================"
    echo "       删除端口规则"
    echo "============================================"
    echo ""

    # 输入端口号
    read -p "请输入要删除的端口号: " port

    if [ -z "$port" ]; then
        error "端口号不能为空"
        return 1
    fi

    # 选择协议
    echo ""
    read -p "协议 [tcp/udp] (默认: tcp): " protocol
    protocol=${protocol:-"tcp"}

    info "删除端口 ${port}/${protocol}..."

    case $FIREWALL_TYPE in
        firewalld)
            firewall-cmd --permanent --remove-port=${port}/${protocol}
            firewall-cmd --reload
            success "端口 ${port}/${protocol} 已删除"
            ;;
        ufw)
            ufw delete allow ${port}/${protocol}
            success "端口 ${port}/${protocol} 已删除"
            ;;
        iptables)
            iptables -D INPUT -p ${protocol} --dport ${port} -j ACCEPT 2>/dev/null
            success "端口 ${port}/${protocol} 已删除 (注意: 重启后可能恢复)"
            ;;
    esac
}

# 显示使用说明
show_usage() {
    echo ""
    echo "============================================"
    info "端口已配置完成！"
    echo "============================================"
    echo ""
    echo "防火墙管理命令:"
    case $FIREWALL_TYPE in
        firewalld)
            echo "  firewall-cmd --list-all             # 查看所有规则"
            echo "  firewall-cmd --list-ports           # 查看开放端口"
            echo "  firewall-cmd --reload               # 重载规则"
            echo "  firewall-cmd --state                # 查看状态"
            ;;
        ufw)
            echo "  ufw status                          # 查看状态"
            echo "  ufw status numbered                 # 查看规则列表"
            echo "  ufw reload                          # 重载规则"
            echo "  ufw enable/disable                  # 启用/禁用防火墙"
            ;;
        iptables)
            echo "  iptables -L -n                      # 查看规则"
            echo "  iptables-save > /etc/iptables.rules # 保存规则"
            echo "  service iptables save               # RHEL/CentOS 保存"
            ;;
    esac
    echo ""
}

# 主菜单
show_menu() {
    echo ""
    echo "============================================"
    echo "       防火墙端口管理工具"
    echo "============================================"
    echo ""
    echo "当前防火墙: ${GREEN}${FIREWALL_TYPE}${NC}"
    echo ""
    echo "  1) 开放单个端口"
    echo "  2) 批量开放端口"
    echo "  3) 删除端口规则"
    echo "  4) 查看已开放端口"
    echo "  5) 查看常用服务端口"
    echo "  6) 测试端口连通性"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 [0-6]: " choice

    case $choice in
        1)
            interactive_add_port
            show_opened_ports
            show_usage
            ;;
        2)
            batch_add_ports
            show_opened_ports
            show_usage
            ;;
        3)
            delete_port
            show_opened_ports
            ;;
        4)
            show_opened_ports
            ;;
        5)
            show_common_ports
            ;;
        6)
            test_port_connectivity
            ;;
        0)
            info "退出脚本"
            exit 0
            ;;
        *)
            error "无效选项"
            ;;
    esac
}

# 测试端口连通性
test_port_connectivity() {
    echo ""
    echo "============================================"
    echo "       测试端口连通性"
    echo "============================================"
    echo ""

    read -p "请输入目标 IP 地址: " target_ip
    read -p "请输入目标端口号: " target_port

    if [ -z "$target_ip" ] || [ -z "$target_port" ]; then
        error "IP 地址和端口号不能为空"
        return 1
    fi

    info "测试连接 $target_ip:$target_port ..."

    if command -v nc &> /dev/null; then
        if nc -zv -w 3 "$target_ip" "$target_port" 2>&1 | grep -q "succeeded"; then
            success "端口 $target_port 开放且可连接"
        else
            warn "端口 $target_port 可能关闭或无法连接"
        fi
    elif command -v telnet &> /dev/null; then
        timeout 3 telnet "$target_ip" "$target_port" 2>&1 | grep -q "Connected" && \
            success "端口 $target_port 开放且可连接" || \
            warn "端口 $target_port 可能关闭或无法连接"
    else
        warn "未找到 nc 或 telnet 工具，无法测试"
        info "安装: apt-get install netcat / yum install nc"
    fi
}

# 主函数
main() {
    echo "============================================"
    echo "       一键开放端口脚本"
    echo "============================================"
    echo ""

    check_root
    detect_firewall

    # 如果通过命令行参数指定端口
    if [ -n "$1" ]; then
        PORT=$1
        PROTOCOL=${2:-tcp}
        info "开放端口: $PORT/$PROTOCOL"
        open_port "$PORT" "$PROTOCOL" "命令行指定"
        reload_firewall
        show_opened_ports
        show_usage
    else
        # 交互式菜单
        while true; do
            show_menu
        done
    fi
}

# 运行主函数
main "$@"

#!/bin/bash
# ============================================
# Docker 镜像源配置（批量）
#
# Docker 的 registry-mirrors 是数组，会按顺序依次尝试，
# 前一个不可用会自动切到下一个，因此可以一次配置多个。
#
# 本脚本不预设"哪个镜像站可用"，而是在运行时逐个探测，
# 只把实测可用的写入配置 —— 公共加速器失效频繁，写死列表不可靠。
# ============================================

set -e

# 颜色定义（本脚本常被单独拷贝到目标机执行，故自带打印函数，不依赖 common.sh）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }

# 需要 root 权限
if [ "$EUID" -ne 0 ]; then
    error "Docker 镜像源配置需要 root 权限，请使用 sudo 运行"
    error "用法: sudo ./$(basename "$0")"
    exit 1
fi

DOCKER_CONFIG_DIR="/etc/docker"
DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/daemon.json"

# 候选镜像：均为无需注册的国内公共 Docker Hub 加速器
# 格式为 "地址|提供方备注"
#
# 数组顺序即 Docker 的尝试顺序（registry-mirrors 按序回退），
# 故按稳定性/速度优先级排列，高校源与大厂源在前。
# 列表仅作为探测输入，实测不通的会被自动剔除，不会写进配置。
CANDIDATES=(
    # —— 主要候选：来源为使用者提供的清单，按稳定性/速度优先级排序 ——
    "https://docker.mirrors.ustc.edu.cn|中科大高校源，稳定首选"
    "https://docker.nju.edu.cn|南京大学高校源"
    "https://docker.m.daocloud.io|DaoCloud 老牌社区源"
    "https://mirror.baidubce.com|百度云国内大厂"
    "https://docker.xuanyuan.me|轩辕镜像，免费公共 CDN 腾讯云"
    "https://docker.1ms.run|毫秒镜像，速度较好"
    "https://docker.kejilion.pro|社区代理，社区维护"
    "https://docker.1panel.live|1Panel 项目面板配套镜像"
    "https://dockerproxy.com|DockerProxy 通用代理"
    "https://docker.mirrors.sjtug.sjtu.edu.cn|上海交大高校源"

    # —— 备选：无实测依据，仅作探测输入，不通的会被自动剔除 ——
    # 注意：镜像站可投毒（Docker 信任镜像返回的 manifest），
    # 优先信任高校源与大厂源，来路不明的即使探测通过也建议谨慎使用
    "https://hub.rat.dev|Rat's Hub 社区代理"
    "https://docker.1panel.top|1Panel 备选节点"
    "https://docker.1panel.pro|1Panel 备选节点"
    "https://docker.hlmirror.com|社区代理"
    "https://docker.rainbond.cc|Rainbond 社区代理"
    "https://docker.aityp.com|社区代理"
    "https://docker.udayun.com|优达云"
    "https://hub-mirror.c.163.com|网易，据信已停服，仅作探测"
)

# 探测单个镜像：/v2/ 返回 200 或 401 均视为可用（401 是正常的未认证响应）
probe_mirror() {
    local url="$1"
    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' \
        --connect-timeout 4 --max-time 8 \
        "$url/v2/" 2>/dev/null || echo "000")

    if [ "$code" = "200" ] || [ "$code" = "401" ]; then
        return 0
    fi
    return 1
}

MIRRORS=()

probe_all() {
    local tmpdir
    tmpdir=$(mktemp -d)

    info "开始并行探测 ${#CANDIDATES[@]} 个候选镜像（每个最多 4 秒超时）..."
    echo ""

    # 并行探测，命中结果写入 $tmpdir/<下标>，下标即原始顺序
    local i entry url
    for i in "${!CANDIDATES[@]}"; do
        entry="${CANDIDATES[$i]}"
        url="${entry%%|*}"
        (
            if probe_mirror "$url"; then
                echo "$url" > "$tmpdir/$i"
            fi
        ) &
    done
    wait

    # 按下标回放，保持候选列表的优先级顺序
    local alive=() desc
    for i in "${!CANDIDATES[@]}"; do
        entry="${CANDIDATES[$i]}"
        url="${entry%%|*}"
        desc="${entry#*|}"

        printf '  %-44s ' "$url"
        if [ -f "$tmpdir/$i" ]; then
            printf '%s' "${GREEN}可用${NC}"
            alive+=("$url")
        else
            printf '%s' "${RED}不通${NC}"
        fi
        echo "   $desc"
    done

    rm -rf "$tmpdir"
    echo ""

    if [ ${#alive[@]} -eq 0 ]; then
        error "所有候选镜像均不可用"
        error "请改用 [2] 手动输入，或检查本机网络/DNS"
        exit 1
    fi

    MIRRORS=("${alive[@]}")
    info "探测完成，${#MIRRORS[@]}/${#CANDIDATES[@]} 个可用"
}

read_manual() {
    echo ""
    read -p "  请输入镜像地址（多个用空格分隔）: " -a MIRRORS

    if [ ${#MIRRORS[@]} -eq 0 ]; then
        error "镜像地址不能为空"
        exit 1
    fi

    local url
    for url in "${MIRRORS[@]}"; do
        case "$url" in
            http://*|https://*) ;;
            *)
                error "镜像地址必须以 http:// 或 https:// 开头: $url"
                exit 1
                ;;
        esac
    done
}

select_method() {
    echo ""
    echo "  Docker 镜像源配置（批量）"
    echo "  ========================="
    echo ""
    echo "  [1] 自动探测并配置国内公共镜像（推荐，无需登录）"
    echo "  [2] 手动输入镜像地址（多个用空格分隔）"
    echo "  [0] 退出"
    echo ""
    read -p "  选择 [0-2]: " choice

    case $choice in
        1) probe_all ;;
        2) read_manual ;;
        0) exit 0 ;;
        *) error "无效选项"; exit 1 ;;
    esac
}

# 合并写入 daemon.json：保留已有配置（日志轮转、存储驱动等），只替换 registry-mirrors
write_daemon_json() {
    mkdir -p "$DOCKER_CONFIG_DIR"

    if [ -f "$DOCKER_CONFIG_FILE" ]; then
        cp "$DOCKER_CONFIG_FILE" "$DOCKER_CONFIG_FILE.bak"
        info "已备份原配置到 $DOCKER_CONFIG_FILE.bak"
    fi

    if command -v python3 > /dev/null 2>&1; then
        python3 - "$DOCKER_CONFIG_FILE" "${MIRRORS[@]}" <<'PY'
import json
import sys

path, *mirrors = sys.argv[1:]

try:
    with open(path, encoding="utf-8") as f:
        config = json.load(f)
except FileNotFoundError:
    config = {}
except json.JSONDecodeError:
    print("[WARN] 原 daemon.json 不是合法 JSON，将整体重写", file=sys.stderr)
    config = {}

config["registry-mirrors"] = mirrors

with open(path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
    else
        # 没有 python3 时退化为整体覆盖，此时日志轮转等配置会丢失
        warn "未找到 python3，将整体覆盖 daemon.json（原有日志轮转等配置会丢失）"

        local mirror_json=""
        local url
        for url in "${MIRRORS[@]}"; do
            [ -n "$mirror_json" ] && mirror_json="$mirror_json,"
            mirror_json="$mirror_json
    \"$url\""
        done

        cat > "$DOCKER_CONFIG_FILE" << EOF
{
  "registry-mirrors": [$mirror_json
  ]
}
EOF
    fi
}

# Main
select_method
write_daemon_json

info "当前 daemon.json:"
cat "$DOCKER_CONFIG_FILE"
echo ""

info "重启 Docker 服务..."
systemctl restart docker

if systemctl is-active --quiet docker; then
    success "Docker 镜像源配置完成，共 ${#MIRRORS[@]} 个镜像"
    info "验证: docker pull hello-world"
else
    error "Docker 服务重启失败，请检查配置: $DOCKER_CONFIG_FILE"
    exit 1
fi

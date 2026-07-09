#!/bin/bash

# ==========================================
# Sing-box 6-in-1
# ==========================================

# --- 扩展视觉与色彩引擎 ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; PURPLE='\033[1;35m'; CYAN='\033[1;36m'
BG_RED='\033[41;37;1m'; BG_GREEN='\033[42;37;1m'; BG_BLUE='\033[44;37;1m'; BG_PURPLE='\033[45;37;1m'
BOLD='\033[1m'; NC='\033[0m'

msg_info() { echo -e " ${BG_BLUE} INFO ${NC} ${CYAN}$1${NC}"; }
msg_success() { echo -e " ${BG_GREEN}  OK  ${NC} ${GREEN}$1${NC}"; }
msg_warn() { echo -e " ${YELLOW}${BOLD}[⚠️ WARN]${NC} $1"; }
msg_error() { echo -e " ${BG_RED} ERROR ${NC} ${RED}$1${NC}"; }
reading() { echo -ne "\n ${CYAN}➤ ${BOLD}$1${NC} ➔ "; read -r "$2"; }
divider() { echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"; }

print_logo() {
    clear
    echo -e "${PURPLE}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}███████╗██╗███╗   ██╗ ██████╗       ██████╗  ██████╗ ██╗  ██╗${NC}   ${PURPLE}┃${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}██╔════╝██║████╗  ██║██╔════╝       ██╔══██╗██╔═══██╗╚██╗██╔╝${NC}   ${PURPLE}┃${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}███████╗██║██╔██╗ ██║██║  ███╗█████╗██████╔╝██║   ██║ ╚███╔╝ ${NC}   ${PURPLE}┃${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}╚════██║██║██║╚██╗██║██║   ██║╚════╝██╔══██╗██║   ██║ ██╔██╗ ${NC}   ${PURPLE}┃${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}███████║██║██║ ╚████║╚██████╔╝      ██████╔╝╚██████╔╝██╔╝ ██╗${NC}   ${PURPLE}┃${NC}"
    echo -e "${PURPLE}┃${NC}   ${CYAN}╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝       ╚═════╝  ╚═════╝ ╚═╝  ╚═╝${NC}   ${PURPLE}┃${NC}"
    divider
    echo -e "${PURPLE}┃${NC}          ${YELLOW}${BOLD}✨ Kele's Sing-box 6-in-1 极致稳定架构 (v6.6) ✨${NC}         ${PURPLE}┃${NC}"
    echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
    echo ""
}

# --- 全局变量 ---

# JSON字符串转义（防止用户输入破坏config.json）
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# URL编码（防止特殊字符污染订阅链接）
url_encode() {
    local s="$1"
    local result=""
    local i c
    # IPv6地址含方括号时，保留方括号不编码
    for ((i=0; i<${#s}; i++)); do
        c="${s:$i:1}"
        if [[ "$c" =~ ^[a-zA-Z0-9_.~%-\[\]]+$ ]]; then
            result+="$c"
        else
            result+=$(printf '%%%02X' "'$c")
        fi
    done
    printf '%s' "$result"
}

# 检测systemd是否支持append语法
systemd_supports_append() {
    if command -v systemctl >/dev/null 2>&1; then
        local ver
        ver=$(systemd --version 2>/dev/null | head -n1 | grep -oE '[0-9]+' | head -n1)
        if [ -n "$ver" ] && [ "$ver" -ge 240 ]; then
            return 0
        fi
    fi
    return 1
}
SB_DIR="/etc/sing-box"
SB_CONF="${SB_DIR}/config.json"
SB_INFO="${SB_DIR}/install.info"
SB_BIN="/usr/local/bin/sing-box"
ARGO_BIN="/usr/local/bin/cloudflared"
ARGO_LOG="${SB_DIR}/argo.log"
SB_LOG="${SB_DIR}/sing-box.log"

[[ $EUID -ne 0 ]] && msg_error "必须以 root 用户运行此脚本！" && exit 1

if [[ "$0" != "/usr/bin/sb" ]]; then
    _script_name=$(basename "$0")
    if [[ -f "$0" && "$_script_name" != "bash" && "$_script_name" != "sh" && "$_script_name" != "dash" ]]; then
        rm -f /usr/bin/sb 2>/dev/null
        cp -f "$0" /usr/bin/sb
        chmod +x /usr/bin/sb
        msg_success "快捷指令 'sb' 已就绪，以后直接输入 sb 即可唤出面板！"
        sleep 1
    else
        msg_warn "检测到内存管道执行，跳过快捷指令 'sb' 生成。如需生成，请将脚本下载到本地执行。"
        sleep 2
    fi
fi

load_config() {
    [ -f "$SB_INFO" ] && source "$SB_INFO"
    [ -z "$VD_MODE" ] && VD_MODE="2"
    [ -z "$VD_DOMAIN" ] && VD_DOMAIN=""
    # 模式迁移：自签证书已被内核弃用跳过证书检测能力，迁移老配置
    # 旧 VD_MODE=2 表示"自签伪装"，如今 = mode 1 (关闭 TLS)
    # 旧 VD_MODE=3 表示"真实证书"，合并到新 mode 2
    if [ "$VD_MODE" == "2" ] && [ -z "$VD_DOMAIN" ]; then
        VD_MODE="1"
    elif [ "$VD_MODE" == "3" ]; then
        VD_MODE="2"
    fi
    [ -z "$ENABLE_VD" ] && ENABLE_VD="1"
    [ -z "$ENABLE_RE" ] && ENABLE_RE="1"
    [ -z "$ENABLE_HY" ] && ENABLE_HY="1"
    [ -z "$ENABLE_TC" ] && ENABLE_TC="1"
    [ -z "$ENABLE_S5" ] && ENABLE_S5="1"
    [ -z "$ENABLE_ARGO" ] && ENABLE_ARGO="1"
    [ -z "$HY_HOPPING" ] && HY_HOPPING="0"
    [ -z "$HY_PORTS" ] && HY_PORTS=""
}

save_config() {
    cat > "$SB_INFO" << EOF
UUID_VD=$UUID_VD
UUID_RE=$UUID_RE
UUID_ARGO=$UUID_ARGO
UUID_TC=$UUID_TC
PW_HY=$PW_HY
PW_TC=$PW_TC
S5_U=$S5_U
S5_P=$S5_P
PORT_VD=$PORT_VD
PORT_RE=$PORT_RE
PORT_HY=$PORT_HY
PORT_TC=$PORT_TC
PORT_S5=$PORT_S5
REALITY_PRK=$REALITY_PRK
REALITY_PBK=$REALITY_PBK
REALITY_SNI=$REALITY_SNI
REALITY_SHORT_ID=$REALITY_SHORT_ID
WARP_MODE=$WARP_MODE
WARP_DOMAINS=$WARP_DOMAINS
CUSTOM_IP=$CUSTOM_IP
ARGO_MODE=$ARGO_MODE
ARGO_TOKEN=$ARGO_TOKEN
ARGO_DOMAIN=$ARGO_DOMAIN
VD_MODE=$VD_MODE
VD_DOMAIN=$VD_DOMAIN
ENABLE_VD=$ENABLE_VD
ENABLE_RE=$ENABLE_RE
ENABLE_HY=$ENABLE_HY
ENABLE_TC=$ENABLE_TC
ENABLE_S5=$ENABLE_S5
ENABLE_ARGO=$ENABLE_ARGO
HY_HOPPING=$HY_HOPPING
HY_PORTS=$HY_PORTS
EOF
    chmod 600 "$SB_INFO"
}

is_alpine() { [ -f /etc/alpine-release ]; }

# ---- IPv6-only 探测 & NAT64 Bootstrap (用完即焚) ----------------------------
# 探测当前 VPS 的双栈状态，分别 ping 一下 v4 和 v6 的公网 IP 给出连接性。
# 返回: 0=dual, 1=v4only, 2=v6only
probe_v4_v6_connectivity() {
    local v4 v6
    timeout 4 python3 -c "import socket; socket.create_connection(('1.1.1.1',443),timeout=3); raise SystemExit(0)" 2>/dev/null; v4=$?
    timeout 4 python3 -c "import socket; socket.create_connection(('2606:4700:4700::1111',443),3); raise SystemExit(0)" 2>/dev/null; v6=$?
    if [ "$v4" = "0" ] && [ "$v6" = "0" ]; then echo 0; return
    elif [ "$v4" = "0" ]; then echo 1; return
    elif [ "$v6" = "0" ]; then echo 2; return
    else echo 1; return   # 双栈全断就当 dual 处理, 让显式 IPv4 路径走完整链路
    fi
}

# 严格 IPv6-only：没有 IPv4 default route + 没 IPv4 全球地址 + TCP/443v4 不通。
# Cloudflare NAT64 prefix (64:ff9b::/96) 仅在 tayga 启动后才生效，所以这里只看
# 系统 routing 状态，不假设 NAT64 已经存在。
is_ipv6_only_strict() {
    ip -4 route show default 2>/dev/null | grep -q . && return 1
    [ -n "$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}')" ] && return 1
    timeout 4 python3 -c "import socket; socket.create_connection(('1.1.1.1',443),timeout=3); raise SystemExit(0)" 2>/dev/null && return 1
    return 0
}

# 取 VPS 公网 IPv6（eth0 第一个 global scope inet6）
get_vps_ipv6() {
    ip -6 addr show scope global 2>/dev/null | awk '/inet6 / {print $2}' | cut -d/ -f1 | head -1
}

# 检测 tayga NAT64 是否已经被部署好（仅作 diagnostic, 当前 bootstrap 不用）
nat64_active() {
    [ -d /sys/class/net/nat64 ] || return 1
    ip link show nat64 2>/dev/null | grep -q "state UP" || return 1
    ip -6 route show 2>/dev/null | grep -q "^64:ff9b::/96 dev nat64" || return 1
    ip -4 route show 2>/dev/null | grep -q "^192.168.255.0/24 dev nat64" || return 1
    return 0
}

# 备份 /etc/resolv.conf。仅当 .sb.bak 不存在时才备份 (幂等)
backup_resolv_conf() {
    [ -f /etc/resolv.conf ] || return 1
    [ -f /etc/resolv.conf.sb.bak ] && return 0
    cp /etc/resolv.conf /etc/resolv.conf.sb.bak 2>/dev/null && return 0
    return 1
}

# 把 /etc/resolv.conf 还原到 install 之前的状态，撤销 bootstrap。
restore_resolv_conf() {
    if [ -s /etc/resolv.conf.sb.bak ]; then
        mv -f /etc/resolv.conf.sb.bak /etc/resolv.conf
        msg_success "/etc/resolv.conf 已恢复原状，NAT64 Bootstrap 已撤销"
    fi
}

# 纯 IPv6 VPS 的 NAT64 DNS 注入 (用完即焚，不依赖 tayga/unbound 自建)：
# 1) 检测到 pure IPv6 时直接往 /etc/resolv.conf 写入公共 NAT64 DNS。
#    这些 DNS 服务器 (fscarmen / Hetzner / Cloudflare IPv6 组合) 自带 DNS64 合成
#    A → 64:ff9b::<A> AAAA；VPS provider 通常在网络层默认配置了 64:ff9b::/96
#    NAT64 gateway, 所以 curl / apt 直接走 IPv6 socket 即可拿 IPv4 资源。
# 2) 不需要自建 tayga NAT64 daemon, 不需要 unbound DNS64 转发。
# 3) install_warp() 末尾调用 teardown_nat64_bootstrap() 把 /etc/resolv.conf
#    还原回去, 日常 IPv4 全部交给 WARP tunnel 出网, 不再走公共 NAT64。
inject_nat64_bootstrap() {
    is_ipv6_only_strict || { msg_info "已检测到 IPv4 出口，跳过 NAT64 Bootstrap"; return 0; }

    # 幂等: 已经注入过就不重复
    if grep -q "2a00:1098:2b::1" /etc/resolv.conf 2>/dev/null; then
        msg_info "NAT64 DNS 已就位 (复用)"
        return 0
    fi

    msg_warn "检测到纯 IPv6 环境，临时注入公共 NAT64 DNS 以拉取底层依赖..."
    backup_resolv_conf || msg_warn "resolv.conf 备份失败, 后续 teardown 手动恢复"
    cat > /etc/resolv.conf <<EOF
# sb.sh NAT64 Bootstrap — WARP 起来后自动撤销
nameserver 2a00:1098:2b::1
nameserver 2a01:4f8:c2c:123f::1
nameserver 2606:4700:4700::1111
EOF
    sleep 2
    msg_success "公共 NAT64 DNS 已注入 (用完即焚)"
}

# 撤销 NAT64 Bootstrap：mv 回原 /etc/resolv.conf 即可，无需停服务
teardown_nat64_bootstrap() {
    [ -s /etc/resolv.conf.sb.bak ] || return 0
    restore_resolv_conf
    msg_info "NAT64 Bootstrap 已撤销, 日常 IPv4 出站全部交给 WARP tunnel"
}
# ---------------------------------------------------------------------------

svc_action() {
    local action="$1"; local service="$2"
    if is_alpine; then
        case "$action" in
            enable) rc-update add "$service" default >/dev/null 2>&1 ;;
            disable) rc-update del "$service" default >/dev/null 2>&1 ;;
            start|stop|restart) rc-service "$service" "$action" >/dev/null 2>&1 ;;
            reload) ;;
        esac
    else
        case "$action" in
            enable) systemctl enable --now "$service" >/dev/null 2>&1 ;;
            disable) systemctl disable --now "$service" >/dev/null 2>&1 ;;
            start|stop|restart) systemctl "$action" "$service" >/dev/null 2>&1 ;;
            reload) systemctl daemon-reload >/dev/null 2>&1 ;;
        esac
    fi
}

check_port_usage() {
    local port="$1"; [ -z "$port" ] && return 0
    if command -v lsof >/dev/null 2>&1; then
        lsof -i "TCP:$port" -sTCP:LISTEN >/dev/null 2>&1 && return 1
        lsof -i "UDP:$port" >/dev/null 2>&1 && return 1
    fi
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -qE ":[0-9]*$port\>" && return 1
        ss -uuln | grep -qE ":[0-9]*$port\>" && return 1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -qE ":[0-9]*$port\>" && return 1
        netstat -uuln | grep -qE ":[0-9]*$port\>" && return 1
    fi
    return 0
}

get_random_port() {
    local port
    while true; do
        port=$(( ((RANDOM << 15) | RANDOM) % 50000 + 10000 ))
        if check_port_usage "$port"; then
            echo "$port"
            return 0
        fi
    done
}

ask_port() {
    local prompt_text="$1"; local var_name="$2"; local temp_input
    while true; do
        reading "$prompt_text" temp_input
        if [ -z "$temp_input" ]; then eval "$var_name=\"\""; return; fi
        if [[ ! "$temp_input" =~ ^[0-9]+$ ]] || [ "$temp_input" -lt 1 ] || [ "$temp_input" -gt 65535 ]; then
            msg_error "非法输入！端口必须是 1-65535 之间的纯数字。"
            continue
        fi
        if ! check_port_usage "$temp_input"; then
            msg_error "端口 $temp_input 已被系统占用！"
            continue
        fi
        eval "$var_name=\"$temp_input\""
        return
    done
}

ask_uuid() {
    local prompt_text="$1"; local var_name="$2"; local temp_input
    while true; do
        reading "$prompt_text" temp_input
        if [ -z "$temp_input" ]; then eval "$var_name=\"\""; return; fi
        if [[ ! "$temp_input" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
            msg_error "必须是标准的 UUID 格式！"
            continue
        fi
        eval "$var_name=\"$temp_input\""
        return
    done
}

ask_port_range() {
    local prompt_text="$1"; local var_name="$2"; local target_port="$3"; local temp_input
    while true; do
        reading "$prompt_text" temp_input
        if [ -z "$temp_input" ]; then eval "$var_name=\"\""; return; fi
        if [[ ! "$temp_input" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            msg_error "格式错误！请输入类似 20000-30000 的端口段。"
            continue
        fi
        local p_start="${BASH_REMATCH[1]}"; local p_end="${BASH_REMATCH[2]}"
        if [ "$p_start" -ge "$p_end" ] || [ "$p_start" -lt 1 ] || [ "$p_end" -gt 65535 ]; then
            msg_error "范围不合法！起始端口必须小于结束端口，且均在 1-65535 之间。"
            continue
        fi
        if [ -n "$target_port" ]; then
            if [ "$target_port" -lt "$p_start" ] || [ "$target_port" -gt "$p_end" ]; then
                msg_error "逻辑错误！主端口 ($target_port) 必须包含在你填写的跳跃段 ($p_start-$p_end) 内，否则节点必定失联！"
                continue
            fi
        fi
        eval "$var_name=\"$temp_input\""
        return
    done
}

get_outbound_ip() {
    local ip=""
    for i in 1 2 3; do
        ip=$(curl -s4 --max-time 5 https://api.ipify.org 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s4 --max-time 5 https://ifconfig.me/ip 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s4 --max-time 5 https://ip.gs 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s6 --max-time 5 https://api6.ipify.org 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s6 --max-time 5 ipv6.ip.sb 2>/dev/null); [ -n "$ip" ] && break
        sleep 1
    done
    if [ -z "$ip" ]; then
        msg_error "无法自动探测公网IP，请确保网络连通或手动指定IP/域名。"
        echo "127.0.0.1"
        return 1
    fi
    echo "$ip"
    return 0
}

get_country_prefix() {
    local cc
    cc=$(curl -s --max-time 3 http://ip-api.com/line/?fields=countryCode 2>/dev/null)
    [ -z "$cc" ] && cc=$(curl -s --max-time 3 https://ipinfo.io/country 2>/dev/null)
    case "$cc" in
        "CN") echo "🇨🇳中国" ;; "HK") echo "🇭🇰香港" ;; "TW") echo "🇹🇼台湾" ;;
        "MO") echo "🇲🇴澳门" ;; "JP") echo "🇯🇵日本" ;; "KR") echo "🇰🇷韩国" ;;
        "SG") echo "🇸🇬新加坡" ;; "US") echo "🇺🇸美国" ;; "GB") echo "🇬🇧英国" ;;
        "DE") echo "🇩🇪德国" ;; "FR") echo "🇫🇷法国" ;; "NL") echo "🇳🇱荷兰" ;;
        *) echo "🌍未知" ;;
    esac
}

optimize_network() {
    cat > /etc/sysctl.d/99-singbox-optimize.conf << EOF
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_keepalive_time=30
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_keepalive_probes=6
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=33554432
net.core.wmem_max=33554432
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.core.netdev_max_backlog=10000
EOF
    sysctl -p /etc/sysctl.d/99-singbox-optimize.conf >/dev/null 2>&1 || true
}

install_deps() {
    # 纯 IPv6 环境只要 NAT64 Bootstrap 起来, 后续 apt/curl 都能拿 IPv4 endpoints。
    inject_nat64_bootstrap

    echo ""; msg_info "正在检查并安装基础依赖环境 (包含 iptables)..."
    if is_alpine; then
        apk update >/dev/null 2>&1
        apk add bash curl wget jq openssl lsof socat procps libc6-compat gcompat iptables ip6tables >/dev/null 2>&1
    else
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -y >/dev/null 2>&1
            local apt_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps" "lsb-release" "iptables")
            for pkg in "${apt_pkgs[@]}"; do
                local cmd_name="$pkg"
                [ "$pkg" = "lsb-release" ] && cmd_name="lsb_release"
                ! command -v "$cmd_name" >/dev/null 2>&1 && apt-get install -y "$pkg" >/dev/null 2>&1
            done
        elif command -v yum >/dev/null 2>&1; then
            yum makecache -y >/dev/null 2>&1
            yum install -y epel-release >/dev/null 2>&1
            local yum_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps-ng" "redhat-lsb-core" "iptables")
            for pkg in "${yum_pkgs[@]}"; do
                local cmd_name="$pkg"
                [ "$pkg" = "redhat-lsb-core" ] && cmd_name="lsb_release"
                ! command -v "$cmd_name" >/dev/null 2>&1 && yum install -y "$pkg" >/dev/null 2>&1
            done
        else
            msg_error "不支持的包管理器，请手动安装核心依赖。"
            exit 1
        fi
    fi
    optimize_network
}

safe_download() {
    local url="$1"; local dest="$2"
    msg_info "正在下载核心组件: $(basename "$dest")..."
    local http_code
    http_code=$(curl -sL -w "%{http_code}" -o "$dest" "$url")
    if [ "$http_code" != "200" ]; then msg_error "文件下载失败！"; rm -f "$dest"; return 1; fi
    if [ ! -s "$dest" ]; then msg_error "下载失败！文件为空。"; rm -f "$dest"; return 1; fi
    return 0
}

apply_cert() {
    local domain=$1
    if [ ! -d ~/.acme.sh ]; then msg_warn "正在安装 acme.sh 证书工具..."; curl -fsSL https://get.acme.sh | sh >/dev/null 2>&1; fi
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1

    echo -e "\n${BG_BLUE} 证书申请 ${NC} 开始为 ${YELLOW}$domain${NC} 申请 TLS 证书..."
    local standalone_success=false
    if check_port_usage 80; then
        if ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force; then
            standalone_success=true
        fi
    else msg_warn "80 端口被占用或不可达，跳过 Standalone 模式。"; fi

    if [ "$standalone_success" = false ]; then
        msg_error "Standalone 模式失败，切换至 API 验证模式。"
        reading "是否启用 Cloudflare API 继续申请？[y/n]" use_dns
        use_dns=${use_dns,,}; [ -z "$use_dns" ] && use_dns="y"
        if [[ "$use_dns" != "y" ]]; then msg_error "已取消证书申请。"; return 1; fi

        reading "请输入 Cloudflare API Token" cf_token; export CF_Token="$cf_token"
        reading "请输入域名的 Zone ID" cf_zone_id; export CF_Zone_ID="$cf_zone_id"

        msg_info "API 申请中，请耐心等待 1-2 分钟..."
        if ! ~/.acme.sh/acme.sh --issue --dns dns_cf -d "$domain" -k ec-256 --force; then
            msg_error "证书申请彻底失败！"; return 1
        fi
    fi

    mkdir -p "${SB_DIR}"
    ~/.acme.sh/acme.sh --installcert -d "$domain" --fullchain-file "${SB_DIR}/server.crt" --key-file "${SB_DIR}/server.key" --ecc >/dev/null 2>&1
    chmod 600 "${SB_DIR}/server.crt" "${SB_DIR}/server.key"
    msg_success "真实域名证书部署成功！"
    return 0
}

install_singbox() {
    if [ ! -f "$SB_BIN" ]; then
        local ARCH S_ARCH TAG
        ARCH=$(uname -m); case "${ARCH}" in x86_64) S_ARCH="amd64" ;; aarch64|arm64) S_ARCH="arm64" ;; *) msg_error "不支持的架构"; exit 1 ;; esac
        # 仅拉取最新 stable 版（过滤 prerelease == true），避免使用 alpha 内核
        TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases?per_page=20" | jq -r '.[] | select(.prerelease == false) | .tag_name' 2>/dev/null | head -n 1)
        if [ -z "$TAG" ] || [ "$TAG" == "null" ]; then
            TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r '.tag_name' 2>/dev/null)
            [ -z "$TAG" ] || [ "$TAG" == "null" ] && TAG="v1.11.5"
        fi
        msg_info "正在下载 sing-box ${TAG} (最新稳定版)..."
        if safe_download "https://github.com/SagerNet/sing-box/releases/download/${TAG}/sing-box-${TAG#v}-linux-${S_ARCH}.tar.gz" "sb.tar.gz"; then
            tar -xzf sb.tar.gz || { msg_error "解压失败"; exit 1; }
            mv sing-box-*/sing-box "$SB_BIN"; rm -rf sb.tar.gz sing-box-*
            chmod +x "$SB_BIN"
        else exit 1; fi
    fi
}

# 生成Reality密钥对，增加健壮性校验
generate_reality_keys() {
    local keys
    keys=$($SB_BIN generate reality-keypair 2>/dev/null)
    if [ -z "$keys" ]; then
        msg_error "sing-box 生成 Reality 密钥对失败，请检查二进制文件是否完整。"
        return 1
    fi
    REALITY_PRK=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
    REALITY_PBK=$(echo "$keys" | awk '/PublicKey/ {print $2}')
    if [ -z "$REALITY_PRK" ] || [ -z "$REALITY_PBK" ]; then
        msg_error "解析 Reality 密钥失败，输出格式异常：$keys"
        return 1
    fi
    return 0
}

install_argo() {
    if [ ! -f "$ARGO_BIN" ]; then
        local ARCH A_ARCH
        ARCH=$(uname -m); case "${ARCH}" in x86_64) A_ARCH="amd64" ;; aarch64|arm64) A_ARCH="arm64" ;; *) msg_error "不支持的架构"; return 1 ;; esac
        if safe_download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${A_ARCH}" "$ARGO_BIN"; then
            chmod +x "$ARGO_BIN"
        fi
    fi
}

# 安装 WARP：自建 kernel wireguard tunnel，绝不依赖 cloudflare-warp 的 warp-svc
# daemon（它会装 nftables rules hijack 出网, pure IPv6 主机上会锁 SSH）。
# 流程：cloudflare-warp apt 包拿 warp-cli 注册设备 → 提取 private_key →
#       /etc/wireguard/warp.conf + ip link add warp type wireguard →
#       iptables fwmark 0xca6c → systemd 持久化。
# 若是 IPv6-only VPS：进入 install_warp 前 inject_nat64_bootstrap 已经到位；
# WARP tunnel up 后立即调用 teardown_nat64_bootstrap 解开 NAT64, 后续 IPv4
# 全部走 warp tunnel, 避免公共 NAT64 拖垮节点稳定性。
install_warp() {
    if is_alpine; then return; fi

    # === 阶段 1：装 cloudflare-warp (拿到 warp-cli 注册设备) ==============
    if ! command -v warp-cli >/dev/null 2>&1; then
        msg_info "正在安装 cloudflare-warp (取 warp-cli 注册设备)..."
        if command -v apt-get >/dev/null 2>&1; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y curl gnupg lsb-release >/dev/null 2>&1
            mkdir -p /usr/share/keyrings
            curl -fsSl https://pkg.cloudflareclient.com/pubkey.gpg 2>/dev/null \
                | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg 2>/dev/null
            local dist_codename=""
            if command -v lsb_release >/dev/null 2>&1; then dist_codename=$(lsb_release -cs)
            else dist_codename=$(grep '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d'=' -f2); [ -z "$dist_codename" ] && dist_codename="stable"; fi
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com $dist_codename main" \
                > /etc/apt/sources.list.d/cloudflare-client.list 2>/dev/null
            apt-get update -y >/dev/null 2>&1 || true
            DEBIAN_FRONTEND=noninteractive apt-get install -y cloudflare-warp >/dev/null 2>&1 || true
        elif command -v yum >/dev/null 2>&1; then msg_error "WARP 不支持 yum 系系统。"; return 1
        else return 1; fi
    fi
    if ! command -v warp-cli >/dev/null 2>&1; then
        msg_warn "warp-cli 未能安装, WARP tunnel 部署跳过"
        return 1
    fi

    # === 阶段 2：注册设备 + 提取 identity ================================
    # 关键：warp-cli 是 client，必须 warp-svc daemon 起来才能连上注册设备。
    # 注册完后立刻 stop+disable daemon (避免它的 nftables 把 outbound
    # IPv4/v6 全部 hijack, 在 pure IPv6 上还可能锁 SSH)。真正的 wireguard
    # interface 由 kernel module + 自己 fwmark 接管。
    systemctl enable --now warp-svc >/dev/null 2>&1
    # 等 daemon ready (warp-cli connect IPC socket 通常 1-2s)
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        systemctl is-active warp-svc >/dev/null 2>&1 && break
        sleep 1
    done

    local REG="/var/lib/cloudflare-warp/registration.json"
    [ ! -f "$REG" ] && REG="/var/lib/warp-svc/registration.json"
    if [ ! -f "$REG" ]; then
        msg_info "首次注册 Cloudflare WARP 设备..."
        warp-cli --accept-tos registration new >/dev/null 2>&1 || {
            systemctl disable --now warp-svc >/dev/null 2>&1 || true
            msg_warn "warp-cli registration new 失败 (pure IPv6 + NAT64 没起来?), WARP 跳过"; return 1
        }
    fi
    # 注册完成, 立刻 stop+disable daemon, 避免 daemon 接管出网
    systemctl disable --now warp-svc >/dev/null 2>&1 || true
    local PRIV IPV4 IPV6
    PRIV=$(jq -r '.warp.private_key // empty' "$REG" 2>/dev/null)
    IPV4=$(jq -r '.warp.interface.addresses.v4 // empty' "$REG" 2>/dev/null)
    IPV6=$(jq -r '.warp.interface.addresses.v6 // empty' "$REG" 2>/dev/null)
    if [ -z "$PRIV" ] || [ -z "$IPV4" ] || [ -z "$IPV6" ]; then
        msg_warn "registration.json 解析失败 (PRIV=${PRIV:-N/A}, IPV4=${IPV4:-N/A}, IPV6=${IPV6:-N/A})"; return 1
    fi

    # === 阶段 3：写 /etc/wireguard/warp.conf + 启动 kernel wireguard =======
    mkdir -p /etc/wireguard
    local VPS_IPV6; VPS_IPV6=$(get_vps_ipv6)
    cat > /etc/wireguard/warp.conf <<EOF
[Interface]
PrivateKey = ${PRIV}
Address = ${IPV4}/32
Address = ${IPV6}/128
DNS = 1.1.1.1, 2606:4700:4700::1111
MTU = 1280
Table = off

PostUp = ip -4 rule add fwmark 0xca6c lookup 51820
PostUp = ip -4 route add default dev warp table 51820
PostUp = ip -4 rule add from 192.168.255.0/24 lookup main priority 100
PostDown = ip -4 rule del fwmark 0xca6c lookup 51820
PostDown = ip -4 route del default dev warp table 51820
PostDown = ip -4 rule del from 192.168.255.0/24 lookup main priority 100

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0
Endpoint = 162.159.193.1:2408
PersistentKeepalive = 25
EOF
    chmod 600 /etc/wireguard/warp.conf

    # 启动 kernel wireguard (Debian 13 默认带 1.0.0, 否则装 wireguard-tools)
    if ! modprobe wireguard 2>/dev/null && ! is_alpine; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard-tools >/dev/null 2>&1 || true
        modprobe wireguard 2>/dev/null || true
    fi
    ip link delete warp 2>/dev/null || true
    ip link add warp type wireguard 2>/dev/null
    wg setconf warp /etc/wireguard/warp.conf 2>/dev/null || {
        msg_warn "wg setconf 失败, 可能是 kernel 缺 wireguard 模块"; return 1
    }
    ip link set mtu 1280 up dev warp

    # iptables fwmark：让本机 system curl/apt 等 IPv4 outbound 也走 warp tunnel
    iptables -t mangle -C OUTPUT -p tcp --dport 443 -j MARK --set-mark 0xca6c 2>/dev/null \
        || iptables -t mangle -A OUTPUT -p tcp --dport 443 -j MARK --set-mark 0xca6c 2>/dev/null
    iptables -t mangle -C OUTPUT -p tcp --dport 80 -j MARK --set-mark 0xca6c 2>/dev/null \
        || iptables -t mangle -A OUTPUT -p tcp --dport 80 -j MARK --set-mark 0xca6c 2>/dev/null

    # systemd unit 持久化：开机自动起 wireguard tunnel
    cat > /etc/systemd/system/warp-sb.service <<'UNIT'
[Unit]
Description=Sing-box WARP tunnel (kernel wireguard + fwmark)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'wg setconf warp /etc/wireguard/warp.conf && ip link set mtu 1280 up dev warp'
ExecStop=/bin/sh -c 'ip link delete warp 2>/dev/null; true'
RestartSec=3
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
    systemctl daemon-reload
    systemctl enable --now warp-sb.service >/dev/null 2>&1

    msg_success "WARP tunnel 已部署 (kernel wireguard, fwmark 0xca6c → table 51820 → dev warp)"

    # === 阶段 4：撤销 NAT64 Bootstrap（IPv6-only 主机才需要） ===============
    # DNS 切回原始上游, IPv4 outbound 改走 warp tunnel (替代 NAT64 兜底)
    if is_ipv6_only_strict; then
        teardown_nat64_bootstrap
    fi
    return 0
}

generate_config() {
    mkdir -p "$SB_DIR"

    # 基础输入安全过滤：禁止JSON破坏性字符进入域名类变量
    VD_DOMAIN="${VD_DOMAIN//\\/}"; VD_DOMAIN="${VD_DOMAIN//\"/}"
    REALITY_SNI="${REALITY_SNI//\\/}"; REALITY_SNI="${REALITY_SNI//\"/}"
    WARP_DOMAINS="${WARP_DOMAINS//\\/}"; WARP_DOMAINS="${WARP_DOMAINS//\"/}"

    # 强制证书检查：任何 TLS 协议都依赖真实证书（自签已被内核弃用跳过证书检测能力后不可用）
    local needs_tls=false
    [ "$ENABLE_VD" == "1" ] && [ "$VD_MODE" != "1" ] && needs_tls=true
    [ "$ENABLE_HY" == "1" ] && needs_tls=true
    [ "$ENABLE_TC" == "1" ] && needs_tls=true
    if [ "$needs_tls" == "true" ] && [ ! -f "${SB_DIR}/server.crt" ]; then
        if [ -n "$VD_DOMAIN" ]; then
            msg_warn "检测到证书缺失，正在为 ${VD_DOMAIN} 自动申请一次..."
            if ! apply_cert "$VD_DOMAIN"; then
                msg_error "证书申请失败，无法继续！"
                return 1
            fi
        else
            msg_error "需要真实域名证书，但 ${SB_DIR}/server.crt 不存在！"
            msg_error "请先在协议管理中填入域名并申请证书。"
            return 1
        fi
    fi

    local rules_json='{"outbound": "direct-out"}'
    if [ "$WARP_MODE" == "2" ] && ! is_alpine; then rules_json='{"outbound": "warp-out"}'
    elif [ "$WARP_MODE" == "3" ] && ! is_alpine && [ -n "$WARP_DOMAINS" ]; then
        IFS=',' read -ra DOMAINS <<< "$WARP_DOMAINS"; local domain_array=""
        for d in "${DOMAINS[@]}"; do [ -n "$d" ] && domain_array+="\"$d\","; done
        domain_array=${domain_array%,}
        [ -n "$domain_array" ] && rules_json="{ \"domain_suffix\": [${domain_array}], \"outbound\": \"warp-out\" }, { \"outbound\": \"direct-out\" }"
    elif [ "$WARP_MODE" == "4" ] && ! is_alpine; then
        # 原生 IPv6 直连 + 全部 IPv4 强走 WARP (适合 dual-stack 和 pure IPv6 VPS,
        # 避免 WARP 隧道里再套一层 IPv6 over IPv4)
        rules_json='{ "ip_version": 6, "outbound": "direct-out" }, { "ip_version": 4, "outbound": "warp-out" }'
    fi

    local INBOUNDS=""

    if [ "$ENABLE_ARGO" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-argo\", \"listen\": \"127.0.0.1\", \"listen_port\": 10086, \"users\": [ { \"uuid\": \"$UUID_ARGO\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/argo\" } },"
    fi

    if [ "$ENABLE_RE" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-reality\", \"listen\": \"::\", \"listen_port\": $PORT_RE, \"users\": [ { \"uuid\": \"$UUID_RE\", \"flow\": \"xtls-rprx-vision\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$REALITY_SNI\", \"reality\": { \"enabled\": true, \"handshake\": { \"server\": \"$REALITY_SNI\", \"server_port\": 443 }, \"private_key\": \"$REALITY_PRK\", \"short_id\": [ \"\" ] } } },"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        elif [ "$VD_MODE" == "2" ] && [ -n "$VD_DOMAIN" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$VD_DOMAIN\", \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        else
            msg_error "VLESS-WS TLS 模式 (VD_MODE=$VD_MODE) 配置异常：开启 TLS 必须先填入域名并申请证书！"
            msg_error "请到 \033[1;33m协议管理 → [1] 修改 VLESS\033[0m 选择 [2] 申请真实证书。"
            return 1
        fi
    fi

    if [ "$ENABLE_HY" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"hysteria2\", \"tag\": \"in-hy2\", \"listen\": \"::\", \"listen_port\": $PORT_HY, \"users\": [ { \"password\": \"$PW_HY\" } ], \"tls\": { \"enabled\": true, \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" } },"
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"tuic\", \"tag\": \"in-tuic\", \"listen\": \"::\", \"listen_port\": $PORT_TC, \"users\": [ { \"uuid\": \"$UUID_TC\", \"password\": \"$PW_TC\" } ], \"tls\": { \"enabled\": true, \"alpn\": [\"h3\"], \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"congestion_control\": \"bbr\" },"
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"socks\", \"tag\": \"in-socks\", \"listen\": \"::\", \"listen_port\": $PORT_S5, \"users\": [ { \"username\": \"$S5_U\", \"password\": \"$S5_P\" } ] },"
    fi

    INBOUNDS=${INBOUNDS%,}

    cat > "$SB_CONF" << EOF
{
  "log": { "level": "warn", "timestamp": true },
  "dns": {
    "servers": [
      { "tag": "dns-ipv6", "type": "udp", "server": "[2606:4700:4700::1111]" },
      { "tag": "dns-ipv4", "type": "udp", "server": "1.1.1.1" }
    ],
    "final": "dns-ipv6",
    "strategy": "prefer_ipv4",
    "independent_cache": true
  },
  "inbounds": [
    $INBOUNDS
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct-out" },
    { "type": "direct", "tag": "warp-out", "bind_interface": "warp" },
    { "type": "block", "tag": "block-out" }
  ],
  "route": { "rules": [ $rules_json ], "auto_detect_interface": true, "final": "direct-out", "default_domain_resolver": "dns-ipv6" }
}
EOF
    save_config
}

# --- 防火墙端口跳跃模块 (带高级冲突规避) ---
apply_iptables() {
    # 彻底清洗老规则
    while iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null; do :; done
    while ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null; do :; done
    while iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null; do :; done
    while ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null; do :; done

    if [ "$ENABLE_HY" == "1" ] && [ "$HY_HOPPING" == "1" ] && [ -n "$HY_PORTS" ]; then
        local start_port end_port
        start_port=$(echo "$HY_PORTS" | cut -d'-' -f1)
        end_port=$(echo "$HY_PORTS" | cut -d'-' -f2)

        # 核心逻辑：为 TUIC 和 SOCKS5 建立豁免通道，防止被 Hy2 规则强行劫持
        if [ "$ENABLE_TC" == "1" ] && [ -n "$PORT_TC" ]; then
            iptables -t nat -A PREROUTING -p udp --dport "$PORT_TC" -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null
            ip6tables -t nat -A PREROUTING -p udp --dport "$PORT_TC" -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null
        fi
        if [ "$ENABLE_S5" == "1" ] && [ -n "$PORT_S5" ]; then
            iptables -t nat -A PREROUTING -p udp --dport "$PORT_S5" -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null
            ip6tables -t nat -A PREROUTING -p udp --dport "$PORT_S5" -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null
        fi

        # 建立跳跃劫持规则
        iptables -t nat -A PREROUTING -p udp --dport "${start_port}:${end_port}" -m comment --comment "hy2-hopping" -j REDIRECT --to-ports "$PORT_HY" 2>/dev/null
        ip6tables -t nat -A PREROUTING -p udp --dport "${start_port}:${end_port}" -m comment --comment "hy2-hopping" -j REDIRECT --to-ports "$PORT_HY" 2>/dev/null
    fi
}

setup_services() {
    apply_iptables

    local ARGO_CMD="$ARGO_BIN tunnel --url http://127.0.0.1:10086 --no-autoupdate --edge-ip-version auto"
    if [ "$ARGO_MODE" == "fixed" ] && [ -n "$ARGO_TOKEN" ]; then
        ARGO_CMD="$ARGO_BIN tunnel run --token $(printf '%q' "$ARGO_TOKEN")"
    fi

    if is_alpine; then
        cat > /etc/init.d/sing-box << 'RCINIT'
#!/sbin/openrc-run
command="SB_BIN_PLACEHOLDER"
command_args="run -c SB_CONF_PLACEHOLDER"
command_background=true
pidfile="/var/run/sing-box.pid"
output_log="SB_LOG_PLACEHOLDER"
error_log="SB_LOG_PLACEHOLDER"
RCINIT
        sed -i "s|SB_BIN_PLACEHOLDER|$SB_BIN|g; s|SB_CONF_PLACEHOLDER|$SB_CONF|g; s|SB_LOG_PLACEHOLDER|$SB_LOG|g" /etc/init.d/sing-box

        cat > /etc/init.d/sb-argo << 'RCINIT'
#!/sbin/openrc-run
command="ARGO_BIN_PLACEHOLDER"
command_args="ARGO_CMD_PLACEHOLDER"
command_background=true
pidfile="/var/run/sb-argo.pid"
output_log="ARGO_LOG_PLACEHOLDER"
error_log="ARGO_LOG_PLACEHOLDER"
RCINIT
        local _argo_args="${ARGO_CMD#* }"
        sed -i "s|ARGO_BIN_PLACEHOLDER|$ARGO_BIN|g; s|ARGO_CMD_PLACEHOLDER|$_argo_args|g; s|ARGO_LOG_PLACEHOLDER|$ARGO_LOG|g" /etc/init.d/sb-argo
        chmod +x /etc/init.d/sing-box /etc/init.d/sb-argo
    else
        local sb_std argo_std
        if systemd_supports_append; then
            sb_std="StandardOutput=append:$SB_LOG\nStandardError=append:$SB_LOG"
            argo_std="StandardOutput=append:$ARGO_LOG\nStandardError=append:$ARGO_LOG"
        else
            sb_std="StandardOutput=file:$SB_LOG\nStandardError=file:$SB_LOG"
            argo_std="StandardOutput=file:$ARGO_LOG\nStandardError=file:$ARGO_LOG"
        fi
        printf '%b\n' "[Unit]" "Description=Sing-box Core Service" "After=network.target" "[Service]" "ExecStart=$SB_BIN run -c $SB_CONF" "Restart=always" "RestartSec=3" "StartLimitInterval=0" "LimitNOFILE=1048576" "WorkingDirectory=$SB_DIR" "$sb_std" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/sing-box.service
        if [ "$ARGO_MODE" == "temp" ] || [ -z "$ARGO_TOKEN" ]; then
            printf '%b\n' "[Unit]" "Description=Argo Tunnel for Sing-box" "After=network.target" "[Service]" "ExecStart=$ARGO_BIN tunnel --url http://127.0.0.1:10086 --no-autoupdate --edge-ip-version auto" "Restart=always" "RestartSec=3" "StartLimitInterval=0" "WorkingDirectory=$SB_DIR" "$argo_std" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/sb-argo.service
        else
            printf '%b\n' "[Unit]" "Description=Argo Tunnel for Sing-box" "After=network.target" "[Service]" "ExecStart=$ARGO_BIN tunnel run --token $ARGO_TOKEN" "Restart=always" "RestartSec=3" "StartLimitInterval=0" "WorkingDirectory=$SB_DIR" "$argo_std" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/sb-argo.service
        fi
        svc_action reload
    fi

    svc_action enable sing-box; svc_action restart sing-box

    if [ "$ENABLE_ARGO" == "1" ]; then
        svc_action enable sb-argo; svc_action restart sb-argo
    else
        svc_action stop sb-argo >/dev/null 2>&1; svc_action disable sb-argo >/dev/null 2>&1
    fi
}

check_existing() {
    if [ -f "$SB_INFO" ]; then
        msg_warn "检测到系统已部署过节点！"
        reading "是否确定要清除旧配置并重新安装？[y/n]" confirm
        confirm=${confirm,,}; if [[ "$confirm" != "y" ]]; then return 1; fi
        find "$SB_DIR" -type f ! -name "server.crt" ! -name "server.key" -delete 2>/dev/null
    fi
    return 0
}

install_fast() {
    print_logo
    echo -e "${BG_PURPLE} 一键极速部署 ${NC} ${YELLOW}开始部署全协议...${NC}\n"
    check_existing || return

    install_deps; install_singbox; install_argo

    # 强制要求真实域名证书（内核已弃用跳过证书检测，自签证书不再可用）
    echo -e "\n${BG_RED} 强制证书 ${NC} ${RED}脚本强制要求使用真实域名证书！${NC}"
    msg_warn "sing-box 等主流内核即将弃用\"跳过证书检测\"功能，自签证书已不可用，必须先申请真实证书。"
    echo ""
    while true; do
        reading "请输入一个已解析到此 VPS 的真实域名 (例如: vpn.example.com)" vd_input
        if [ -z "$vd_input" ]; then
            msg_error "域名不能为空，已取消一键部署。"
            return 1
        fi
        VD_DOMAIN="$vd_input"
        if apply_cert "$VD_DOMAIN"; then
            echo -e "  ${GREEN}➤ 已为 ${VD_DOMAIN} 申请并部署证书${NC}"
            break
        fi
        msg_warn "证书申请失败，请重新输入域名或检查 DNS 解析后重试。"
    done

    UUID_VD=$(cat /proc/sys/kernel/random/uuid); UUID_RE=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid); UUID_TC=$(cat /proc/sys/kernel/random/uuid)
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10); PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    S5_U="user"; S5_P=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

    ENABLE_VD=1; ENABLE_RE=1; ENABLE_HY=1; ENABLE_TC=1; ENABLE_S5=1; ENABLE_ARGO=1

    msg_info "正在自动分配系统可用端口..."
    PORT_VD=$(get_random_port); PORT_RE=$(get_random_port); PORT_HY=$(get_random_port)
    PORT_TC=$(get_random_port); PORT_S5=$(get_random_port)

    msg_info "正在生成 Reality 专属密钥对..."
    if ! generate_reality_keys; then
        msg_error "Reality 密钥生成失败，安装中止。"
        exit 1
    fi
    REALITY_SHORT_ID=""
    REALITY_SNI="addons.mozilla.org"

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"  # 一键部署：直接使用上面已申请的证书
    HY_HOPPING="0"; HY_PORTS=""

    msg_info "正在写入底层架构并启动守护进程..."
    if ! generate_config; then
        msg_error "配置生成失败，部署中止。"
        exit 1
    fi
    setup_services
    echo ""; msg_success "一键部署已完成！"; sleep 2
}

install_custom() {
    print_logo
    echo -e "${BG_PURPLE} 自定义部署 ${NC} ${YELLOW}进入按需部署模式...${NC}\n"
    check_existing || return

    install_deps; install_singbox; install_argo

    # 强制要求真实域名证书（内核已弃用跳过证书检测，自签证书不再可用）
    echo -e "\n${BG_RED} 强制证书 ${NC} ${RED}脚本强制要求使用真实域名证书！${NC}"
    msg_warn "sing-box 等主流内核即将弃用\"跳过证书检测\"功能，自签证书已不可用，必须先申请真实证书。"
    echo ""
    while true; do
        reading "请输入一个已解析到此 VPS 的真实域名 (例如: vpn.example.com)" vd_input
        if [ -z "$vd_input" ]; then
            msg_error "域名不能为空，已取消自定义部署。"
            return 1
        fi
        VD_DOMAIN="$vd_input"
        if apply_cert "$VD_DOMAIN"; then
            echo -e "  ${GREEN}➤ 已为 ${VD_DOMAIN} 申请并部署证书${NC}"
            break
        fi
        msg_warn "证书申请失败，请重新输入域名或检查 DNS 解析后重试。"
    done

    UUID_VD=$(cat /proc/sys/kernel/random/uuid); UUID_RE=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid); UUID_TC=$(cat /proc/sys/kernel/random/uuid)
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10); PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    S5_U="user"; S5_P=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

    echo -e "${BG_BLUE} 协议开关 ${NC} (NAT 环境建议自定义端口)"
    reading "启用 VLESS (WS) [y/n] (默认 y)" c_vd; c_vd=${c_vd,,}; [ -z "$c_vd" ] && c_vd="y"; ENABLE_VD=$([[ "$c_vd" == "y" ]] && echo 1 || echo 0)
    reading "启用 VLESS (XTLS-Reality) [y/n] (默认 y)" c_re; c_re=${c_re,,}; [ -z "$c_re" ] && c_re="y"; ENABLE_RE=$([[ "$c_re" == "y" ]] && echo 1 || echo 0)
    reading "启用 Hysteria 2 (UDP) [y/n] (默认 y)" c_hy; c_hy=${c_hy,,}; [ -z "$c_hy" ] && c_hy="y"; ENABLE_HY=$([[ "$c_hy" == "y" ]] && echo 1 || echo 0)
    reading "启用 TUIC v5 (UDP) [y/n] (默认 y)" c_tc; c_tc=${c_tc,,}; [ -z "$c_tc" ] && c_tc="y"; ENABLE_TC=$([[ "$c_tc" == "y" ]] && echo 1 || echo 0)
    reading "启用 SOCKS5 [y/n] (默认 y)" c_s5; c_s5=${c_s5,,}; [ -z "$c_s5" ] && c_s5="y"; ENABLE_S5=$([[ "$c_s5" == "y" ]] && echo 1 || echo 0)
    reading "启用 Argo 隧道 [y/n] (默认 y)" c_ar; c_ar=${c_ar,,}; [ -z "$c_ar" ] && c_ar="y"; ENABLE_ARGO=$([[ "$c_ar" == "y" ]] && echo 1 || echo 0)

    echo -e "\n${BG_BLUE} 端口与参数分配 ${NC}"
    
    if [ "$ENABLE_VD" == "1" ]; then
        ask_port "VLESS (WS) 外网端口 (回车随机)" PORT_VD
        if [ -z "$PORT_VD" ]; then PORT_VD=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 VLESS 端口: ${GREEN}$PORT_VD${NC}"; fi
    fi
    if [ "$ENABLE_RE" == "1" ]; then
        ask_port "Reality 外网端口 (建议443，回车随机)" PORT_RE
        if [ -z "$PORT_RE" ]; then PORT_RE=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 Reality 端口: ${GREEN}$PORT_RE${NC}"; fi
        msg_info "正在生成 Reality 密钥对..."
        if ! generate_reality_keys; then
            msg_error "Reality 密钥生成失败，安装中止。"
            exit 1
        fi
        REALITY_SHORT_ID=""
        REALITY_SNI="addons.mozilla.org"
    fi
    if [ "$ENABLE_HY" == "1" ]; then
        ask_port "Hysteria2 外网端口 (回车随机)" PORT_HY
        if [ -z "$PORT_HY" ]; then PORT_HY=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 Hysteria2 端口: ${GREEN}$PORT_HY${NC}"; fi
        
        reading "是否开启端口跳跃 (Port Hopping)? [y/n] (默认 n)" ph
        if [[ "${ph,,}" == "y" ]]; then
            HY_HOPPING=1
            ask_port_range "请输入连续跳跃端口段 (例如: 20000-30000)" HY_PORTS "$PORT_HY"
        else HY_HOPPING=0; HY_PORTS=""; fi
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        ask_port "TUIC 外网端口 (回车随机)" PORT_TC
        if [ -z "$PORT_TC" ]; then PORT_TC=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 TUIC 端口: ${GREEN}$PORT_TC${NC}"; fi
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        ask_port "SOCKS5 外网端口 (回车随机)" PORT_S5
        if [ -z "$PORT_S5" ]; then PORT_S5=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 SOCKS5 端口: ${GREEN}$PORT_S5${NC}"; fi
    fi

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"  # 自定义部署：使用流程开头已申请的证书域名

    echo ""; msg_info "正在写入底层架构并启动守护进程..."
    if ! generate_config; then
        msg_error "配置生成失败，部署中止。"
        exit 1
    fi
    setup_services
    echo ""; msg_success "自定义部署已完成！"; sleep 2
}

manage_protocols() {
    [ ! -f "$SB_INFO" ] && msg_error "请先进行部署！" && sleep 1 && return
    load_config
    while true; do
        print_logo
        echo -e "${PURPLE}╭━━━ ⚙️ ${BG_BLUE} 协议精细化管理 ${NC} ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        [ "$ENABLE_VD" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [1]\t⚡ 修改 VLESS (WS)   ${YELLOW}(端口: $PORT_VD)${NC}"
        [ "$ENABLE_RE" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [2]\t🎭 修改 Reality      ${YELLOW}(端口: $PORT_RE)${NC}"
        [ "$ENABLE_HY" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [3]\t🚀 修改 Hy2          ${YELLOW}(端口: $PORT_HY)${NC}"
        [ "$ENABLE_TC" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [4]\t🏎️ 修改 TUIC v5      ${YELLOW}(端口: $PORT_TC)${NC}"
        [ "$ENABLE_S5" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [5]\t🛡️ 修改 SOCKS5       ${YELLOW}(端口: $PORT_S5)${NC}"
        [ "$ENABLE_ARGO" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [6]\t☁️  配置 Argo 隧道    ${YELLOW}(模式: $ARGO_MODE)${NC}"
        echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        printf '%b\n' "${PURPLE}┃${NC}  ${RED}[7]\t🛑 停用/卸载单独协议${NC}"
        printf '%b\n' "${PURPLE}┃${NC}  [0]\t↩️  返回主菜单${NC}"
        echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
        reading "请选择操作 [0-7]" choice
        case $choice in
            1)
                [ "$ENABLE_VD" != "1" ] && continue
                ask_port "新 VLESS 端口 (回车不变)" p; [ -n "$p" ] && PORT_VD=$p
                ask_uuid "新 VLESS 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_VD=$u
                
                local current_vd_mode_str="关闭 TLS (纯普通直连)"
                [ "$VD_MODE" == "2" ] && current_vd_mode_str="开启 TLS (真实证书: ${VD_DOMAIN:-未配置})"

                echo -e "\n  ${YELLOW}当前 VLESS 模式: ${GREEN}${current_vd_mode_str}${NC}"
                echo -e "  ${YELLOW}请选择新的 VLESS 模式 (直接回车保持不变)：${NC}"
                echo -e "  [1] 关闭 TLS (纯普通直连)"
                echo -e "  [2] 开启 TLS (申请真实域名证书)"
                reading "模式选择 [1-2]" vm
                if [ "$vm" == "2" ]; then
                    reading "请输入已解析到此VPS的真实域名" vd
                    if [ -n "$vd" ]; then
                        if apply_cert "$vd"; then
                            VD_MODE="2"; VD_DOMAIN="$vd"
                        else
                            msg_error "获取失败，放弃修改。"
                        fi
                    else
                        msg_warn "操作取消。"
                    fi
                elif [[ "$vm" == "1" ]]; then VD_MODE="1"; VD_DOMAIN=""; fi
                ;;
            2)
                [ "$ENABLE_RE" != "1" ] && continue
                ask_port "新 Reality 端口 (回车不变)" p; [ -n "$p" ] && PORT_RE=$p
                ask_uuid "新 Reality 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_RE=$u
                reading "伪装 SNI 域名 (当前: $REALITY_SNI)" s; [ -n "$s" ] && REALITY_SNI=$s
                ;;
            3)
                [ "$ENABLE_HY" != "1" ] && continue
                ask_port "新 Hy2 端口 (回车不变)" p; [ -n "$p" ] && PORT_HY=$p
                reading "新密码 (回车不变)" pw; [ -n "$pw" ] && PW_HY=$pw
                
                local current_hop_str
                current_hop_str=$([ "$HY_HOPPING" == "1" ] && echo "已开启 (${HY_PORTS})" || echo "未开启")
                reading "是否开启端口跳跃 (Port Hopping)? [y/n] (默认 n, 当前状态: $current_hop_str)" ph
                ph=${ph,,}
                if [[ "$ph" == "y" ]]; then
                    HY_HOPPING=1
                    ask_port_range "请输入端口段 (例如: 20000-30000)" HY_PORTS "$PORT_HY"
                elif [[ "$ph" == "n" ]]; then
                    HY_HOPPING=0; HY_PORTS=""
                fi
                ;;
            4)
                [ "$ENABLE_TC" != "1" ] && continue
                ask_port "新 TUIC 端口 (回车不变)" p; [ -n "$p" ] && PORT_TC=$p
                ask_uuid "新 TUIC 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_TC=$u
                reading "新密码 (回车不变)" pw; [ -n "$pw" ] && PW_TC=$pw
                ;;
            5)
                [ "$ENABLE_S5" != "1" ] && continue
                ask_port "新 Socks5 端口 (回车不变)" p; [ -n "$p" ] && PORT_S5=$p
                reading "新密码 (回车不变)" pw; [ -n "$pw" ] && S5_P=$pw
                ;;
            6)
                [ "$ENABLE_ARGO" != "1" ] && continue
                ask_uuid "新 Argo 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_ARGO=$u
                reading "[1]=临时隧道(随机域名)  [2]=固定隧道 (直接回车保持不变)" am
                if [ "$am" == "2" ]; then
                    ARGO_MODE="fixed"
                    while true; do reading "请输入绑定的固定域名" d; if [ -n "$d" ]; then ARGO_DOMAIN=$d; break; else msg_error "域名不能为空！"; fi; done
                    while true; do reading "请输入 Cloudflare Token" t; if [ ${#t} -gt 50 ]; then ARGO_TOKEN=$t; break; else msg_error "Token 过短！"; fi; done
                elif [ "$am" == "1" ]; then
                    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
                fi
                ;;
            7)
                echo -e "\n  ${YELLOW}请选择要停用的协议 (释放端口及资源)：${NC}"
                [ "$ENABLE_VD" == "1" ] && echo "  [1] VLESS (WS)"
                [ "$ENABLE_RE" == "1" ] && echo "  [2] Reality"
                [ "$ENABLE_HY" == "1" ] && echo "  [3] Hy2"
                [ "$ENABLE_TC" == "1" ] && echo "  [4] TUIC v5"
                [ "$ENABLE_S5" == "1" ] && echo "  [5] SOCKS5"
                [ "$ENABLE_ARGO" == "1" ] && echo "  [6] Argo 隧道"
                echo "  [0] 取消"
                reading "选择停用目标 [0-6]" disable_choice
                case $disable_choice in
                    1) ENABLE_VD=0 ;; 2) ENABLE_RE=0 ;; 3) ENABLE_HY=0 ;; 4) ENABLE_TC=0 ;; 5) ENABLE_S5=0 ;; 6) ENABLE_ARGO=0 ;; 0) continue ;; *) msg_warn "无效输入"; sleep 1; continue ;;
                esac
                msg_success "目标协议已标记为停用！"
                ;;
            0) break ;;
            *) continue ;;
        esac
        msg_info "正在热重载内核配置..."
        if ! generate_config; then
            msg_error "配置重载失败，请检查日志。"
            sleep 1
            continue
        fi
        setup_services
        msg_success "配置热重载完成！"; sleep 1
    done
}

manage_warp() {
    [ ! -f "$SB_INFO" ] && msg_error "请先进行部署！" && sleep 1 && return
    if is_alpine; then msg_error "Alpine 系统不支持 WARP。"; sleep 2; return; fi
    load_config
    while true; do
        print_logo
        local mode_str="原生直连"
        [ "$WARP_MODE" == "2" ] && mode_str="全局 WARP"
        [ "$WARP_MODE" == "3" ] && mode_str="路由分流"
        [ "$WARP_MODE" == "4" ] && mode_str="原生v6+WARP-v4"

        echo -e "${PURPLE}╭━━━ 🌐 ${BG_BLUE} WARP 智能大脑 ${NC} ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        echo -e "${PURPLE}┃${NC} 当前模式: ${GREEN}$mode_str${NC}"
        [ "$WARP_MODE" == "3" ] && echo -e "${PURPLE}┃${NC} 分流名单: ${YELLOW}${WARP_DOMAINS:-无}${NC}"
        [ "$WARP_MODE" == "3" ] && [ -z "$WARP_DOMAINS" ] && echo -e "${PURPLE}┃${NC} ${RED}⚠ 当前分流模式未指定任何域名，流量将全部直连。${NC}"
        echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        printf '%b\n' "${PURPLE}┃${NC}  [1]\t🔄 切换 WARP 工作模式"
        printf '%b\n' "${PURPLE}┃${NC}  [2]\t➕ 追加目标分流域名"
        printf '%b\n' "${PURPLE}┃${NC}  [3]\t➖ 移除指定分流域名"
        printf '%b\n' "${PURPLE}┃${NC}  [4]\t🗑️ 清空所有分流名单"
        printf '%b\n' "${PURPLE}┃${NC}  [0]\t↩️  返回主菜单"
        echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"

        reading "请选择操作 [0-4]" choice
        case $choice in
            1) echo -e "  ➤ [1]=关闭  [2]=全局WARP  [3]=指定分流  [4]=原生v6+WARP-v4"; reading "选择模式" wm; [ -n "$wm" ] && WARP_MODE=$wm; [[ "$WARP_MODE" == "2" || "$WARP_MODE" == "3" || "$WARP_MODE" == "4" ]] && install_warp ;;
            2) reading "输入要追加的域名 (如 netflix.com)" nd; if [ -n "$nd" ]; then if [ -z "$WARP_DOMAINS" ]; then WARP_DOMAINS="$nd"; else WARP_DOMAINS="$WARP_DOMAINS,$nd"; fi; fi ;;
            3) if [ -z "$WARP_DOMAINS" ]; then msg_warn "无可删除域名！"; sleep 1; continue; fi; reading "输入要移除的域名" rm_d; if [ -n "$rm_d" ]; then IFS=',' read -ra DOMAINS <<< "$WARP_DOMAINS"; local new_arr=""; for d in "${DOMAINS[@]}"; do if [ "$d" != "$rm_d" ] && [ -n "$d" ]; then new_arr+="$d,"; fi; done; WARP_DOMAINS=${new_arr%,}; msg_success "已更新！"; fi ;;
            4) WARP_DOMAINS="" ;;
            0) break ;;
        esac
        generate_config; svc_action restart sing-box; msg_success "WARP 规则已热生效！"; sleep 1
    done
}

show_nodes() {
    print_logo; [ ! -f "$SB_INFO" ] && msg_error "请先部署节点！" && sleep 1 && return
    load_config

    msg_info "正在探测公网 IP (请稍候)..."
    out_ip=$(get_outbound_ip)
    msg_info "正在获取节点物理位置归属地..."
    NODE_PREFIX=$(get_country_prefix)

    if [ -z "$CUSTOM_IP" ]; then
        echo -e " ${BG_BLUE} 网络探针 ${NC} 发现外网 IP: ${GREEN}$out_ip${NC} (${NODE_PREFIX})"
        reading "若需指定入站IP/域名请在此输入 (一致请直接回车)" in_ip
        [ -n "$in_ip" ] && CUSTOM_IP=$in_ip || CUSTOM_IP=$out_ip
        save_config
    fi

    local ip=$CUSTOM_IP
    [[ "$ip" =~ .*:.* ]] && ip="[${ip}]"

    echo -e "\n${CYAN}╭━━━━━━━━━━━━ 🔗 节点订阅凭证 ━━━━━━━━━━━━╮${NC}"
    local all_links=""
    local link_re link1 link2 link3 link4 link5

    if [ "$ENABLE_RE" == "1" ]; then
        echo -e "${CYAN}┃${NC} 🎭 ${GREEN}[VLESS + Reality]${NC} (极致隐蔽直连)"
        link_re="vless://${UUID_RE}@${ip}:${PORT_RE}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PBK}&type=tcp#${NODE_PREFIX}-REALITY"
        echo -e "${CYAN}┃${NC}    ${link_re}"; all_links+="$link_re\n"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS]${NC} (关闭 TLS 纯直连)"
            link1="vless://${UUID_VD}@${ip}:${PORT_VD}?encryption=none&security=none&type=ws&path=%2Fws#${NODE_PREFIX}-VLESS"
        elif [ "$VD_MODE" == "2" ] && [ -n "$VD_DOMAIN" ]; then
            echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS + TLS]${NC} (真实证书: ${VD_DOMAIN})"
            link1="vless://${UUID_VD}@${VD_DOMAIN}:${PORT_VD}?encryption=none&security=tls&sni=${VD_DOMAIN}&type=ws&host=${VD_DOMAIN}&path=%2Fws#${NODE_PREFIX}-VLESS"
        fi
        echo -e "${CYAN}┃${NC}    ${link1}"; all_links+="$link1\n"
    fi

    if [ "$ENABLE_ARGO" == "1" ]; then
        local argo_domain=""
        if [ "$ARGO_MODE" == "temp" ]; then
            for i in $(seq 1 10); do
                [ -f "$ARGO_LOG" ] && argo_domain=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" "$ARGO_LOG" 2>/dev/null | tail -n 1 | sed 's/https:\/\///')
                [ -n "$argo_domain" ] && break
                sleep 2
            done
            [ -n "$argo_domain" ] && argo_type="临时随机隧道"
        elif [ "$ARGO_MODE" == "fixed" ]; then
            argo_domain="$ARGO_DOMAIN"; argo_type="固定专线隧道"
        fi

        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        echo -e "${CYAN}┃${NC} ☁️  ${GREEN}[VLESS + Argo]${NC} (${argo_type:-未就绪})"
        if [ -n "$argo_domain" ]; then
            link2="vless://${UUID_ARGO}@www.visa.com.sg:443?encryption=none&security=tls&sni=${argo_domain}&type=ws&host=${argo_domain}&path=%2Fargo#${NODE_PREFIX}-ARGO"
            echo -e "${CYAN}┃${NC}    ${link2}"; all_links+="$link2\n"
        else echo -e "${CYAN}┃${NC}    ${RED}(未能成功获取隧道域名，请稍后重试或检查日志)${NC}"; fi
    fi

    if [ "$ENABLE_HY" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        local mport_suffix=""
        [ "$HY_HOPPING" == "1" ] && [ -n "$HY_PORTS" ] && mport_suffix="&mport=${HY_PORTS}"
        
        echo -e "${CYAN}┃${NC} 🚀 ${GREEN}[Hysteria 2]${NC} (暴力加速)"
        link3="hysteria2://${PW_HY}@${VD_DOMAIN:-$ip}:${PORT_HY}?sni=${VD_DOMAIN:-bing.com}${mport_suffix}#${NODE_PREFIX}-HY2"
        echo -e "${CYAN}┃${NC}    ${link3}"; all_links+="$link3\n"
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        echo -e "${CYAN}┃${NC} 🏎️  ${GREEN}[TUIC v5]${NC} (QUIC 协议)"
        link4="tuic://${UUID_TC}:${PW_TC}@${VD_DOMAIN:-$ip}:${PORT_TC}?sni=${VD_DOMAIN:-bing.com}&alpn=h3&congestion_control=bbr#${NODE_PREFIX}-TUIC"
        echo -e "${CYAN}┃${NC}    ${link4}"; all_links+="$link4\n"
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        echo -e "${CYAN}┃${NC} 🛡️  ${GREEN}[SOCKS5]${NC} (基础代理)"
        local cred="${S5_U}:${S5_P}" b64_cred
        b64_cred=$(echo -n "$cred" | base64 -w0 2>/dev/null || echo -n "$cred" | base64)
        link5="socks://${b64_cred}@${ip}:${PORT_S5}#${NODE_PREFIX}-SOCKS5"
        echo -e "${CYAN}┃${NC}    ${link5}"; all_links+="$link5\n"
    fi
    echo -e "${CYAN}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"

    echo -e "\n ${BG_BLUE} Base64 订阅 ${NC} 一键复制以下内容导入客户端:"
    echo -e "$all_links" | sed '/^$/d' | base64 -w0
    echo ""
    reading "按回车键 (Enter) 返回主菜单..." dummy
}

uninstall_script() {
    print_logo; echo -e " ${BG_RED} 危险警告 ${NC} ${RED}你正在执行物理毁灭程序！${NC}\n"
    reading "确定要彻底卸载脚本、核心及配置吗？[y/n]" c
    c=${c,,}; if [[ "$c" != "y" ]]; then return; fi

    echo ""; for i in 3 2 1; do echo -e "${YELLOW}将在 $i 秒后开始清理...${NC}"; sleep 1; done

    msg_info "正在清理后台进程与残留文件..."
    svc_action stop sing-box >/dev/null 2>&1; svc_action stop sb-argo >/dev/null 2>&1
    svc_action disable sing-box >/dev/null 2>&1; svc_action disable sb-argo >/dev/null 2>&1

    while iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null; do :; done
    while ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null; do :; done
    while iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null; do :; done
    while ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping-exclude" -j ACCEPT 2>/dev/null; do :; done

    if is_alpine; then rm -f /etc/init.d/sing-box /etc/init.d/sb-argo
    else rm -f /etc/systemd/system/sing-box.service /etc/systemd/system/sb-argo.service; systemctl daemon-reload; fi

    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli disconnect >/dev/null 2>&1
        if command -v apt-get >/dev/null 2>&1; then apt-get remove -y cloudflare-warp >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then yum remove -y cloudflare-warp >/dev/null 2>&1; fi
    fi

    # 清理 sysctl 优化配置
    rm -f /etc/sysctl.d/99-singbox-optimize.conf
    sysctl --system >/dev/null 2>&1 || true

    # 此处已删除 ! -name "sub.txt" 的限制，实现彻底销毁
    find "$SB_DIR" -type f -delete 2>/dev/null
    rm -f "$SB_BIN" "$ARGO_BIN" "/usr/bin/sb"
    msg_success "系统已恢复纯净状态，江湖再见！"; rm -f "$0"; exit 0
}

main_menu() {
    while true; do
        print_logo
        local status="${BG_RED} 休眠中 (未安装) ${NC}"
        [ -f "$SB_INFO" ] && status="${BG_GREEN} 运行中 (已部署) ${NC}"

        echo -e "   系统状态: $status"
        echo -e "   ${CYAN}──────────────────────────────────────────────────${NC}"
        printf '%b\n' "   ${GREEN}[1]${NC}\t🚀 一键快速部署 / 重置引擎"
        printf '%b\n' "   ${GREEN}[2]${NC}\t🛠️ 自定义按需部署 / 重置引擎"
        printf '%b\n' "   ${GREEN}[3]${NC}\t⚙️  单独协议参数管理 (端口/独立UUID/证书/停用)"
        printf '%b\n' "   ${GREEN}[4]${NC}\t🌐 调教 WARP 智能分流规则 (Alpine 系统不支持 WARP)"
        printf '%b\n' "   ${GREEN}[5]${NC}\t🔗 查看提取节点订阅链接"
        echo -e "   ${CYAN}──────────────────────────────────────────────────${NC}"
        # 卸载菜单文字已更新，提示会清理所有数据
        printf '%b\n' "   ${RED}[9]${NC}\t🗑️ 彻底卸载"
        printf '%b\n' "   ${RED}[0]${NC}\t🚪 退出面板"
        echo ""
        reading "请输入指令代码" choice
        case $choice in
            1) install_fast ;; 2) install_custom ;; 3) manage_protocols ;; 4) manage_warp ;;
            5) show_nodes ;; 9) uninstall_script ;; 0) clear; exit 0 ;; *) ;;
        esac
    done
}

main_menu

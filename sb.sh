#!/bin/bash

# ==========================================
# Sing-box 6-in-1
# ==========================================

# --- 扩展视觉与色彩引擎 ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; PURPLE='\033[1;35m'; CYAN='\033[1;36m'; WHITE='\033[1;37m'
BG_RED='\033[41;37;1m'; BG_GREEN='\033[42;37;1m'; BG_BLUE='\033[44;37;1m'; BG_PURPLE='\033[45;37;1m'
BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'

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
SB_DIR="/etc/sing-box"
SB_CONF="${SB_DIR}/config.json"
SB_INFO="${SB_DIR}/install.info"
SB_BIN="/usr/local/bin/sing-box"
ARGO_BIN="/usr/local/bin/cloudflared"
ARGO_LOG="${SB_DIR}/argo.log"
SB_LOG="${SB_DIR}/sing-box.log"

[[ $EUID -ne 0 ]] && msg_error "必须以 root 用户运行此脚本！" && exit 1

# 修复快捷键判定逻辑，精准过滤解释器本身
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

svc_action() {
    local action=$1; local service=$2
    if is_alpine; then
        case $action in
            enable) rc-update add $service default >/dev/null 2>&1 ;;
            disable) rc-update del $service default >/dev/null 2>&1 ;;
            start|stop|restart) rc-service $service $action >/dev/null 2>&1 ;;
            reload) ;;
        esac
    else
        case $action in
            enable) systemctl enable --now $service >/dev/null 2>&1 ;;
            disable) systemctl disable --now $service >/dev/null 2>&1 ;;
            start|stop|restart) systemctl $action $service >/dev/null 2>&1 ;;
            reload) systemctl daemon-reload >/dev/null 2>&1 ;;
        esac
    fi
}

check_port_usage() {
    local port=$1; [ -z "$port" ] && return 0
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :$port >/dev/null 2>&1 && return 1
    fi
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":$port " && return 1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port " && return 1
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
            msg_error "必须是标准的 UUID 格式！(例如: 550e8400-e29b-41d4-a716-446655440000)"
            continue
        fi
        eval "$var_name=\"$temp_input\""
        return
    done
}

# 增加目标端口强包围校验
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
                msg_error "逻辑错误！主端口 ($target_port) 必须包含在你填写的跳跃段 ($p_start-$p_end) 之间，否则节点必定失联 (-1)！"
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
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
}

get_country_prefix() {
    local cc=$(curl -s --max-time 3 http://ip-api.com/line/?fields=countryCode 2>/dev/null)
    [ -z "$cc" ] && cc=$(curl -s --max-time 3 https://ipinfo.io/country 2>/dev/null)
    case "$cc" in
        "CN") echo "🇨🇳中国" ;; "HK") echo "🇭🇰香港" ;; "TW") echo "🇹🇼台湾" ;;
        "MO") echo "🇲🇴澳门" ;; "JP") echo "🇯🇵日本" ;; "KR") echo "🇰🇷韩国" ;;
        "SG") echo "🇸🇬新加坡" ;; "US") echo "🇺🇸美国" ;; "GB") echo "🇬🇧英国" ;;
        "DE") echo "🇩🇪德国" ;; "FR") echo "🇫🇷法国" ;; "NL") echo "🇳🇱荷兰" ;;
        "RU") echo "🇷🇺俄罗斯" ;; "CA") echo "🇨🇦加拿大" ;; "IN") echo "🇮🇳印度" ;;
        "AU") echo "🇦🇺澳大利亚" ;; "BR") echo "🇧🇷巴西" ;; "MY") echo "🇲🇾马来西亚" ;;
        "TH") echo "🇹🇭泰国" ;; "VN") echo "🇻🇳越南" ;; "PH") echo "🇵🇭菲律宾" ;;
        "TR") echo "🇹🇷土耳其" ;; "AR") echo "🇦🇷阿根廷" ;; "ZA") echo "🇿🇦南非" ;;
        "AE") echo "🇦🇪阿联酋" ;; *) echo "🌍未知" ;;
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
    echo ""; msg_info "正在检查并安装基础依赖环境 (包含 iptables)..."
    if is_alpine; then
        apk update >/dev/null 2>&1
        apk add bash curl wget jq openssl lsof socat procps libc6-compat gcompat iptables ip6tables >/dev/null 2>&1
    else
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -y >/dev/null 2>&1
            local apt_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps" "lsb-release" "iptables")
            for pkg in "${apt_pkgs[@]}"; do ! command -v "$pkg" >/dev/null 2>&1 && apt-get install -y "$pkg" >/dev/null 2>&1; done
        elif command -v yum >/dev/null 2>&1; then
            yum makecache -y >/dev/null 2>&1
            yum install -y epel-release >/dev/null 2>&1
            local yum_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps-ng" "redhat-lsb-core" "iptables")
            for pkg in "${yum_pkgs[@]}"; do ! command -v "$pkg" >/dev/null 2>&1 && yum install -y "$pkg" >/dev/null 2>&1; done
        else
            msg_error "不支持的包管理器，请手动安装核心依赖。"
            exit 1
        fi
    fi
    optimize_network
}

safe_download() {
    local url=$1; local dest=$2
    msg_info "正在下载核心组件: $(basename $dest)..."
    local http_code=$(curl -sL -w "%{http_code}" -o "$dest" "$url")
    if [ "$http_code" != "200" ]; then msg_error "文件下载失败！(HTTP: $http_code)"; rm -f "$dest"; return 1; fi
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
        ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
        if [ $? -eq 0 ]; then standalone_success=true; fi
    else msg_warn "80 端口被占用或不可达，跳过 Standalone 模式。"; fi

    if [ "$standalone_success" = false ]; then
        msg_error "Standalone 模式失败，切换至 API 验证模式。"
        reading "是否启用 Cloudflare API 继续申请？[y/n]" use_dns
        use_dns=${use_dns,,}; [ -z "$use_dns" ] && use_dns="y"
        if [[ "$use_dns" != "y" ]]; then msg_error "已取消证书申请。"; return 1; fi

        reading "请输入 Cloudflare API Token" cf_token; export CF_Token="$cf_token"
        reading "请输入域名的 Zone ID" cf_zone_id; export CF_Zone_ID="$cf_zone_id"

        msg_info "API 申请中，请耐心等待 1-2 分钟..."
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d "$domain" -k ec-256 --force
        [ $? -ne 0 ] && { msg_error "证书申请彻底失败！"; return 1; }
    fi

    mkdir -p "${SB_DIR}"
    ~/.acme.sh/acme.sh --installcert -d "$domain" --fullchain-file "${SB_DIR}/server.crt" --key-file "${SB_DIR}/server.key" --ecc >/dev/null 2>&1
    chmod 600 "${SB_DIR}/server.crt" "${SB_DIR}/server.key"
    msg_success "真实域名证书部署成功！"
    return 0
}

install_singbox() {
    if [ ! -f "$SB_BIN" ]; then
        ARCH=$(uname -m); case "${ARCH}" in x86_64) S_ARCH="amd64" ;; aarch64|arm64) S_ARCH="arm64" ;; *) msg_error "不支持的架构"; exit 1 ;; esac
        TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r .tag_name 2>/dev/null)
        if [ -z "$TAG" ] || [ "$TAG" == "null" ]; then
            TAG=$(curl -sL https://github.com/SagerNet/sing-box/releases/latest | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | head -n 1)
            [ -z "$TAG" ] && TAG="v1.9.3"
            msg_warn "触发 Github API 限制，已启用备用解析获取版本: $TAG"
        fi
        if safe_download "https://github.com/SagerNet/sing-box/releases/download/${TAG}/sing-box-${TAG#v}-linux-${S_ARCH}.tar.gz" "sb.tar.gz"; then
            tar -xzf sb.tar.gz || { msg_error "解压失败"; exit 1; }
            mv sing-box-*/sing-box "$SB_BIN"; rm -rf sb.tar.gz sing-box-*
            chmod +x "$SB_BIN"
        else exit 1; fi
    fi
}

install_argo() {
    if [ ! -f "$ARGO_BIN" ]; then
        ARCH=$(uname -m); case "${ARCH}" in x86_64) A_ARCH="amd64" ;; aarch64|arm64) A_ARCH="arm64" ;; esac
        if safe_download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${A_ARCH}" "$ARGO_BIN"; then
            chmod +x "$ARGO_BIN"
        fi
    fi
}

install_warp() {
    if is_alpine; then return; fi
    if ! command -v warp-cli >/dev/null 2>&1; then
        msg_info "正在安装 Cloudflare WARP..."
        if command -v apt-get >/dev/null 2>&1; then
            curl -fsSl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
            local dist_codename=""
            if command -v lsb_release >/dev/null 2>&1; then dist_codename=$(lsb_release -cs)
            else dist_codename=$(grep '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d'=' -f2); [ -z "$dist_codename" ] && dist_codename="stable"; fi
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $dist_codename main" | tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null
            apt-get update -y >/dev/null 2>&1 && apt-get install -y cloudflare-warp >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then msg_error "WARP 不支持 yum 系系统，请手动安装或使用 apt 系统。"; return 1
        else msg_error "无法安装 WARP：不支持当前包管理器。"; return 1; fi
    fi
    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli --accept-tos registration new >/dev/null 2>&1; warp-cli --accept-tos mode proxy >/dev/null 2>&1
        warp-cli --accept-tos proxy port 40000 >/dev/null 2>&1; warp-cli --accept-tos connect >/dev/null 2>&1
    fi
}

generate_config() {
    mkdir -p "$SB_DIR"

    if [[ "$VD_MODE" != "3" ]] && [[ ! -f "${SB_DIR}/server.crt" ]]; then
        openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "${SB_DIR}/server.key" -out "${SB_DIR}/server.crt" -subj "/CN=bing.com" -days 3650 >/dev/null 2>&1
        chmod 600 "${SB_DIR}/server.key" "${SB_DIR}/server.crt"
    fi

    local rules_json='{"outbound": "direct-out"}'
    if [ "$WARP_MODE" == "2" ] && ! is_alpine; then rules_json='{"outbound": "warp-out"}'
    elif [ "$WARP_MODE" == "3" ] && ! is_alpine && [ -n "$WARP_DOMAINS" ]; then
        IFS=',' read -ra DOMAINS <<< "$WARP_DOMAINS"; local domain_array=""
        for d in "${DOMAINS[@]}"; do [ -n "$d" ] && domain_array+="\"$d\","; done
        domain_array=${domain_array%,}
        [ -n "$domain_array" ] && rules_json="{ \"domain_suffix\": [${domain_array}], \"outbound\": \"warp-out\" }, { \"outbound\": \"direct-out\" }"
    fi

    local INBOUNDS=""

    if [ "$ENABLE_ARGO" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-argo\", \"listen\": \"127.0.0.1\", \"listen_port\": 10086, \"users\": [ { \"uuid\": \"$UUID_ARGO\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/argo\" } },"
    fi

    if [ "$ENABLE_RE" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-reality\", \"listen\": \"::\", \"listen_port\": $PORT_RE, \"users\": [ { \"uuid\": \"$UUID_RE\", \"flow\": \"xtls-rprx-vision\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$REALITY_SNI\", \"reality\": { \"enabled\": true, \"handshake\": { \"server\": \"$REALITY_SNI\", \"server_port\": 443 }, \"private_key\": \"$REALITY_PRK\", \"short_id\": [ \"$REALITY_SHORT_ID\" ] } } },"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        elif [ "$VD_MODE" == "3" ] && [ -n "$VD_DOMAIN" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$VD_DOMAIN\", \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        else
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
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
    "servers": [ { "tag": "dns-remote", "type": "udp", "server": "1.1.1.1" } ],
    "final": "dns-remote",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    $INBOUNDS
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct-out" },
    { "type": "socks", "tag": "warp-out", "server": "127.0.0.1", "server_port": 40000 },
    { "type": "block", "tag": "block-out" }
  ],
  "route": { "rules": [ $rules_json ], "auto_detect_interface": true, "final": "direct-out" }
}
EOF
    save_config
}

# --- 防火墙端口跳跃模块 ---
apply_iptables() {
    iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null || true
    ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null || true

    if [ "$ENABLE_HY" == "1" ] && [ "$HY_HOPPING" == "1" ] && [ -n "$HY_PORTS" ]; then
        local start_port=$(echo $HY_PORTS | cut -d'-' -f1)
        local end_port=$(echo $HY_PORTS | cut -d'-' -f2)
        iptables -t nat -A PREROUTING -p udp --dport $start_port:$end_port -m comment --comment "hy2-hopping" -j REDIRECT --to-ports $PORT_HY 2>/dev/null
        ip6tables -t nat -A PREROUTING -p udp --dport $start_port:$end_port -m comment --comment "hy2-hopping" -j REDIRECT --to-ports $PORT_HY 2>/dev/null
    fi
}

setup_services() {
    apply_iptables

    local ARGO_CMD="$ARGO_BIN tunnel --url http://127.0.0.1:10086 --no-autoupdate --edge-ip-version auto"
    if [ "$ARGO_MODE" == "fixed" ] && [ -n "$ARGO_TOKEN" ]; then
        ARGO_CMD="$ARGO_BIN tunnel run --token ${ARGO_TOKEN}"
    fi

    if is_alpine; then
        cat > /etc/init.d/sing-box << EOF
#!/sbin/openrc-run
command="$SB_BIN"
command_args="run -c $SB_CONF"
command_background=true
pidfile="/var/run/sing-box.pid"
output_log="/var/log/sing-box.log"
error_log="/var/log/sing-box.log"
EOF
        cat > /etc/init.d/sb-argo << EOF
#!/sbin/openrc-run
command="$ARGO_BIN"
command_args="tunnel --url http://127.0.0.1:10086 --no-autoupdate --edge-ip-version auto"
command_background=true
pidfile="/var/run/sb-argo.pid"
output_log="/var/log/sb-argo.log"
error_log="/var/log/sb-argo.log"
EOF
        if [ "$ARGO_MODE" == "fixed" ] && [ -n "$ARGO_TOKEN" ]; then
            cat > /etc/init.d/sb-argo << EOF
#!/sbin/openrc-run
command="$ARGO_BIN"
command_args="tunnel run --token $ARGO_TOKEN"
command_background=true
pidfile="/var/run/sb-argo.pid"
output_log="/var/log/sb-argo.log"
error_log="/var/log/sb-argo.log"
EOF
        fi
        chmod +x /etc/init.d/sing-box /etc/init.d/sb-argo
    else
        cat > /etc/systemd/system/sing-box.service << EOF
[Unit]
Description=Sing-box Core Service
After=network.target
[Service]
ExecStart=$SB_BIN run -c $SB_CONF
Restart=always
RestartSec=3
StartLimitInterval=0
LimitNOFILE=1048576
WorkingDirectory=$SB_DIR
StandardOutput=append:$SB_LOG
StandardError=append:$SB_LOG
[Install]
WantedBy=multi-user.target
EOF
        if [ "$ARGO_MODE" == "temp" ] || [ -z "$ARGO_TOKEN" ]; then
            cat > /etc/systemd/system/sb-argo.service << EOF
[Unit]
Description=Argo Tunnel for Sing-box
After=network.target
[Service]
ExecStart=$ARGO_BIN tunnel --url http://127.0.0.1:10086 --no-autoupdate --edge-ip-version auto
Restart=always
RestartSec=3
StartLimitInterval=0
WorkingDirectory=$SB_DIR
StandardOutput=append:$ARGO_LOG
StandardError=append:$ARGO_LOG
[Install]
WantedBy=multi-user.target
EOF
        else
            cat > /etc/systemd/system/sb-argo.service << EOF
[Unit]
Description=Argo Tunnel for Sing-box
After=network.target
[Service]
ExecStart=$ARGO_BIN tunnel run --token $ARGO_TOKEN
Restart=always
RestartSec=3
StartLimitInterval=0
WorkingDirectory=$SB_DIR
StandardOutput=append:$ARGO_LOG
StandardError=append:$ARGO_LOG
[Install]
WantedBy=multi-user.target
EOF
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
        confirm=${confirm,,}
        if [[ "$confirm" != "y" ]]; then return 1; fi
        find "$SB_DIR" -type f ! -name "server.crt" ! -name "server.key" -delete 2>/dev/null
    fi
    return 0
}

# --- 一键极速部署 ---
install_fast() {
    print_logo
    echo -e "${BG_PURPLE} 一键极速部署 ${NC} ${YELLOW}开始部署全协议...${NC}\n"
    check_existing || return

    install_deps; install_singbox; install_argo

    UUID_VD=$(cat /proc/sys/kernel/random/uuid)
    UUID_RE=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid)
    UUID_TC=$(cat /proc/sys/kernel/random/uuid)
    
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    S5_U="user"; S5_P=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)

    ENABLE_VD=1; ENABLE_RE=1; ENABLE_HY=1; ENABLE_TC=1; ENABLE_S5=1; ENABLE_ARGO=1

    msg_info "正在自动分配系统可用端口..."
    PORT_VD=$(get_random_port); PORT_RE=$(get_random_port); PORT_HY=$(get_random_port)
    PORT_TC=$(get_random_port); PORT_S5=$(get_random_port)

    msg_info "正在生成 Reality 专属密钥对..."
    local keys=$($SB_BIN generate reality-keypair)
    REALITY_PRK=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
    REALITY_PBK=$(echo "$keys" | awk '/PublicKey/ {print $2}')
    REALITY_SHORT_ID=$(openssl rand -hex 8)
    REALITY_SNI="www.microsoft.com"

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"; VD_DOMAIN=""
    HY_HOPPING="0"; HY_PORTS=""

    msg_info "正在写入底层架构并启动守护进程..."
    generate_config; setup_services
    echo ""; msg_success "一键部署已完成！"
    sleep 2
}

# --- 自定义按需部署 ---
install_custom() {
    print_logo
    echo -e "${BG_PURPLE} 自定义部署 ${NC} ${YELLOW}进入按需部署模式...${NC}\n"
    check_existing || return

    install_deps; install_singbox; install_argo

    UUID_VD=$(cat /proc/sys/kernel/random/uuid)
    UUID_RE=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid)
    UUID_TC=$(cat /proc/sys/kernel/random/uuid)
    
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
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
        ask_port "VLESS (WS) 外网端口 (回车随机)" PORT_VD; [ -z "$PORT_VD" ] && PORT_VD=$(get_random_port)
    fi
    if [ "$ENABLE_RE" == "1" ]; then
        ask_port "Reality 外网端口 (建议443，回车随机)" PORT_RE; [ -z "$PORT_RE" ] && PORT_RE=$(get_random_port)
        msg_info "正在生成 Reality 密钥对..."
        local keys=$($SB_BIN generate reality-keypair)
        REALITY_PRK=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
        REALITY_PBK=$(echo "$keys" | awk '/PublicKey/ {print $2}')
        REALITY_SHORT_ID=$(openssl rand -hex 8)
        REALITY_SNI="www.microsoft.com"
    fi
    if [ "$ENABLE_HY" == "1" ]; then
        ask_port "Hysteria2 外网端口 (回车随机)" PORT_HY; [ -z "$PORT_HY" ] && PORT_HY=$(get_random_port)
        reading "是否开启端口跳跃 (Port Hopping)? [y/n] (默认 n)" ph
        if [[ "${ph,,}" == "y" ]]; then
            HY_HOPPING=1
            ask_port_range "请输入连续跳跃端口段 (例如: 20000-30000)" HY_PORTS "$PORT_HY"
        else HY_HOPPING=0; HY_PORTS=""; fi
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        ask_port "TUIC 外网端口 (回车随机)" PORT_TC; [ -z "$PORT_TC" ] && PORT_TC=$(get_random_port)
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        ask_port "SOCKS5 外网端口 (回车随机)" PORT_S5; [ -z "$PORT_S5" ] && PORT_S5=$(get_random_port)
    fi

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"; VD_DOMAIN=""

    echo ""; msg_info "正在写入底层架构并启动守护进程..."
    generate_config; setup_services
    echo ""; msg_success "自定义部署已完成！"
    sleep 2
}

manage_protocols() {
    [ ! -f "$SB_INFO" ] && msg_error "请先进行部署！" && sleep 1 && return
    load_config
    while true; do
        print_logo
        echo -e "${PURPLE}╭━━━ ⚙️ ${BG_BLUE} 协议精细化管理 ${NC} ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        [ "$ENABLE_VD" == "1" ] && printf "${PURPLE}┃${NC}  [1]\t⚡ 修改 VLESS (WS)   ${YELLOW}(端口: $PORT_VD)${NC}\n"
        [ "$ENABLE_RE" == "1" ] && printf "${PURPLE}┃${NC}  [2]\t🎭 修改 Reality      ${YELLOW}(端口: $PORT_RE)${NC}\n"
        [ "$ENABLE_HY" == "1" ] && printf "${PURPLE}┃${NC}  [3]\t🚀 修改 Hy2          ${YELLOW}(端口: $PORT_HY)${NC}\n"
        [ "$ENABLE_TC" == "1" ] && printf "${PURPLE}┃${NC}  [4]\t🏎️ 修改 TUIC v5      ${YELLOW}(端口: $PORT_TC)${NC}\n"
        [ "$ENABLE_S5" == "1" ] && printf "${PURPLE}┃${NC}  [5]\t🛡️ 修改 SOCKS5       ${YELLOW}(端口: $PORT_S5)${NC}\n"
        [ "$ENABLE_ARGO" == "1" ] && printf "${PURPLE}┃${NC}  [6]\t☁️  配置 Argo 隧道    ${YELLOW}(模式: $ARGO_MODE)${NC}\n"
        echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        printf "${PURPLE}┃${NC}  ${RED}[7]\t🛑 停用/卸载单独协议${NC}\n"
        printf "${PURPLE}┃${NC}  [0]\t↩️  返回主菜单${NC}\n"
        echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
        reading "请选择操作 [0-7]" choice
        case $choice in
            1)
                [ "$ENABLE_VD" != "1" ] && continue
                ask_port "新 VLESS 端口 (回车不变)" p; [ -n "$p" ] && PORT_VD=$p
                ask_uuid "新 VLESS 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_VD=$u
                
                local current_vd_mode_str="关闭 TLS (纯普通直连)"
                [ "$VD_MODE" == "2" ] && current_vd_mode_str="开启 TLS (自签伪装证书)"
                [ "$VD_MODE" == "3" ] && current_vd_mode_str="开启 TLS (真实域名证书: $VD_DOMAIN)"

                echo -e "\n  ${YELLOW}当前 VLESS 模式: ${GREEN}${current_vd_mode_str}${NC}"
                echo -e "  ${YELLOW}请选择新的 VLESS 模式 (直接回车保持不变)：${NC}"
                echo -e "  [1] 关闭 TLS (纯普通直连)"
                echo -e "  [2] 开启 TLS (自签伪装证书)"
                echo -e "  [3] 开启 TLS (申请真实域名证书)"
                reading "模式选择 [1-3]" vm
                if [ "$vm" == "3" ]; then
                    reading "请输入已解析到此VPS的真实域名" vd
                    if [ -n "$vd" ]; then apply_cert "$vd"; if [ $? -eq 0 ]; then VD_MODE="3"; VD_DOMAIN="$vd"; else msg_error "获取失败，放弃修改。"; fi; else msg_warn "操作取消。"; fi
                elif [[ "$vm" == "1" || "$vm" == "2" ]]; then VD_MODE=$vm; VD_DOMAIN=""; fi
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
                
                local current_hop_str=$([ "$HY_HOPPING" == "1" ] && echo "已开启 (${HY_PORTS})" || echo "未开启")
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
        generate_config; setup_services
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

        echo -e "${PURPLE}╭━━━ 🌐 ${BG_BLUE} WARP 智能大脑 ${NC} ${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
        echo -e "${PURPLE}┃${NC} 当前模式: ${GREEN}$mode_str${NC}"
        [ "$WARP_MODE" == "3" ] && echo -e "${PURPLE}┃${NC} 分流名单: ${YELLOW}${WARP_DOMAINS:-无}${NC}"
        [ "$WARP_MODE" == "3" ] && [ -z "$WARP_DOMAINS" ] && echo -e "${PURPLE}┃${NC} ${RED}⚠ 当前分流模式未指定任何域名，流量将全部直连。${NC}"
        echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        printf "${PURPLE}┃${NC}  [1]\t🔄 切换 WARP 工作模式\n"
        printf "${PURPLE}┃${NC}  [2]\t➕ 追加目标分流域名\n"
        printf "${PURPLE}┃${NC}  [3]\t➖ 移除指定分流域名\n"
        printf "${PURPLE}┃${NC}  [4]\t🗑️ 清空所有分流名单\n"
        printf "${PURPLE}┃${NC}  [0]\t↩️  返回主菜单\n"
        echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"

        reading "请选择操作 [0-4]" choice
        case $choice in
            1) echo -e "  ➤ [1]=关闭  [2]=全局WARP  [3]=指定分流"; reading "选择模式" wm; [ -n "$wm" ] && WARP_MODE=$wm; [[ "$WARP_MODE" == "2" || "$WARP_MODE" == "3" ]] && install_warp ;;
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

    if [ "$ENABLE_RE" == "1" ]; then
        echo -e "${CYAN}┃${NC} 🎭 ${GREEN}[VLESS + Reality]${NC} (极致隐蔽直连)"
        link_re="vless://${UUID_RE}@${ip}:${PORT_RE}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PBK}&sid=${REALITY_SHORT_ID}&type=tcp#${NODE_PREFIX}-REALITY"
        echo -e "${CYAN}┃${NC}    ${link_re}"; all_links+="$link_re\n"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS]${NC} (关闭 TLS 纯直连)"
            link1="vless://${UUID_VD}@${ip}:${PORT_VD}?encryption=none&security=none&type=ws&path=%2Fws#${NODE_PREFIX}-VLESS"
        elif [ "$VD_MODE" == "3" ] && [ -n "$VD_DOMAIN" ]; then
            echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS + TLS]${NC} (真实证书: ${VD_DOMAIN})"
            link1="vless://${UUID_VD}@${VD_DOMAIN}:${PORT_VD}?encryption=none&security=tls&sni=${VD_DOMAIN}&type=ws&host=${VD_DOMAIN}&path=%2Fws#${NODE_PREFIX}-VLESS"
        else
            echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS + TLS]${NC} (自签伪装证书)"
            link1="vless://${UUID_VD}@${ip}:${PORT_VD}?encryption=none&security=tls&sni=bing.com&alpn=http%2F1.1&type=ws&host=bing.com&path=%2Fws&allowInsecure=1#${NODE_PREFIX}-VLESS"
        fi
        echo -e "${CYAN}┃${NC}    ${link1}"; all_links+="$link1\n"
    fi

    if [ "$ENABLE_ARGO" == "1" ]; then
        local argo_domain=""
        if [ "$ARGO_MODE" == "temp" ]; then
            for i in {1..10}; do
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
            link2="vless://${UUID_ARGO}@www.visa.com.sg:443?encryption=none&security=tls&sni=${argo_domain}&type=ws&host=${argo_domain}&path=%2Fargo&allowInsecure=1#${NODE_PREFIX}-ARGO"
            echo -e "${CYAN}┃${NC}    ${link2}"; all_links+="$link2\n"
        else echo -e "${CYAN}┃${NC}    ${RED}(未能成功获取隧道域名，请稍后重试或检查日志)${NC}"; fi
    fi

    if [ "$ENABLE_HY" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        local mport_suffix=""
        [ "$HY_HOPPING" == "1" ] && [ -n "$HY_PORTS" ] && mport_suffix="&mport=${HY_PORTS}"
        
        echo -e "${CYAN}┃${NC} 🚀 ${GREEN}[Hysteria 2]${NC} (暴力加速)"
        link3="hysteria2://${PW_HY}@${ip}:${PORT_HY}?insecure=1&sni=bing.com${mport_suffix}#${NODE_PREFIX}-HY2"
        echo -e "${CYAN}┃${NC}    ${link3}"; all_links+="$link3\n"
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        echo -e "${CYAN}┃${NC} 🏎️  ${GREEN}[TUIC v5]${NC} (QUIC 协议)"
        link4="tuic://${UUID_TC}:${PW_TC}@${ip}:${PORT_TC}?sni=bing.com&alpn=h3&congestion_control=bbr&allow_insecure=1#${NODE_PREFIX}-TUIC"
        echo -e "${CYAN}┃${NC}    ${link4}"; all_links+="$link4\n"
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        echo -e "${CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        echo -e "${CYAN}┃${NC} 🛡️  ${GREEN}[SOCKS5]${NC} (基础代理)"
        local cred="${S5_U}:${S5_P}"; local b64_cred=$(echo -n "$cred" | base64 -w0)
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

    iptables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null || true
    ip6tables -t nat -D PREROUTING -p udp -m comment --comment "hy2-hopping" -j REDIRECT 2>/dev/null || true

    if is_alpine; then rm -f /etc/init.d/sing-box /etc/init.d/sb-argo
    else rm -f /etc/systemd/system/sing-box.service /etc/systemd/system/sb-argo.service; systemctl daemon-reload; fi

    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli disconnect >/dev/null 2>&1
        if command -v apt-get >/dev/null 2>&1; then apt-get remove -y cloudflare-warp >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then yum remove -y cloudflare-warp >/dev/null 2>&1; fi
    fi

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
        printf "   ${GREEN}[1]${NC}\t🚀 一键快速部署 / 重置引擎\n"
        printf "   ${GREEN}[2]${NC}\t🛠️ 自定义按需部署 / 重置引擎\n"
        printf "   ${GREEN}[3]${NC}\t⚙️  单独协议参数管理 (端口/独立UUID/证书/停用)\n"
        printf "   ${GREEN}[4]${NC}\t🌐 调教 WARP 智能分流规则 (Alpine 系统不支持 WARP)\n"
        printf "   ${GREEN}[5]${NC}\t🔗 查看提取节点订阅链接\n"
        echo -e "   ${CYAN}──────────────────────────────────────────────────${NC}"
        printf "   ${RED}[9]${NC}\t🗑️ 彻底卸载\n"
        printf "   ${RED}[0]${NC}\t🚪 安全退出面板\n"
        echo ""
        reading "请输入指令代码" choice
        case $choice in
            1) install_fast ;; 2) install_custom ;; 3) manage_protocols ;; 4) manage_warp ;;
            5) show_nodes ;; 9) uninstall_script ;; 0) clear; exit 0 ;; *) ;;
        esac
    done
}

main_menu

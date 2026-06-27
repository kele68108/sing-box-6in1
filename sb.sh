#!/bin/bash

# ==========================================
# Sing-box VLESS + WS + Argo 稳定架构
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
    echo -e "${PURPLE}┃${NC}      ${YELLOW}${BOLD}✨ Kele's Sing-box VLESS + Argo 稳定架构 (TLS 强制版) ✨${NC}    ${PURPLE}┃${NC}"
    echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
    echo ""
}

# --- 全局变量 ---
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

url_encode() {
    local s="$1"; local result=""; local i c
    for ((i=0; i<${#s}; i++)); do
        c="${s:$i:1}"
        if [[ "$c" =~ ^[a-zA-Z0-9_.~%-\[\]]+$ ]]; then result+="$c"
        else result+=$(printf '%%%02X' "'$c"); fi
    done
    printf '%s' "$result"
}

systemd_supports_append() {
    if command -v systemctl >/dev/null 2>&1; then
        local ver
        ver=$(systemd --version 2>/dev/null | head -n1 | grep -oE '[0-9]+' | head -n1)
        if [ -n "$ver" ] && [ "$ver" -ge 240 ]; then return 0; fi
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
    fi
fi

load_config() {
    [ -f "$SB_INFO" ] && source "$SB_INFO"
    [ -z "$VD_DOMAIN" ] && VD_DOMAIN=""
    [ -z "$ENABLE_VD" ] && ENABLE_VD="1"
    [ -z "$ENABLE_ARGO" ] && ENABLE_ARGO="1"
}

save_config() {
    cat > "$SB_INFO" << EOF
UUID_VD=$UUID_VD
UUID_ARGO=$UUID_ARGO
PORT_VD=$PORT_VD
WARP_MODE=$WARP_MODE
WARP_DOMAINS=$WARP_DOMAINS
CUSTOM_IP=$CUSTOM_IP
ARGO_MODE=$ARGO_MODE
ARGO_TOKEN=$ARGO_TOKEN
ARGO_DOMAIN=$ARGO_DOMAIN
VD_DOMAIN=$VD_DOMAIN
ENABLE_VD=$ENABLE_VD
ENABLE_ARGO=$ENABLE_ARGO
EOF
    chmod 600 "$SB_INFO"
}

is_alpine() { [ -f /etc/alpine-release ]; }

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
    fi
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -qE ":[0-9]*$port\>" && return 1
    fi
    return 0
}

get_random_port() {
    local port
    while true; do
        port=$(( ((RANDOM << 15) | RANDOM) % 50000 + 10000 ))
        if check_port_usage "$port"; then echo "$port"; return 0; fi
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
        eval "$var_name=\"$temp_input\""; return
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
        eval "$var_name=\"$temp_input\""; return
    done
}

get_outbound_ip() {
    local ip=""
    for i in 1 2 3; do
        ip=$(curl -s4 --max-time 5 https://api.ipify.org 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s4 --max-time 5 https://ifconfig.me/ip 2>/dev/null); [ -n "$ip" ] && break
        ip=$(curl -s6 --max-time 5 https://api6.ipify.org 2>/dev/null); [ -n "$ip" ] && break
        sleep 1
    done
    if [ -z "$ip" ]; then
        msg_error "无法自动探测公网IP，请确保网络连通或手动指定IP/域名。"
        echo "127.0.0.1"; return 1
    fi
    echo "$ip"; return 0
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
    echo ""; msg_info "正在检查并安装基础依赖环境..."
    if is_alpine; then
        apk update >/dev/null 2>&1
        apk add bash curl wget jq openssl lsof socat procps libc6-compat gcompat >/dev/null 2>&1
    else
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -y >/dev/null 2>&1
            local apt_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps" "lsb-release")
            for pkg in "${apt_pkgs[@]}"; do
                local cmd_name="$pkg"
                [ "$pkg" = "lsb-release" ] && cmd_name="lsb_release"
                ! command -v "$cmd_name" >/dev/null 2>&1 && apt-get install -y "$pkg" >/dev/null 2>&1
            done
        elif command -v yum >/dev/null 2>&1; then
            yum makecache -y >/dev/null 2>&1
            yum install -y epel-release >/dev/null 2>&1
            local yum_pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat" "procps-ng" "redhat-lsb-core")
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
        # 强制拉取最新正式版 (Latest Stable)
        TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r '.tag_name' 2>/dev/null)
        if [ -z "$TAG" ] || [ "$TAG" == "null" ]; then TAG="v1.9.3"; fi
        
        msg_info "正在下载 sing-box ${TAG} (最新正式版)..."
        if safe_download "https://github.com/SagerNet/sing-box/releases/download/${TAG}/sing-box-${TAG#v}-linux-${S_ARCH}.tar.gz" "sb.tar.gz"; then
            tar -xzf sb.tar.gz || { msg_error "解压失败"; exit 1; }
            mv sing-box-*/sing-box "$SB_BIN"; rm -rf sb.tar.gz sing-box-*
            chmod +x "$SB_BIN"
        else exit 1; fi
    fi
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

install_warp() {
    if is_alpine; then return; fi
    if ! command -v warp-cli >/dev/null 2>&1; then
        msg_info "正在安装 Cloudflare WARP..."
        if command -v apt-get >/dev/null 2>&1; then
            mkdir -p /usr/share/keyrings
            curl -fsSl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
            local dist_codename=""
            if command -v lsb_release >/dev/null 2>&1; then dist_codename=$(lsb_release -cs)
            else dist_codename=$(grep '^VERSION_CODENAME=' /etc/os-release 2>/dev/null | cut -d'=' -f2); [ -z "$dist_codename" ] && dist_codename="stable"; fi
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $dist_codename main" | tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null
            apt-get update -y >/dev/null 2>&1 && apt-get install -y cloudflare-warp >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then msg_error "WARP 不支持 yum 系系统。"; return 1
        else return 1; fi
    fi
    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli --accept-tos registration new >/dev/null 2>&1; warp-cli --accept-tos mode proxy >/dev/null 2>&1
        warp-cli --accept-tos proxy port 40000 >/dev/null 2>&1; warp-cli --accept-tos connect >/dev/null 2>&1
    fi
}

generate_config() {
    mkdir -p "$SB_DIR"
    VD_DOMAIN="${VD_DOMAIN//\\/}"; VD_DOMAIN="${VD_DOMAIN//\"/}"
    WARP_DOMAINS="${WARP_DOMAINS//\\/}"; WARP_DOMAINS="${WARP_DOMAINS//\"/}"

    if [[ "$ENABLE_VD" == "1" ]] && [[ ! -f "${SB_DIR}/server.crt" ]]; then
        msg_error "致命错误: 未找到域名 ${VD_DOMAIN} 的证书。"
        msg_error "各大客户端已弃用不安全直连模式，请确保成功申请证书后再继续。"
        return 1
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

    if [ "$ENABLE_VD" == "1" ] && [ -n "$VD_DOMAIN" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID_VD\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$VD_DOMAIN\", \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
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

setup_services() {
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
    echo -e "${BG_PURPLE} 一键极速部署 ${NC} ${YELLOW}开始自动化部署...${NC}\n"
    check_existing || return

    install_deps; install_singbox; install_argo

    UUID_VD=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid)
    ENABLE_VD=1; ENABLE_ARGO=1

    msg_info "正在自动分配系统可用端口..."
    PORT_VD=$(get_random_port)

    # 强制域名和证书申请环节
    while true; do
        echo -e "\n${BG_RED} 安全策略强制要求 ${NC} 为了兼容新版客户端，必须配置真实 TLS 证书。"
        reading "请填入已解析到本机 IP 的域名 (必填):" domain_input
        if [ -n "$domain_input" ]; then
            if apply_cert "$domain_input"; then
                VD_DOMAIN="$domain_input"
                break
            else
                msg_error "证书申请失败！请检查域名解析是否生效，或更换域名后重试。"
                exit 1
            fi
        else
            msg_error "域名不能为空，部署已强制中断！"
        fi
    done

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""

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

    UUID_VD=$(cat /proc/sys/kernel/random/uuid)
    UUID_ARGO=$(cat /proc/sys/kernel/random/uuid)

    echo -e "${BG_BLUE} 协议开关 ${NC}"
    ENABLE_VD=1 # 核心节点强制开启
    reading "启用 Argo 隧道 [y/n] (默认 y)" c_ar; c_ar=${c_ar,,}; [ -z "$c_ar" ] && c_ar="y"; ENABLE_ARGO=$([[ "$c_ar" == "y" ]] && echo 1 || echo 0)

    echo -e "\n${BG_BLUE} 端口与参数分配 ${NC}"
    ask_port "VLESS (WS+TLS) 外网端口 (回车随机)" PORT_VD
    if [ -z "$PORT_VD" ]; then PORT_VD=$(get_random_port); echo -e "  ${CYAN}➤ 自动分配 VLESS 端口: ${GREEN}$PORT_VD${NC}"; fi

    # 强制域名和证书申请环节
    while true; do
        echo -e "\n${BG_RED} 安全策略强制要求 ${NC} 为了兼容新版客户端，必须配置真实 TLS 证书。"
        reading "请填入已解析到本机 IP 的域名 (必填):" domain_input
        if [ -n "$domain_input" ]; then
            if apply_cert "$domain_input"; then
                VD_DOMAIN="$domain_input"
                break
            else
                msg_error "证书申请失败！请检查域名解析是否生效，或更换域名后重试。"
                exit 1
            fi
        else
            msg_error "域名不能为空，部署已强制中断！"
        fi
    done

    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""

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
        [ "$ENABLE_VD" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [1]\t⚡ 修改 VLESS (WS+TLS) ${YELLOW}(端口: $PORT_VD)${NC}"
        [ "$ENABLE_ARGO" == "1" ] && printf '%b\n' "${PURPLE}┃${NC}  [2]\t☁️  配置 Argo 隧道     ${YELLOW}(模式: $ARGO_MODE)${NC}"
        echo -e "${PURPLE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
        printf '%b\n' "${PURPLE}┃${NC}  [0]\t↩️  返回主菜单${NC}"
        echo -e "${PURPLE}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
        reading "请选择操作 [0-2]" choice
        case $choice in
            1)
                [ "$ENABLE_VD" != "1" ] && continue
                ask_port "新 VLESS 端口 (回车不变)" p; [ -n "$p" ] && PORT_VD=$p
                ask_uuid "新 VLESS 独立 UUID (回车不变)" u; [ -n "$u" ] && UUID_VD=$u
                
                echo -e "\n  ${YELLOW}当前绑定的真实域名: ${GREEN}${VD_DOMAIN}${NC}"
                reading "是否需要更换域名并重新申请证书? [y/n] (默认 n)" c_cert
                if [[ "${c_cert,,}" == "y" ]]; then
                    reading "请输入已解析到此VPS的新真实域名" vd
                    if [ -n "$vd" ]; then
                        if apply_cert "$vd"; then VD_DOMAIN="$vd"
                        else msg_error "证书获取失败，域名未更改。"; fi
                    fi
                fi
                ;;
            2)
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

    msg_info "正在获取节点物理位置归属地..."
    NODE_PREFIX=$(get_country_prefix)

    echo -e "\n${CYAN}╭━━━━━━━━━━━━ 🔗 节点订阅凭证 ━━━━━━━━━━━━╮${NC}"
    local all_links=""
    local link1 link2

    if [ "$ENABLE_VD" == "1" ] && [ -n "$VD_DOMAIN" ]; then
        echo -e "${CYAN}┃${NC} ⚡ ${GREEN}[VLESS + WS + TLS]${NC} (已部署真实证书: ${VD_DOMAIN})"
        # 移除了所有不安全的 allowInsecure 标识
        link1="vless://${UUID_VD}@${VD_DOMAIN}:${PORT_VD}?encryption=none&security=tls&sni=${VD_DOMAIN}&type=ws&host=${VD_DOMAIN}&path=%2Fws#${NODE_PREFIX}-VLESS"
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

    if is_alpine; then rm -f /etc/init.d/sing-box /etc/init.d/sb-argo
    else rm -f /etc/systemd/system/sing-box.service /etc/systemd/system/sb-argo.service; systemctl daemon-reload; fi

    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli disconnect >/dev/null 2>&1
        if command -v apt-get >/dev/null 2>&1; then apt-get remove -y cloudflare-warp >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then yum remove -y cloudflare-warp >/dev/null 2>&1; fi
    fi

    rm -f /etc/sysctl.d/99-singbox-optimize.conf
    sysctl --system >/dev/null 2>&1 || true

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
        printf '%b\n' "   ${GREEN}[1]${NC}\t🚀 一键极速部署 (强制 TLS)"
        printf '%b\n' "   ${GREEN}[2]${NC}\t🛠️ 自定义部署 (强制 TLS)"
        printf '%b\n' "   ${GREEN}[3]${NC}\t⚙️  单独协议参数管理 (端口/独立UUID/证书)"
        printf '%b\n' "   ${GREEN}[4]${NC}\t🌐 调教 WARP 智能分流规则 (Alpine 系统不支持)"
        printf '%b\n' "   ${GREEN}[5]${NC}\t🔗 查看提取节点订阅链接"
        echo -e "   ${CYAN}──────────────────────────────────────────────────${NC}"
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

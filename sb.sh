#!/bin/bash

# ==========================================
# Sing-box 6-in-1 极致稳定架构版
# 特性：纯 ASCII 终端，繁体中文，全协议默认，独立 Argo
# ==========================================

# --- 扩展視覺與色彩引擎 ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; PURPLE='\033[1;35m'; CYAN='\033[1;36m'; WHITE='\033[1;37m'
BG_RED='\033[41;37;1m'; BG_GREEN='\033[42;37;1m'; BG_BLUE='\033[44;37;1m'; BG_PURPLE='\033[45;37;1m'
BOLD='\033[1m'; UNDERLINE='\033[4m'; NC='\033[0m'

msg_info() { echo -e " ${CYAN}[ SYS.INFO ]${NC} $1"; }
msg_success() { echo -e " ${GREEN}[ SYS.OK   ]${NC} $1"; }
msg_warn() { echo -e " ${YELLOW}${BOLD}[ SYS.WARN ]${NC} $1"; }
msg_error() { echo -e " ${RED}[ SYS.FAIL ]${NC} $1"; }
reading() { echo -ne "\n ${CYAN}[ INPUT ] ${BOLD}$1${NC} > "; read -r "$2"; }
divider() { echo -e "${CYAN} ||----------------------------------------------------------------||${NC}"; }

print_logo() {
    clear
    echo -e "${CYAN} //================================================================\\\\ ${NC}"
    echo -e "${CYAN} ||  [ S I N G - B O X   O P E R A T I O N   T E R M I N A L ]     || ${NC}"
    echo -e "${CYAN} ||================================================================|| ${NC}"
    echo -e "${CYAN} ||  ███████╗██╗███╗   ██╗ ██████╗       ██████╗  ██████╗ ██╗  ██╗ || ${NC}"
    echo -e "${CYAN} ||  ██╔════╝██║████╗  ██║██╔════╝       ██╔══██╗██╔═══██╗╚██╗██╔╝ || ${NC}"
    echo -e "${CYAN} ||  ███████╗██║██╔██╗ ██║██║  ███╗█████╗██████╔╝██║   ██║ ╚███╔╝  || ${NC}"
    echo -e "${CYAN} ||  ╚════██║██║██║╚██╗██║██║   ██║╚════╝██╔══██╗██║   ██║ ██╔██╗  || ${NC}"
    echo -e "${CYAN} ||  ███████║██║██║ ╚████║╚██████╔╝      ██████╔╝╚██████╔╝██╔╝ ██╗ || ${NC}"
    echo -e "${CYAN} ||  ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝       ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ || ${NC}"
    divider
    echo -e "${CYAN} ||         ${PURPLE}${BOLD}[SYS.CORE] Kele's Advanced Architecture [v6.6]${NC}         ${CYAN}|| ${NC}"
    echo -e "${CYAN} \\\\================================================================// ${NC}"
    echo ""
}

# --- 全局變量 ---
SB_DIR="/etc/sing-box"
SB_CONF="${SB_DIR}/config.json"
SB_INFO="${SB_DIR}/install.info"
SB_BIN="/usr/local/bin/sing-box"
ARGO_BIN="/usr/local/bin/cloudflared"
ARGO_LOG="${SB_DIR}/argo.log"

[[ $EUID -ne 0 ]] && msg_error "權限不足，必須以 root 用戶運行此腳本！" && exit 1

if [[ "$0" != "/usr/bin/sb" ]]; then
    rm -f /usr/bin/sb 2>/dev/null
    cp -f "$0" /usr/bin/sb
    chmod +x /usr/bin/sb
    msg_success "環境變量 'sb' 映射已就緒，可直接輸入 sb 喚出控制台。"
    sleep 1
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
}

save_config() {
    cat > "$SB_INFO" << EOF
UUID=$UUID
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
EOF
}

is_alpine() { [ -f /etc/alpine-release ]; }

svc_action() {
    local action=$1; local service=$2
    if is_alpine; then
        case $action in
            enable) rc-update add $service default >/dev/null 2>&1 ;;
            disable) rc-update del $service default >/dev/null 2>&1 ;;
            start|stop|restart) rc-service $service $action >/dev/null 2>&1 ;;
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
    if lsof -i :$port >/dev/null 2>&1 || netstat -tuln | grep -q ":$port "; then return 1; fi
    return 0
}

get_outbound_ip() {
    local ip=""
    ip=$(curl -s4 --max-time 3 https://api.ipify.org 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -s4 --max-time 3 https://ifconfig.me/ip 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -s4 --max-time 3 https://ip.gs 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -s6 --max-time 3 https://api6.ipify.org 2>/dev/null)
    [ -z "$ip" ] && ip=$(curl -s6 --max-time 3 ipv6.ip.sb 2>/dev/null)
    [ -z "$ip" ] && ip="127.0.0.1"
    echo "$ip"
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
    echo ""; msg_info "正在檢測並加載系統依賴環境..."
    local pkgs=("curl" "wget" "jq" "openssl" "lsof" "socat")
    if is_alpine; then
        apk update >/dev/null 2>&1; apk add libc6-compat gcompat >/dev/null 2>&1
        for pkg in "${pkgs[@]}"; do ! command -v "$pkg" >/dev/null 2>&1 && apk add "$pkg" >/dev/null 2>&1; done
    else
        apt-get update -y >/dev/null 2>&1 || yum makecache -y >/dev/null 2>&1
        for pkg in "${pkgs[@]}"; do ! command -v "$pkg" >/dev/null 2>&1 && (apt-get install -y "$pkg" >/dev/null 2>&1 || yum install -y "$pkg" >/dev/null 2>&1); done
    fi
    optimize_network
}

safe_download() {
    local url=$1; local dest=$2
    msg_info "正在拉取遠程核心組件: $(basename $dest)..."
    local http_code=$(curl -sL -w "%{http_code}" -o "$dest" "$url")
    if [ "$http_code" != "200" ]; then msg_error "二進制文件拉取失敗！(HTTP CODE: $http_code)"; rm -f "$dest"; return 1; fi
    if [ ! -s "$dest" ]; then msg_error "數據塊寫入失敗！文件為空。"; rm -f "$dest"; return 1; fi
    return 0
}

apply_cert() {
    local domain=$1
    if [ ! -d ~/.acme.sh ]; then msg_warn "加載 acme.sh 證書自動化工具..."; curl https://get.acme.sh | sh >/dev/null 2>&1; fi
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1
    
    echo -e "\n${CYAN}[ SYS.ACME ]${NC} 初始化 ${YELLOW}$domain${NC} 的 TLS 密鑰交換進程..."
    local standalone_success=false
    if check_port_usage 80; then
        ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
        if [ $? -eq 0 ]; then standalone_success=true; fi
    else msg_warn "端口 80 資源衝突或不可達，放棄 Standalone 模式。"; fi
    
    if [ "$standalone_success" = false ]; then
        msg_error "Standalone 失敗，降級至 API 握手模式。"
        reading "是否啓用 Cloudflare API 執行 DNS-01 驗證？[y/n]" use_dns
        [ "${use_dns:-y}" != "y" ] && { msg_error "密鑰交換中止。"; return 1; }
        
        reading "輸入 Cloudflare API Token 密鑰" cf_token; export CF_Token="$cf_token"
        reading "輸入目標域名的 Zone ID" cf_zone_id; export CF_Zone_ID="$cf_zone_id"
        
        msg_info "正在向 Cloudflare 下發 API 驗證請求，預計用時 60-120 秒..."
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d "$domain" -k ec-256 --force
        [ $? -ne 0 ] && { msg_error "TLS 證書頒發遭到拒絕！"; return 1; }
    fi
    
    mkdir -p "${SB_DIR}"
    ~/.acme.sh/acme.sh --installcert -d "$domain" --fullchain-file "${SB_DIR}/server.crt" --key-file "${SB_DIR}/server.key" --ecc >/dev/null 2>&1
    msg_success "真實域名 TLS 證書已部署至系統內核！"
    return 0
}

install_singbox() {
    if [ ! -f "$SB_BIN" ]; then
        ARCH=$(uname -m); case "${ARCH}" in x86_64) S_ARCH="amd64" ;; aarch64|arm64) S_ARCH="arm64" ;; *) msg_error "硬件架構未授權"; exit 1 ;; esac
        TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r .tag_name)
        if safe_download "https://github.com/SagerNet/sing-box/releases/download/${TAG}/sing-box-${TAG#v}-linux-${S_ARCH}.tar.gz" "sb.tar.gz"; then
            tar -xzf sb.tar.gz || { msg_error "數據解壓縮崩潰"; exit 1; }
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
        msg_info "正在掛載 Cloudflare WARP 節點模塊..."
        curl -fsSl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        DPKG_ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
        echo "deb [arch=${DPKG_ARCH} signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list >/dev/null
        apt-get update -y >/dev/null 2>&1 && apt-get install -y cloudflare-warp >/dev/null 2>&1
    fi
    warp-cli --accept-tos registration new >/dev/null 2>&1; warp-cli --accept-tos mode proxy >/dev/null 2>&1
    warp-cli --accept-tos proxy port 40000 >/dev/null 2>&1; warp-cli --accept-tos connect >/dev/null 2>&1
}

generate_config() {
    mkdir -p "$SB_DIR"
    
    if [[ "$VD_MODE" != "3" ]] && [[ ! -f "${SB_DIR}/server.crt" ]]; then
        openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "${SB_DIR}/server.key" -out "${SB_DIR}/server.crt" -subj "/CN=bing.com" -days 3650 >/dev/null 2>&1
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
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-argo\", \"listen\": \"127.0.0.1\", \"listen_port\": 10086, \"users\": [ { \"uuid\": \"$UUID\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/argo\" } },"
    fi
    
    if [ "$ENABLE_RE" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-reality\", \"listen\": \"::\", \"listen_port\": $PORT_RE, \"users\": [ { \"uuid\": \"$UUID\", \"flow\": \"xtls-rprx-vision\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$REALITY_SNI\", \"reality\": { \"enabled\": true, \"handshake\": { \"server\": \"$REALITY_SNI\", \"server_port\": 443 }, \"private_key\": \"$REALITY_PRK\", \"short_id\": [ \"$REALITY_SHORT_ID\" ] } } },"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID\", \"flow\": \"\" } ], \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        elif [ "$VD_MODE" == "3" ] && [ -n "$VD_DOMAIN" ]; then
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"server_name\": \"$VD_DOMAIN\", \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        else
            INBOUNDS="$INBOUNDS { \"type\": \"vless\", \"tag\": \"in-vless\", \"listen\": \"::\", \"listen_port\": $PORT_VD, \"users\": [ { \"uuid\": \"$UUID\", \"flow\": \"\" } ], \"tls\": { \"enabled\": true, \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"transport\": { \"type\": \"ws\", \"path\": \"/ws\" } },"
        fi
    fi
    
    if [ "$ENABLE_HY" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"hysteria2\", \"tag\": \"in-hy2\", \"listen\": \"::\", \"listen_port\": $PORT_HY, \"users\": [ { \"password\": \"$PW_HY\" } ], \"tls\": { \"enabled\": true, \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" } },"
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        INBOUNDS="$INBOUNDS { \"type\": \"tuic\", \"tag\": \"in-tuic\", \"listen\": \"::\", \"listen_port\": $PORT_TC, \"users\": [ { \"uuid\": \"$UUID\", \"password\": \"$PW_TC\" } ], \"tls\": { \"enabled\": true, \"alpn\": [\"h3\"], \"certificate_path\": \"${SB_DIR}/server.crt\", \"key_path\": \"${SB_DIR}/server.key\" }, \"congestion_control\": \"bbr\" },"
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

setup_services() {
    local ARGO_CMD="$ARGO_BIN tunnel --url http://localhost:10086 --no-autoupdate --edge-ip-version auto"
    [ "$ARGO_MODE" == "fixed" ] && ARGO_CMD="$ARGO_BIN tunnel run --token ${ARGO_TOKEN}"

    if is_alpine; then
        cat > /etc/init.d/sing-box << EOF
#!/sbin/openrc-run
command="$SB_BIN"
command_args="run -c $SB_CONF"
command_background=true
pidfile="/var/run/sing-box.pid"
EOF
        cat > /etc/init.d/sb-argo << EOF
#!/sbin/openrc-run
command="/bin/sh"
command_args="-c '$ARGO_CMD > $ARGO_LOG 2>&1'"
command_background=true
pidfile="/var/run/sb-argo.pid"
EOF
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
[Install]
WantedBy=multi-user.target
EOF
        cat > /etc/systemd/system/sb-argo.service << EOF
[Unit]
Description=Argo Tunnel for Sing-box
After=network.target
[Service]
ExecStart=/bin/bash -c '$ARGO_CMD > $ARGO_LOG 2>&1'
Restart=always
RestartSec=3
StartLimitInterval=0
[Install]
WantedBy=multi-user.target
EOF
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
        msg_warn "警告：檢測到系統已存在活動的節點配置！"
        reading "是否確認執行覆蓋重置程序？[y/n]" confirm
        [[ "$confirm" != "y" ]] && return 1
        find "$SB_DIR" -type f ! -name "sub.txt" ! -name "server.crt" ! -name "server.key" -delete 2>/dev/null
    fi
    return 0
}

# --- 一鍵極速部署 ---
install_fast() {
    print_logo
    echo -e " ${CYAN}[ SYS.INIT ]${NC} ${YELLOW}開始執行全協議自動部署腳本...${NC}\n"
    check_existing || return
    
    install_deps; install_singbox; install_argo
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    S5_U="user"; S5_P=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
    
    ENABLE_VD=1; ENABLE_RE=1; ENABLE_HY=1; ENABLE_TC=1; ENABLE_S5=1; ENABLE_ARGO=1
    
    msg_info "底層進程正在自動映射系統空閒端口..."
    while true; do PORT_VD=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_VD && break; done
    while true; do PORT_RE=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_RE && break; done
    while true; do PORT_HY=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_HY && break; done
    while true; do PORT_TC=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_TC && break; done
    while true; do PORT_S5=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_S5 && break; done
    
    msg_info "正在由內核生成 XTLS-Reality 私鑰簽名..."
    local keys=$($SB_BIN generate reality-keypair)
    REALITY_PRK=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
    REALITY_PBK=$(echo "$keys" | awk '/PublicKey/ {print $2}')
    REALITY_SHORT_ID=$(openssl rand -hex 8)
    REALITY_SNI="www.microsoft.com"
    
    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"; VD_DOMAIN=""

    msg_info "正在向內存注入架構配置並喚醒守護進程..."
    generate_config; setup_services
    echo ""; msg_success "全協議部署完畢！"
    sleep 2
}

# --- 自定義按需部署 ---
install_custom() {
    print_logo
    echo -e " ${CYAN}[ SYS.EXEC ]${NC} ${YELLOW}進入自定義架構師調優模式...${NC}\n"
    check_existing || return
    
    install_deps; install_singbox; install_argo
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    PW_HY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    PW_TC=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)
    S5_U="user"; S5_P=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 8)
    
    echo -e "${CYAN}[ SYS.CONF ]${NC} 路由協議開關 (NAT 環境建議按需開啓以節約端口)"
    reading "啓用 VLESS (WS) 模塊 [y/n] (默認 y)" c_vd; [ "${c_vd:-y}" == "y" ] && ENABLE_VD=1 || ENABLE_VD=0
    reading "啓用 VLESS (XTLS-Reality) 模塊 [y/n] (默認 y)" c_re; [ "${c_re:-y}" == "y" ] && ENABLE_RE=1 || ENABLE_RE=0
    reading "啓用 Hysteria 2 (UDP) 模塊 [y/n] (默認 y)" c_hy; [ "${c_hy:-y}" == "y" ] && ENABLE_HY=1 || ENABLE_HY=0
    reading "啓用 TUIC v5 (UDP) 模塊 [y/n] (默認 y)" c_tc; [ "${c_tc:-y}" == "y" ] && ENABLE_TC=1 || ENABLE_TC=0
    reading "啓用 SOCKS5 代理模塊 [y/n] (默認 y)" c_s5; [ "${c_s5:-y}" == "y" ] && ENABLE_S5=1 || ENABLE_S5=0
    reading "啓用 Cloudflare Argo 隧道 [y/n] (默認 y)" c_ar; [ "${c_ar:-y}" == "y" ] && ENABLE_ARGO=1 || ENABLE_ARGO=0

    echo -e "\n${CYAN}[ SYS.NET  ]${NC} 物理層端口分配"
    if [ "$ENABLE_VD" == "1" ]; then
        reading "VLESS (WS) 監聽端口 (直接回車由系統隨機分配)" PORT_VD
        [ -z "$PORT_VD" ] && while true; do PORT_VD=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_VD && break; done
    fi
    if [ "$ENABLE_RE" == "1" ]; then
        reading "Reality 監聽端口 (強烈建議配置443，直接回車隨機分配)" PORT_RE
        [ -z "$PORT_RE" ] && while true; do PORT_RE=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_RE && break; done
        msg_info "正在由內核生成 XTLS-Reality 私鑰簽名..."
        local keys=$($SB_BIN generate reality-keypair)
        REALITY_PRK=$(echo "$keys" | awk '/PrivateKey/ {print $2}')
        REALITY_PBK=$(echo "$keys" | awk '/PublicKey/ {print $2}')
        REALITY_SHORT_ID=$(openssl rand -hex 8)
        REALITY_SNI="www.microsoft.com"
    fi
    if [ "$ENABLE_HY" == "1" ]; then
        reading "Hysteria2 監聽端口 (直接回車由系統隨機分配)" PORT_HY
        [ -z "$PORT_HY" ] && while true; do PORT_HY=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_HY && break; done
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        reading "TUIC 監聽端口 (直接回車由系統隨機分配)" PORT_TC
        [ -z "$PORT_TC" ] && while true; do PORT_TC=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_TC && break; done
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        reading "SOCKS5 監聽端口 (直接回車由系統隨機分配)" PORT_S5
        [ -z "$PORT_S5" ] && while true; do PORT_S5=$((RANDOM % 50000 + 10000)); check_port_usage $PORT_S5 && break; done
    fi
    
    ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""
    WARP_MODE="1"; WARP_DOMAINS=""
    VD_MODE="2"; VD_DOMAIN=""

    echo ""; msg_info "正在向內存注入架構配置並喚醒守護進程..."
    generate_config; setup_services
    echo ""; msg_success "自定義架構部署完畢！引擎已在後台鎖定運行。"
    sleep 2
}

manage_protocols() {
    [ ! -f "$SB_INFO" ] && msg_error "系統處於休眠狀態，請先執行初始化部署指令！" && sleep 2 && return
    load_config
    while true; do
        print_logo
        echo -e "${CYAN} //================================================================\\\\ ${NC}"
        echo -e "${CYAN} ||  [ SYS.CONF ] 協議熱更新與調優控制台                           || ${NC}"
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        [ "$ENABLE_VD" == "1" ] && echo -e "${CYAN} ||${NC}  [1] [ MOD ] 修改 VLESS (WS) 參數   ${YELLOW}(當前端口: $PORT_VD)${NC}"
        [ "$ENABLE_RE" == "1" ] && echo -e "${CYAN} ||${NC}  [2] [ MOD ] 修改 Reality 參數      ${YELLOW}(當前端口: $PORT_RE)${NC}"
        [ "$ENABLE_HY" == "1" ] && echo -e "${CYAN} ||${NC}  [3] [ MOD ] 修改 Hy2 參數          ${YELLOW}(當前端口: $PORT_HY)${NC}"
        [ "$ENABLE_TC" == "1" ] && echo -e "${CYAN} ||${NC}  [4] [ MOD ] 修改 TUIC v5 參數      ${YELLOW}(當前端口: $PORT_TC)${NC}"
        [ "$ENABLE_S5" == "1" ] && echo -e "${CYAN} ||${NC}  [5] [ MOD ] 修改 SOCKS5 參數       ${YELLOW}(當前端口: $PORT_S5)${NC}"
        [ "$ENABLE_ARGO" == "1" ] && echo -e "${CYAN} ||${NC}  [6] [ MOD ] 調整 Argo 隧道配置     ${YELLOW}(當前模式: $ARGO_MODE)${NC}"
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  ${RED}[7] [ KILL ] 強制停用/卸載指定協議釋放內存與端口${NC}"
        echo -e "${CYAN} ||${NC}  [0] [ EXIT ] 斷開連接並返回主終端"
        echo -e "${CYAN} \\\\================================================================// ${NC}"
        reading "請輸入操作代碼 [0-7]" choice
        case $choice in
            1) 
                [ "$ENABLE_VD" != "1" ] && continue
                reading "輸入新 VLESS 端口 (直接回車保持當前不變)" p; [ -n "$p" ] && PORT_VD=$p
                reading "輸入新 UUID (直接回車保持當前不變)" u; [ -n "$u" ] && UUID=$u
                echo -e "\n  ${YELLOW}請指定 VLESS 數據流傳輸模式：${NC}"
                echo -e "  [1] 關閉 TLS (極端環境純 TCP 直連)"
                echo -e "  [2] 開啓 TLS (生成自籤僞裝證書)"
                echo -e "  [3] 開啓 TLS (掛載真實域名 ACME 證書)"
                reading "模式選擇代碼 [1-3]" vm
                if [ "$vm" == "3" ]; then
                    reading "請輸入已解析至當前主機 IPv4 的真實域名" vd
                    if [ -n "$vd" ]; then apply_cert "$vd"; if [ $? -eq 0 ]; then VD_MODE="3"; VD_DOMAIN="$vd"; else msg_error "ACME 握手失敗，終止變更。"; fi; else msg_warn "輸入非法，操作已撤銷。"; fi
                elif [[ "$vm" == "1" || "$vm" == "2" ]]; then VD_MODE=$vm; VD_DOMAIN=""; fi
                ;;
            2)
                [ "$ENABLE_RE" != "1" ] && continue
                reading "輸入新 Reality 端口 (直接回車保持當前不變)" p; [ -n "$p" ] && PORT_RE=$p
                reading "替換僞裝 SNI 域名 (當前探測目標: $REALITY_SNI)" s; [ -n "$s" ] && REALITY_SNI=$s
                ;;
            3) [ "$ENABLE_HY" != "1" ] && continue; reading "輸入新 Hy2 端口 (直接回車保持不變)" p; [ -n "$p" ] && PORT_HY=$p; reading "替換握手密碼 (直接回車保持不變)" pw; [ -n "$pw" ] && PW_HY=$pw ;;
            4) [ "$ENABLE_TC" != "1" ] && continue; reading "輸入新 TUIC 端口 (直接回車保持不變)" p; [ -n "$p" ] && PORT_TC=$p; reading "替換握手密碼 (直接回車保持不變)" pw; [ -n "$pw" ] && PW_TC=$pw ;;
            5) [ "$ENABLE_S5" != "1" ] && continue; reading "輸入新 Socks5 端口 (直接回車保持不變)" p; [ -n "$p" ] && PORT_S5=$p; reading "替換認證密碼 (直接回車保持不變)" pw; [ -n "$pw" ] && S5_P=$pw ;;
            6)
                [ "$ENABLE_ARGO" != "1" ] && continue
                reading "[1]=加載臨時隨機隧道  [2]=綁定固定專屬隧道" am
                if [ "$am" == "2" ]; then
                    ARGO_MODE="fixed"
                    while true; do reading "請輸入 Cloudflare 綁定的固定域名" d; if [ -n "$d" ]; then ARGO_DOMAIN=$d; break; else msg_error "參數不能爲空！"; fi; done
                    while true; do reading "請輸入 Cloudflare 授權 Token 密鑰" t; if [ ${#t} -gt 50 ]; then ARGO_TOKEN=$t; break; else msg_error "密鑰長度校驗失敗！"; fi; done
                else ARGO_MODE="temp"; ARGO_TOKEN=""; ARGO_DOMAIN=""; fi
                ;;
            7)
                echo -e "\n  ${YELLOW}[ SYS.KILL ] 選擇需要從內存中移除的協議進程：${NC}"
                [ "$ENABLE_VD" == "1" ] && echo "  [1] VLESS (WS)"
                [ "$ENABLE_RE" == "1" ] && echo "  [2] Reality"
                [ "$ENABLE_HY" == "1" ] && echo "  [3] Hy2"
                [ "$ENABLE_TC" == "1" ] && echo "  [4] TUIC v5"
                [ "$ENABLE_S5" == "1" ] && echo "  [5] SOCKS5"
                [ "$ENABLE_ARGO" == "1" ] && echo "  [6] Argo 隧道進程"
                echo "  [0] 放棄操作"
                reading "選擇停用目標代碼 [0-6]" disable_choice
                case $disable_choice in
                    1) ENABLE_VD=0 ;; 2) ENABLE_RE=0 ;; 3) ENABLE_HY=0 ;; 4) ENABLE_TC=0 ;; 5) ENABLE_S5=0 ;; 6) ENABLE_ARGO=0 ;; 0) continue ;; *) msg_warn "非法代碼"; sleep 1; continue ;;
                esac
                msg_success "協議進程銷燬標記已記錄！"
                ;;
            0) break ;;
            *) continue ;;
        esac
        msg_info "正在向內核發送 SIGHUP 執行配置熱重載..."
        generate_config; setup_services
        msg_success "配置流熱重載執行成功！"; sleep 1
    done
}

manage_warp() {
    [ ! -f "$SB_INFO" ] && msg_error "系統處於休眠狀態，請先執行初始化部署指令！" && sleep 2 && return
    if is_alpine; then msg_error "Alpine 系統底層缺失依賴，WARP 模塊被鎖定。"; sleep 2; return; fi
    load_config
    while true; do
        print_logo
        local mode_str="原生物理網卡直連"
        [ "$WARP_MODE" == "2" ] && mode_str="全局 WARP 流量接管"
        [ "$WARP_MODE" == "3" ] && mode_str="基於策略路由分流"
        
        echo -e "${CYAN} //================================================================\\\\ ${NC}"
        echo -e "${CYAN} ||  [ SYS.WARP ] 智能分流與出口策略大腦                           || ${NC}"
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  當前路由模式: ${GREEN}$mode_str${NC}"
        [ "$WARP_MODE" == "3" ] && echo -e "${CYAN} ||${NC}  自定義分流黑名單: ${YELLOW}${WARP_DOMAINS:-無記錄}${NC}"
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  [1] [ SWAP ] 切換 WARP 底層工作模式"
        echo -e "${CYAN} ||${NC}  [2] [ ADD  ] 注入目標分流域名記錄"
        echo -e "${CYAN} ||${NC}  [3] [ DEL  ] 移除指定分流域名記錄"
        echo -e "${CYAN} ||${NC}  [4] [ DROP ] 清空整張路由分流表"
        echo -e "${CYAN} ||${NC}  [0] [ EXIT ] 斷開連接並返回主終端"
        echo -e "${CYAN} \\\\================================================================// ${NC}"
        
        reading "請輸入操作代碼 [0-4]" choice
        case $choice in
            1) echo -e "  ➤ [1]=關閉 WARP  [2]=全局接管  [3]=自定義分流策略"; reading "選擇模式代碼" wm; [ -n "$wm" ] && WARP_MODE=$wm; [[ "$WARP_MODE" == "2" || "$WARP_MODE" == "3" ]] && install_warp ;;
            2) reading "輸入需要追加路由記錄的域名 (例如: netflix.com)" nd; if [ -n "$nd" ]; then if [ -z "$WARP_DOMAINS" ]; then WARP_DOMAINS="$nd"; else WARP_DOMAINS="$WARP_DOMAINS,$nd"; fi; fi ;;
            3) if [ -z "$WARP_DOMAINS" ]; then msg_warn "路由表爲空，無數據可刪除！"; sleep 1; continue; fi; reading "輸入需要從路由表中移除的域名" rm_d; if [ -n "$rm_d" ]; then IFS=',' read -ra DOMAINS <<< "$WARP_DOMAINS"; local new_arr=""; for d in "${DOMAINS[@]}"; do if [ "$d" != "$rm_d" ] && [ -n "$d" ]; then new_arr+="$d,"; fi; done; WARP_DOMAINS=${new_arr%,}; msg_success "路由策略表已同步更新！"; fi ;;
            4) WARP_DOMAINS="" ;;
            0) break ;;
        esac
        generate_config; svc_action restart sing-box; msg_success "WARP 路由策略已熱重載生效！"; sleep 1
    done
}

show_nodes() {
    print_logo; [ ! -f "$SB_INFO" ] && msg_error "系統處於休眠狀態，無活動的節點數據！" && sleep 2 && return
    load_config
    
    msg_info "正在向外部接口廣播探針，解析公網 IPv4/v6 地址 (請稍候)..."
    out_ip=$(get_outbound_ip)
    
    if [ -z "$CUSTOM_IP" ]; then
        echo -e " ${CYAN}[ SYS.NET  ]${NC} 系統外網物理出口 IP 探測爲: ${GREEN}$out_ip${NC}"
        reading "若需強制覆蓋入站 IP / DDNS 域名請在此鍵入 (確認無誤請直接回車)" in_ip
        [ -n "$in_ip" ] && CUSTOM_IP=$in_ip || CUSTOM_IP=$out_ip
        save_config
    fi

    local ip=$CUSTOM_IP
    [[ "$ip" =~ .*:.* ]] && ip="[${ip}]" 

    echo -e "\n${CYAN} //====================== [ SYS.DATA_LINKS ] ======================\\\\ ${NC}"
    local all_links=""
    
    if [ "$ENABLE_RE" == "1" ]; then
        echo -e "${CYAN} ||${NC}  ${GREEN}[ VLESS + XTLS-Reality ]${NC} (底層 TCP 直連，隱蔽性極致)"
        link_re="vless://${UUID}@${ip}:${PORT_RE}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=chrome&pbk=${REALITY_PBK}&sid=${REALITY_SHORT_ID}&type=tcp#SB-Reality"
        echo -e "${CYAN} ||${NC}      -> ${link_re}"; all_links+="$link_re\n"
    fi

    if [ "$ENABLE_VD" == "1" ]; then
        if [ "$VD_MODE" == "1" ]; then
            echo -e "${CYAN} ||${NC}  ${GREEN}[ VLESS + WS ]${NC} (未加密明文流，適用於內網或中轉)"
            link1="vless://${UUID}@${ip}:${PORT_VD}?encryption=none&security=none&type=ws&path=%2Fws#SB-VLESS-NoTLS"
        elif [ "$VD_MODE" == "3" ] && [ -n "$VD_DOMAIN" ]; then
            echo -e "${CYAN} ||${NC}  ${GREEN}[ VLESS + WS + TLS ]${NC} (掛載 ACME 真實證書: ${VD_DOMAIN})"
            link1="vless://${UUID}@${VD_DOMAIN}:${PORT_VD}?encryption=none&security=tls&sni=${VD_DOMAIN}&type=ws&host=${VD_DOMAIN}&path=%2Fws#SB-VLESS-TLS"
        else
            echo -e "${CYAN} ||${NC}  ${GREEN}[ VLESS + WS + TLS ]${NC} (掛載內核自簽名僞裝證書)"
            link1="vless://${UUID}@${ip}:${PORT_VD}?encryption=none&security=tls&sni=bing.com&alpn=http%2F1.1&type=ws&host=bing.com&path=%2Fws&allowInsecure=1#SB-VLESS-FakeTLS"
        fi
        echo -e "${CYAN} ||${NC}      -> ${link1}"; all_links+="$link1\n"
    fi
    
    if [ "$ENABLE_ARGO" == "1" ]; then
        local argo_domain=""
        if [ "$ARGO_MODE" == "temp" ]; then
            for i in {1..5}; do argo_domain=$(grep -oE "https://[a-zA-Z0-9-]+\.trycloudflare\.com" "$ARGO_LOG" | head -n 1 | sed 's/https:\/\///'); [ -n "$argo_domain" ] && break; sleep 1; done
            [ -n "$argo_domain" ] && argo_type="臨時隨機邊緣節點"
        elif [ "$ARGO_MODE" == "fixed" ]; then
            argo_domain="$ARGO_DOMAIN"; argo_type="固定域專線邊緣節點"
        fi
        
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  ${GREEN}[ VLESS + Argo Edge ]${NC} (${argo_type:-進程異常或網絡被阻斷})"
        if [ -n "$argo_domain" ]; then
            link2="vless://${UUID}@www.visa.com.sg:443?encryption=none&security=tls&sni=${argo_domain}&type=ws&host=${argo_domain}&path=%2Fargo#SB-Argo"
            echo -e "${CYAN} ||${NC}      -> ${link2}"; all_links+="$link2\n"
        else echo -e "${CYAN} ||${NC}      -> ${RED}[ SYS.FAIL ] 隧道鏈接獲取失敗，請排查網絡狀態！${NC}"; fi
    fi

    if [ "$ENABLE_HY" == "1" ]; then
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  ${GREEN}[ Hysteria 2 ]${NC} (基於 UDP 的暴力提速引擎)"
        link3="hysteria2://${PW_HY}@${ip}:${PORT_HY}?insecure=1&sni=bing.com#SB-Hy2"
        echo -e "${CYAN} ||${NC}      -> ${link3}"; all_links+="$link3\n"
    fi
    if [ "$ENABLE_TC" == "1" ]; then
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  ${GREEN}[ TUIC v5 ]${NC} (基於 QUIC 協議的低延遲架構)"
        link4="tuic://${UUID}:${PW_TC}@${ip}:${PORT_TC}?sni=bing.com&alpn=h3&congestion_control=bbr&allow_insecure=1#SB-TUIC"
        echo -e "${CYAN} ||${NC}      -> ${link4}"; all_links+="$link4\n"
    fi
    if [ "$ENABLE_S5" == "1" ]; then
        echo -e "${CYAN} ||----------------------------------------------------------------|| ${NC}"
        echo -e "${CYAN} ||${NC}  ${GREEN}[ SOCKS5 ]${NC} (基礎網絡代理層)"
        b64_cred=$(echo -n "${S5_U}:${S5_P}" | base64 | tr -d '\n')
        link5="socks://${b64_cred}@${ip}:${PORT_S5}#SB-Socks5"
        echo -e "${CYAN} ||${NC}      -> ${link5}"; all_links+="$link5\n"
    fi
    echo -e "${CYAN} \\\\================================================================// ${NC}"

    echo -e "\n ${CYAN}[ BASE.64 ]${NC} 通用數據流，請一鍵拷貝下方代碼導入客戶端:"
    echo -e "$all_links" | sed '/^$/d' | base64 | tr -d '\n'
    reading "鍵入回車 (Enter) 斷開數據鏈接並返回終端..." dummy
}

uninstall_script() {
    print_logo; echo -e " ${RED}${BOLD}[ SYS.CRIT ] 系統危險操作警告！你正在執行物理毀灭程序！${NC}\n"
    reading "是否授權執行？(將徹底清空腳本、內核引擎及配置) [y/n]" c
    [[ "$c" != "y" ]] && return

    echo ""; for i in {3..1}; do echo -e "${YELLOW}[ SYS.WARN ] 距離系統清理還有 $i 秒...${NC}"; sleep 1; done
    
    msg_info "向守護進程發送 SIGKILL 中斷信號..."
    svc_action stop sing-box >/dev/null 2>&1; svc_action stop sb-argo >/dev/null 2>&1
    svc_action disable sing-box >/dev/null 2>&1; svc_action disable sb-argo >/dev/null 2>&1
    
    if is_alpine; then
        rm -f /etc/init.d/sing-box /etc/init.d/sb-argo
    else
        rm -f /etc/systemd/system/sing-box.service /etc/systemd/system/sb-argo.service; systemctl daemon-reload
    fi
    
    if command -v warp-cli >/dev/null 2>&1; then warp-cli disconnect >/dev/null 2>&1; apt-get remove -y cloudflare-warp >/dev/null 2>&1; fi

    msg_info "正在抹除內存中的二進制文件與日誌..."
    find "$SB_DIR" -type f ! -name "sub.txt" -delete 2>/dev/null
    rm -f "$SB_BIN" "$ARGO_BIN" "/usr/bin/sb"
    msg_success "系統底層已恢復純淨狀態 (自定義文本 sub.txt 已安全保留)。鏈接已斷開！"; rm -f "$0"; exit 0
}

main_menu() {
    while true; do
        print_logo
        local status="${RED}[ OFFLINE / 休眠中 / 核心未部署 ]${NC}"
        [ -f "$SB_INFO" ] && status="${GREEN}[ ONLINE / 運行中 / 系統已接管 ]${NC}"
        
        echo -e "   [ SYSTEM STATUS ] :: $status"
        echo -e "   ${CYAN}//------------------------------------------------------------\\\\${NC}"
        echo -e "   ${CYAN}[1]${NC} [ INIT ] 一鍵極速部署 / 強制重置引擎"
        echo -e "   ${CYAN}[2]${NC} [ EXEC ] 自定義按需部署 / 強制重置引擎"
        echo -e "   ${CYAN}[3]${NC} [ CONF ] 獨立協議參數控制台 (端口/密碼/證書/停用)"
        echo -e "   ${CYAN}[4]${NC} [ NET  ] 調教 WARP 智能分流策略大腦 (Alpine 拒絕訪問)"
        echo -e "   ${CYAN}[5]${NC} [ DATA ] 查看提取節點訂閱鏈接及配置"
        echo -e "   ${CYAN}//------------------------------------------------------------\\\\${NC}"
        echo -e "   ${RED}[9]${NC} [ KILL ] 徹底物理毀灭 (安全清理所有進程與殘留)"
        echo -e "   ${RED}[0]${NC} [ EXIT ] 斷開連接並安全退出終端"
        echo ""
        reading "請輸入操作指令代碼" choice
        case $choice in
            1) install_fast ;;
            2) install_custom ;;
            3) manage_protocols ;;
            4) manage_warp ;;
            5) show_nodes ;;
            9) uninstall_script ;;
            0) clear; exit 0 ;;
            *) ;;
        esac
    done
}

main_menu

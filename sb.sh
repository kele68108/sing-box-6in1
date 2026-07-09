# ================= 内建 API WARP 注册模块 =================
register_warp_api() {
    if is_alpine; then return 0; fi
    if [ -n "$WARP_IPV4" ] && [ -n "$WARP_PRIV" ]; then return 0; fi
    
    msg_info "正在通过 Cloudflare API 注册内建 WARP 账户..."
    bootstrap_network

    local response client_id
    
    # 【尝试 1】: 官方原生接口注册 (极易被 CF 阻断)
    local wg_keys warp_pub install_id fcm_token
    wg_keys=$($SB_BIN generate wireguard-keypair 2>/dev/null)
    WARP_PRIV=$(echo "$wg_keys" | awk '/PrivateKey/ {print $2}')
    warp_pub=$(echo "$wg_keys" | awk '/PublicKey/ {print $2}')
    install_id=$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 22)
    fcm_token="${install_id}:APA91b$(tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 134)"

    response=$(curl -s -m 5 -X POST "https://api.cloudflareclient.com/v0a884/reg" \
        -H "User-Agent: okhttp/3.12.1" \
        -H "CF-Client-Version: a-6.11-2223" \
        -H "Content-Type: application/json" \
        -d '{
          "key": "'"${warp_pub}"'",
          "install_id": "'"${install_id}"'",
          "fcm_token": "'"${fcm_token}"'",
          "tos": "'$(date -u +%FT%T.000Z)'",
          "model": "PC",
          "locale": "zh_CN"
        }')

    WARP_IPV4=$(echo "$response" | jq -r '.config.interface.addresses.v4' 2>/dev/null)
    WARP_IPV6=$(echo "$response" | jq -r '.config.interface.addresses.v6' 2>/dev/null)
    client_id=$(echo "$response" | jq -r '.config.client_id' 2>/dev/null)
    WARP_RESERVED=$(echo "$client_id" | base64 -d 2>/dev/null | od -An -tu1 -N3 | awk '{print "["$1", "$2", "$3"]'} 2>/dev/null)

    # 【尝试 2】: 官方接口失败，尝试通过代理 API 获取
    if [ -z "$WARP_IPV4" ] || [ "$WARP_IPV4" == "null" ]; then
        msg_warn "官方 API 遭阻断，尝试通过代理节点获取..."
        response=$(curl -s -m 5 "https://warp.cloudflare.nyc.mn/?run=register")
        WARP_PRIV=$(echo "$response" | jq -r '.private_key' 2>/dev/null)
        WARP_IPV4=$(echo "$response" | jq -r '.config.interface.addresses.v4' 2>/dev/null)
        WARP_IPV6=$(echo "$response" | jq -r '.config.interface.addresses.v6' 2>/dev/null)
        WARP_RESERVED=$(echo "$response" | jq -c '.config.reserved' 2>/dev/null)
    fi

    # 【尝试 3】: 若网络彻底无法联通外网 API，启用内置防失联账户
    if [ -z "$WARP_IPV4" ] || [ "$WARP_IPV4" == "null" ]; then
        msg_warn "API 均超时，启用 Sing-box 内置防失联 WARP 账户..."
        WARP_PRIV="hTk06uwwXhZx3RVqtug3MQ0RSodzdM/U5z/M5NIbh4c="
        WARP_IPV4="172.16.0.2"
        WARP_IPV6="2606:4700:110:8921:bf06:c4d7:40b7:8afd"
        WARP_RESERVED="[151, 54, 152]"
    fi

    restore_network
    [ -z "$WARP_RESERVED" ] && WARP_RESERVED="[0,0,0]"

    msg_success "内建 WARP 账户准备就绪: 分配 IP $WARP_IPV4"
    save_config
    return 0
}
# ==========================================================

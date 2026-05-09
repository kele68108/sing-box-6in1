#!/bin/bash

# === 視覺與色彩引擎 ===
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'
BG_RED='\033[41;37;1m'

clear
echo -e "${CYAN}=== 賽博龐克終端動效 DEMO ===${NC}\n"

# 1. 打字機效應 (純 Bash 實現，支持中文字符)
typewriter() {
    local text="$1"
    local delay="${2:-0.03}"
    # 逐字讀取並打印，模擬終端緩慢吐出數據
    while IFS= read -r -n1 -d '' char; do
        echo -ne "$char"
        sleep "$delay"
    done < <(echo -n "$text")
    echo ""
}

# 2. 偽造自檢序列 (Hex Dump Boot)
boot_sequence() {
    echo -e "${CYAN}[ SYS.INIT ]${NC} 開始加載核心組件..."
    for i in {1..12}; do
        # 生成隨機 Hex 字符串和偽造內存地址
        local hex=$(od -A n -t x1 -N 6 /dev/urandom | tr -d ' \n' 2>/dev/null || openssl rand -hex 6)
        local addr=$(printf "0x%08X" $((RANDOM * RANDOM)))
        echo -e "  ${CYAN}[${addr}]${NC} ${YELLOW}MOUNTED${NC} :: MODULE_${hex} ... OK"
        sleep 0.05
    done
    typewriter " ${GREEN}[ SYS.OK   ] 底層環境初始化完成。${NC}" 0.02
}

# 3. 賽博進度條 (Cyber Progress Bar)
cyber_progress() {
    local task="$1"
    local total_steps=25
    echo -ne " ${CYAN}[ SYS.EXEC ]${NC} ${task} \n"
    for ((i=1; i<=total_steps; i++)); do
        local percent=$((i * 100 / total_steps))
        echo -ne "\r ["
        # 繪製已完成部分 (實心方塊)
        for ((j=1; j<=i; j++)); do echo -ne "${GREEN}█${NC}"; done
        # 繪製未完成部分 (陰影方塊)
        for ((j=i+1; j<=total_steps; j++)); do echo -ne "░"; done
        echo -ne "] ${percent}% "
        sleep 0.08
    done
    echo -e "\n ${GREEN}[ SYS.OK   ] 執行完畢。${NC}"
}

# 4. 矩陣解密展示 (Matrix Reveal)
matrix_reveal() {
    local secret_data="$1"
    local length=${#secret_data}
    echo -ne " ${CYAN}[ BASE.64  ]${NC} 正在解密並提取數據鏈接...\n"
    
    # 快速打印隨機亂碼，模擬解密過程
    for i in {1..15}; do
        local random_str=$(tr -dc 'a-zA-Z0-9!@#$%^&*()' < /dev/urandom | fold -w "$length" | head -n 1)
        echo -ne "\r  ${YELLOW}${random_str}${NC}"
        sleep 0.04
    done
    # 最終展示真實數據
    echo -ne "\r  ${GREEN}${secret_data}${NC}                                      \n"
}

# 5. 故障閃爍警告 (Glitch Error)
glitch_error() {
    local msg="$1"
    # 紅白背景快速交替閃爍，製造強烈警告感
    for i in {1..4}; do
        echo -ne "\r ${BG_RED}[ SYS.CRIT ] ${msg} ${NC}"
        sleep 0.1
        echo -ne "\r ${RED}[ SYS.CRIT ] ${msg} ${NC}"
        sleep 0.1
    done
    echo ""
}

# === 運行展示序列 ===

# 模擬啟動時的加載
boot_sequence
echo ""

# 模擬常規提示（替換原本瞬間出現的 echo）
typewriter " ${CYAN}[ SYS.INFO ]${NC} 正在向內存注入架構配置並喚醒守護進程..."
echo ""

# 模擬耗時操作（比如申請證書或 Argo 隧道）
cyber_progress "正在向 Cloudflare 節點發起 TLS 握手請求..."
echo ""

# 模擬顯示最終的訂閱鏈接
matrix_reveal "vless://5b2a1c...234@bing.com:443?encryption=none&security=reality..."
echo ""

# 模擬執行物理毀滅程序時的警告
glitch_error "系統危險操作警告！你正在執行物理毀滅程序！"
echo ""

typewriter " 演示結束。按任意鍵返回主終端..."

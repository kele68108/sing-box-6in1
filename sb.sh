#!/bin/bash

# ==========================================
# 美化方案演示（纯符号 + 颜色 + 边框 + 状态标签）
# ==========================================

# --- 颜色定义 ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # no color

# --- 固定宽度符号 ---
SYM_ADD="[+]"
SYM_SET="[~]"
SYM_INFO="[i]"
SYM_WARN="[!]"
SYM_OK="[√]"
SYM_ERR="[×]"
SYM_RUN="[RUN]"
SYM_STOP="[STOP]"
SYM_ERR2="[ERR]"

# --- 辅助函数 ---
print_header() {
    clear
    echo -e "${CYAN}╭──────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}            ${WHITE}Sing-box 6-in-1 管理面板 (v7.0)${NC}                  ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
}

print_footer() {
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────╯${NC}"
}

# --- 主菜单演示 ---
main_menu_demo() {
    print_header

    # 第一行：系统状态（使用颜色标签）
    printf "${CYAN}│${NC}  ${WHITE}系统状态:${NC}  ${GREEN}${SYM_RUN} 已部署${NC}                          ${CYAN}│${NC}\n"

    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"

    # 菜单项：使用固定宽度符号 + 制表符对齐
    printf "${CYAN}│${NC}  ${GREEN}${SYM_ADD}${NC}\t一键快速部署 / 重置引擎                    ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  ${GREEN}${SYM_SET}${NC}\t自定义按需部署 / 重置引擎                    ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  ${GREEN}${SYM_INFO}${NC}\t单独协议参数管理 (端口/密码/证书)            ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  ${GREEN}${SYM_INFO}${NC}\t调教 WARP 智能分流规则                      ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  ${GREEN}${SYM_INFO}${NC}\t查看节点订阅链接                            ${CYAN}│${NC}\n"

    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"

    printf "${CYAN}│${NC}  ${RED}${SYM_ERR}${NC}\t彻底卸载 (安全清理服务与残留)                 ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  ${RED}${SYM_ERR}${NC}\t安全退出面板                                  ${CYAN}│${NC}\n"

    print_footer
    echo ""

    # 输入提示
    printf "${CYAN}➤ ${BOLD}请输入指令代码${NC} ➔ "
    read -r choice
    echo "你输入了: $choice"
}

# --- 协议状态演示（展示不同状态标签）---
protocol_status_demo() {
    print_header
    printf "${CYAN}│${NC}  ${WHITE}协议运行状态${NC}                                        ${CYAN}│${NC}\n"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    printf "${CYAN}│${NC}  VLESS (WS)      ${GREEN}${SYM_RUN}${NC}  端口: 10001                    ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  VLESS (Reality) ${RED}${SYM_STOP}${NC}  端口: -                         ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  Hysteria 2      ${GREEN}${SYM_RUN}${NC}  端口: 10002                    ${CYAN}│${NC}\n"
    printf "${CYAN}│${NC}  TUIC v5         ${YELLOW}${SYM_ERR2}${NC} 端口冲突 (10003)               ${CYAN}│${NC}\n"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    printf "${CYAN}│${NC}  Argo 隧道       ${GREEN}${SYM_RUN}${NC}  域名: abc.trycloudflare.com     ${CYAN}│${NC}\n"
    print_footer
}

# --- 演示信息输出（使用统一符号）---
info_demo() {
    echo -e " ${BLUE}${SYM_INFO}${NC} ${WHITE}正在探测公网 IP...${NC}"
    sleep 0.5
    echo -e " ${GREEN}${SYM_OK}${NC} ${WHITE}IP 地址: 203.0.113.5${NC}"
    echo -e " ${YELLOW}${SYM_WARN}${NC} ${WHITE}端口 80 被占用，跳过 standalone 模式${NC}"
    echo -e " ${RED}${SYM_ERR}${NC} ${WHITE}证书申请失败，请检查域名解析${NC}"
}

# --- 运行演示 ---
main_menu_demo
echo ""
protocol_status_demo
echo ""
info_demo

#!/bin/bash

# ==============================================================================
# Hysteria 2 一键安装脚本 (增强版)
#
# - 适配 Debian, Ubuntu, Alpine Linux
# - 自动检测并使用对应的包管理器和初始化系统 (systemd/OpenRC)
# - 增强的用户提示和错误处理
# - 自动生成客户端配置文件
#
# by rei (重构与增强 by AI Assistant)
# ==============================================================================

# --- 全局设置 ---
# 如果任何命令失败，立即退出脚本
set -e
# 在管道中，只要有任何一个命令失败，整个管道的返回值就为非零
set -o pipefail

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- 日志函数 ---
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# --- 变量定义 ---
HYSTERIA_CONFIG_DIR="/etc/hysteria"
HYSTERIA_CERT_FILE="${HYSTERIA_CONFIG_DIR}/server.crt"
HYSTERIA_KEY_FILE="${HYSTERIA_CONFIG_DIR}/server.key"
HYSTERIA_CONFIG_FILE="${HYSTERIA_CONFIG_DIR}/config.yaml"

# --- 脚本函数 ---

# 检查是否以 root 身份运行
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "此脚本需要以 root 权限运行。请尝试使用 'sudo'。"
    fi
}

# 检测操作系统和初始化系统
detect_os_and_init() {
    info "正在检测操作系统和初始化系统..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    else
        error "无法检测到操作系统。此脚本支持 Debian, Ubuntu, 和 Alpine。"
    fi

    case "$OS_ID" in
        debian|ubuntu)
            PKG_MANAGER="apt-get"
            INIT_SYSTEM="systemd"
            info "检测到 Debian/Ubuntu (systemd)"
            ;;
        alpine)
            PKG_MANAGER="apk"
            INIT_SYSTEM="openrc"
            info "检测到 Alpine Linux (OpenRC)"
            ;;
        *)
            error "不支持的操作系统: $OS_ID"
            ;;
    esac
}

# 安装依赖
install_dependencies() {
    info "正在更新软件包列表并安装依赖..."
    case "$PKG_MANAGER" in
        apt-get)
            apt-get update -y
            apt-get install -y curl sudo openssl || error "依赖安装失败。"
            ;;
        apk)
            # Alpine 需要额外的包来兼容官方脚本
            # grep: 提供完整的 GNU grep，因为 busybox grep 不支持 -P 选项
            # shadow: 提供 useradd 命令
            info "为 Alpine 安装额外兼容性依赖 (grep, shadow)..."
            apk update
            apk add curl sudo openssl grep shadow || error "依赖安装失败。"
            ;;
    esac
    success "依赖安装完成。"
}

# 安装 Hysteria
install_hysteria() {
    info "正在从官方源安装 Hysteria..."
    if [ "$OS_ID" = "alpine" ]; then
        info "在 Alpine 上运行，使用 FORCE_NO_SYSTEMD=2 标志..."
        env FORCE_NO_SYSTEMD=2 bash <(curl -fsSL https://get.hy2.sh/) || error "Hysteria 安装脚本执行失败。"
    else
        bash <(curl -fsSL https://get.hy2.sh/) || error "Hysteria 安装脚本执行失败。"
    fi

    if [ ! -f /usr/local/bin/hysteria ]; then
        error "Hysteria 可执行文件未找到，安装可能已失败。"
    fi
    success "Hysteria 安装成功。"
}

# 生成自签名证书
generate_certificate() {
    info "正在生成自签名 TLS 证书..."
    if [ -f "$HYSTERIA_CERT_FILE" ] || [ -f "$HYSTERIA_KEY_FILE" ]; then
        warn "证书文件已存在。"
        read -p "是否要覆盖现有证书? (y/N): " overwrite_cert
        if [[ "$overwrite_cert" != "y" && "$overwrite_cert" != "Y" ]]; then
            info "跳过证书生成。"
            return
        fi
    fi

    mkdir -p "$HYSTERIA_CONFIG_DIR"
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$HYSTERIA_KEY_FILE" \
        -out "$HYSTERIA_CERT_FILE" \
        -subj "/CN=bing.com" -days 36500 || error "OpenSSL 证书生成失败。"

    # Hysteria v2.3.0+ 需要 hysteria 用户拥有私钥权限
    if id "hysteria" &>/dev/null; then
        chown hysteria:hysteria "$HYSTERIA_KEY_FILE" "$HYSTERIA_CERT_FILE"
    else
        warn "未找到 'hysteria' 用户，跳过权限设置。这在新版本中可能导致问题。"
    fi
    
    success "证书生成并配置完成。"
}

# 获取用户配置并生成配置文件
configure_hysteria() {
    info "开始配置 Hysteria..."
    
    # 获取端口
    read -p "请输入您想要的 Hysteria 端口 (默认 443): " port
    port=${port:-443} # 如果用户未输入，则使用默认值

    # 获取密码
    read -p "是否自定义密码? (y/N): " useCustomPwd
    if [[ "$useCustomPwd" == "y" || "$useCustomPwd" == "Y" ]]; then
        read -s -p "请输入您的自定义密码: " password
        echo
        if [ -z "$password" ]; then
            error "密码不能为空。"
        fi
    else
        # 生成一个安全的随机密码
        password=$(openssl rand -base64 16)
        info "已生成随机密码。"
    fi

    info "正在写入配置文件到 $HYSTERIA_CONFIG_FILE..."
    # 使用 heredoc 写入配置，更清晰
    cat > "$HYSTERIA_CONFIG_FILE" << EOF
# Hysteria 2 服务器配置文件
# 由一键脚本自动生成

listen: :${port}

tls:
  cert: ${HYSTERIA_CERT_FILE}
  key: ${HYSTERIA_KEY_FILE}

auth:
  type: password
  password: ${password}

masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

    # 保存配置以供后续显示
    SERVER_PORT=$port
    SERVER_PASSWORD=$password

    success "配置文件写入完成。"
}

# 启动并设置开机自启
start_and_enable_service() {
    info "正在启动 Hysteria 服务并设置开机自启..."
    case "$INIT_SYSTEM" in
        systemd)
            systemctl enable hysteria-server.service || warn "设置开机自启失败。"
            systemctl restart hysteria-server.service || error "启动 Hysteria 服务失败。"
            ;;
        openrc)
            rc-update add hysteria-server default || warn "设置开机自启失败。"
            rc-service hysteria-server restart || error "启动 Hysteria 服务失败。"
            ;;
    esac
    # 等待一秒确保服务已启动
    sleep 1
    success "Hysteria 服务已启动。"
}

# 显示结果和客户端配置
display_results() {
    # 获取服务器的公网 IP
    SERVER_IP=$(curl -fsSL --ipv4 https://ifconfig.co)

    clear
    echo -e "============================================================"
    echo -e " ${GREEN}Hysteria 2 安装与配置完成！${NC}"
    echo -e "============================================================"
    echo ""
    echo -e " ${YELLOW}服务器配置信息:${NC}"
    echo -e "   - 地址:     ${GREEN}${SERVER_IP}${NC}"
    echo -e "   - 端口:     ${GREEN}${SERVER_PORT}${NC}"
    echo -e "   - 密码:     ${GREEN}${SERVER_PASSWORD}${NC}"
    echo ""
    echo -e " ${YELLOW}客户端配置文件 (例如 config.json):${NC}"
    echo -e "   请将以下内容保存为客户端的 'config.json' 文件。"
    echo -e "------------------------------------------------------------"
    echo -e "${GREEN}"
    cat << EOF
{
  "server": "${SERVER_IP}:${SERVER_PORT}",
  "auth": "${SERVER_PASSWORD}",
  "tls": {
    "sni": "bing.com",
    "insecure": true
  }
}
EOF
    echo -e "${NC}------------------------------------------------------------"
    echo ""
    info "正在检查服务运行状态..."
    echo ""
    
    case "$INIT_SYSTEM" in
        systemd)
            systemctl status hysteria-server.service --no-pager
            ;;
        openrc)
            rc-service hysteria-server status
            ;;
    esac
}


# --- 主函数 ---
main() {
    clear
    echo -e "${GREEN}**************************************${NC}"
    echo -e "${GREEN}*      Hysteria 2 一键安装脚本     *${NC}"
    echo -e "${GREEN}*        (Debian/Ubuntu/Alpine)      *${NC}"
    echo -e "${GREEN}**************************************${NC}"
    echo ""
    
    read -p "确认开始执行脚本吗? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "操作已取消。"
        exit 0
    fi

    check_root
    detect_os_and_init
    install_dependencies
    install_hysteria
    generate_certificate
    configure_hysteria
    start_and_enable_service
    display_results
}

# --- 脚本入口 ---
main

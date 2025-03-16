#!/system/bin/sh
# 全自动安装引擎

MODDIR="$MODPATH"
CONF_DIR="$MODDIR/config"
LOG_FILE="$MODDIR/install.log"

log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [安装] $1" >> "$LOG_FILE" 2>/dev/null
    echo "[$(( $(date +%s) - $(stat -c %Y "$LOG_FILE" 2>/dev/null) ))秒前] $1" >> "$MODDIR/install_debug.log" 2>/dev/null
}

generate_secret() {
    if command -v openssl >/dev/null 2>/dev/null; then
        openssl rand -hex 24 | tr -dc 'a-zA-Z0-9!@#$%' | head -c 48
    else
        head -c 48 /dev/urandom 2>/dev/null | tr -dc 'a-zA-Z0-9!@#$%'
    fi
}

create_config() {
    token=$(generate_secret)
    password=$(generate_secret)
    ip=$(curl -s icanhazip.com 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null || echo "127.0.0.1")
    mkdir -p "$CONF_DIR" 2>/dev/null
    cat > "$CONF_DIR/frps.auto.toml" << EOF
[common]
bind_port = 7000
token = "$token"
[dashboard]
addr = "0.0.0.0"
port = 7500
user = "admin"
password = "$password"
[log]
format = "plain"
level = "info"
timestamp_format = "2006年01月02日 15:04:05"
disable_color = true
EOF
    cat > "$CONF_DIR/frpc.auto.toml" << EOF
[common]
server_addr = "$ip"
server_port = 7000
token = "$token"
[auto_ssh]
type = "tcp"
local_ip = "127.0.0.1"
local_port = 22
remote_port = 6000
[log]
format = "plain"
level = "info"
timestamp_format = "2006年01月02日 15:04:05"
disable_color = true
EOF
    echo "$token" > "$CONF_DIR/token.vault" 2>/dev/null
    echo "$password" > "$CONF_DIR/password.vault" 2>/dev/null
    chmod 600 "$CONF_DIR"/*.vault 2>/dev/null
    log "配置生成: IP=$ip, 令牌=${#token}字节, 密码=${#password}字节"
}

{
    log "===== 安装开始 ===="
    mkdir -p "$CONF_DIR" "$MODDIR/logs" 2>/dev/null
    create_config
    log "✅ 安装完成，重启生效"
} >> "$LOG_FILE" 2>/dev/null

exit 0

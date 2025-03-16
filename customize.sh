#!/system/bin/sh
# 全自动安装引擎 | 零手动配置

MODDIR="$MODPATH"
CONF_DIR="$MODDIR/config"
LOG_FILE="$MODDIR/install.log"

# 日志函数（中文显示，增加详细信息）
log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [安装日志] $1" >> "$LOG_FILE"
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_FILE") ))秒前] $1" >> "$MODDIR/install_debug.log"
}

# 生成安全凭证（兼容无 openssl 环境）
generate_secret() {
    if command -v openssl >/dev/null; then
        log "✅ 使用 openssl 生成安全凭证，版本: $(openssl version 2>/dev/null)"
        openssl rand -hex 24 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | head -c 48
    else
        log "⚠️ 未找到 openssl，使用 /dev/urandom 生成凭证"
        head -c 48 /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-='
    fi
}

# 创建配置文件
create_config() {
    token=$(generate_secret)
    password=$(generate_secret)
    ip=$(curl -s icanhazip.com || echo "127.0.0.1")

    log "生成配置文件：服务端 IP=$ip，令牌长度=${#token}，密码长度=${#password}"

    # 服务端配置
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

    # 客户端配置
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

    # 保存凭证
    echo "$token" > "$CONF_DIR/token.vault"
    echo "$password" > "$CONF_DIR/password.vault"
    chmod 600 "$CONF_DIR"/*.vault
    log "✅ 安全凭证已生成并存储：$CONF_DIR/token.vault, $CONF_DIR/password.vault，权限: $(ls -l $CONF_DIR/token.vault | awk '{print $1}')"
}

# 主安装流程
{
    log "===== 智能安装开始 ====="
    mkdir -p "$CONF_DIR" "$MODDIR/logs"
    log "创建目录：$CONF_DIR, $MODDIR/logs，权限: $(ls -ld $CONF_DIR | awk '{print $1}')"
    create_config
    log "✅ 安装完成！重启生效"
} >> "$LOG_FILE" 2>&1

exit...

出错了，请重试。

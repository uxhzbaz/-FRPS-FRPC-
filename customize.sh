#!/system/bin/sh
# 全自动安装引擎 | 零手动配置

MODDIR="$MODPATH"
CONF_DIR="$MODDIR/config"
LOG_FILE="$MODDIR/install.log"

# 生成安全凭证
generate_secret() {
    openssl rand -hex 24 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | head -c 48
}

# 创建配置文件
create_config() {
    local token=$(generate_secret)
    local password=$(generate_secret)
    local ip=$(curl -s icanhazip.com || echo "127.0.0.1")

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
}

# 主安装流程
{
    echo "===== 智能安装开始 ====="
    mkdir -p "$CONF_DIR" "$MODDIR/logs"
    create_config
    chmod 600 "$CONF_DIR"/*.vault
    echo "✅ 安装完成！重启生效"
} > "$LOG_FILE" 2>&1

exit 0

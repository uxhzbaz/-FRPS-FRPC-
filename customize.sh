#!/system/bin/sh
# 智能安装引擎 | 自动配置 | 权限自动设置 | 增强日志

MODDIR="$MODPATH"
CONF_DIR="$MODDIR/config"
LOG_DIR="$MODDIR/logs"
BIN_DIR="$MODDIR/bin"
SCRIPT_DIR="$MODDIR/scripts"
DATE_TAG=$(date "+%Y%m%d_%H%M%S")

# 初始化日志
mkdir -p "$LOG_DIR" 2>/dev/null || { echo "无法创建日志目录 $LOG_DIR"; exit 1; }
exec 2>>"$LOG_DIR/install_error_$DATE_TAG.log"

# 日志函数
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$level] [安装] $message" >> "$LOG_DIR/install_$DATE_TAG.log" 2>/dev/null
    echo "[$(date '+%s')] [$level] $message" >> "$LOG_DIR/install_debug_$DATE_TAG.log" 2>/dev/null
}

# 生成高强度凭证
generate_secret() {
    if command -v openssl >/dev/null 2>&1; then
        log "INFO" "使用 openssl 生成凭证"
        openssl rand -hex 16 2>/dev/null | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c 32
    else
        log "WARN" "未找到 openssl，使用 /dev/urandom"
        head -c 32 /dev/urandom 2>/dev/null | tr -dc 'A-Za-z0-9!@#$%^&*()_+-='
    fi
}

# 创建配置文件
create_config() {
    log "INFO" "开始生成配置文件"
    mkdir -p "$CONF_DIR" 2>/dev/null || { log "ERROR" "无法创建配置目录 $CONF_DIR"; exit 1; }
    local token=$(generate_secret)
    local password=$(generate_secret)
    local ip=$(curl -s icanhazip.com 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null || echo "127.0.0.1")
    log "INFO" "生成配置: IP=$ip, 令牌长度=${#token}, 密码长度=${#password}"

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
user = "user"
server_addr = "$ip"
server_port = 7100
auth.method = "token"
auth.token = "$token"
login_fail_exit = false

[[proxies]]
name = "adb5"
type = "tcp"
local_ip = "127.0.0.1"
local_port = 5555
remote_port = 5555

[log]
format = "plain"
level = "info"
timestamp_format = "2006年01月02日 15:04:05"
disable_color = true
EOF

    # 存储凭证
    echo "$token" > "$CONF_DIR/token.vault" 2>/dev/null
    echo "$password" > "$CONF_DIR/password.vault" 2>/dev/null
    chmod 600 "$CONF_DIR"/*.vault 2>/dev/null
    log "INFO" "凭证存储: $CONF_DIR/token.vault, $CONF_DIR/password.vault, 权限: $(ls -l $CONF_DIR/*.vault 2>/dev/null)"
}

# 设置权限
set_permissions() {
    log "INFO" "开始设置文件权限"
    chmod 755 "$MODDIR" 2>/dev/null || log "WARN" "无法设置 $MODDIR 权限"
    [ -d "$BIN_DIR" ] && chmod 755 "$BIN_DIR"/* 2>/dev/null || log "WARN" "二进制目录 $BIN_DIR 为空"
    [ -d "$SCRIPT_DIR" ] && chmod 755 "$SCRIPT_DIR"/*.sh 2>/dev/null || log "WARN" "脚本目录 $SCRIPT_DIR 为空"
    chmod 755 "$MODDIR"/*.sh 2>/dev/null || log "WARN" "无法设置模块脚本权限"
    log "INFO" "权限设置完成: 模块目录 $(ls -ld $MODDIR 2>/dev/null), 二进制 $(ls -l $BIN_DIR/* 2>/dev/null), 脚本 $(ls -l $SCRIPT_DIR/*.sh 2>/dev/null)"
}

# 主程序
{
    log "INFO" "===== 安装开始 ====="
    create_config
    set_permissions
    log "INFO" "===== 安装完成 ====="
} &

exit 0

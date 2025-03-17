#!/system/bin/sh
# 全自动服务控制中枢 | 增强日志 | 安卓7-15兼容 | KernelSU 0.9.x-1.0.x

MODDIR="${0%/*}"
BIN_DIR="$MODDIR/bin"
LOG_DIR="$MODDIR/logs"
CONF_DIR="$MODDIR/config"
DATE_TAG=$(date "+%Y%m%d_%H%M%S")

# 初始化日志目录
mkdir -p "$LOG_DIR" 2>/dev/null || { echo "无法创建日志目录 $LOG_DIR"; exit 1; }
exec 2>>"$LOG_DIR/error_$DATE_TAG.log"

# 增强日志函数
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$level] [设备: $(getprop ro.product.model)] [架构: $(uname -m)] $message" >> "$LOG_DIR/service_$DATE_TAG.log" 2>/dev/null
    echo "[$(date '+%s')] [$level] $message" >> "$LOG_DIR/service_debug_$DATE_TAG.log" 2>/dev/null
}

# 环境检测
check_env() {
    log "INFO" "===== 环境检测开始 ====="
    [ -d "$BIN_DIR" ] || { log "ERROR" "二进制目录 $BIN_DIR 不存在"; exit 1; }
    [ -d "$CONF_DIR" ] || mkdir -p "$CONF_DIR" 2>/dev/null || { log "ERROR" "无法创建配置目录 $CONF_DIR"; exit 1; }
    log "INFO" "模块路径: $MODDIR"
    log "INFO" "系统版本: Android $(getprop ro.build.version.release)"
    log "INFO" "内核版本: $(uname -r)"
    log "INFO" "存储空间: $(df -h /data | awk 'NR==2 {print $4}') 可用"
    log "INFO" "网络状态: $(ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo '已连接' || echo '未连接')"
    if command -v curl >/dev/null 2>&1; then
        log "INFO" "✅ curl 可用"
    elif command -v wget >/dev/null 2>&1; then
        log "INFO" "✅ wget 可用"
    else
        log "WARN" "❌ 未找到 curl 或 wget，IP 检测可能失败"
    fi
    [ -f "$BIN_DIR/frps" ] && [ -f "$BIN_DIR/frpc" ] && log "INFO" "✅ frps 和 frpc 存在，权限: $(ls -l $BIN_DIR/frps $BIN_DIR/frpc)" || { log "ERROR" "❌ 未找到 frps 或 frpc"; exit 1; }
    [ -r "$CONF_DIR/frps.auto.toml" ] && [ -r "$CONF_DIR/frpc.auto.toml" ] && log "INFO" "✅ 配置文件可读" || { log "ERROR" "❌ 配置文件不可读"; exit 1; }
    log "INFO" "===== 环境检测完成 ====="
}

# 网络适配器（兼容 KernelSU 0.9.x-1.0.x）
network_adapter() {
    case $(getprop ro.build.version.sdk) in
        34|35) echo "nsenter --net=/proc/1/ns/net" ;;
        30|31|32|33) echo "unshare -m --propagation private" ;;
        *) [ -d /proc/1/ns/net ] && echo "nsenter --net=/proc/1/ns/net" || echo "" ;;
    esac
}

# 服务守护进程
start_service() {
    local service="$1"
    local config="$CONF_DIR/${service}.auto.toml"
    local log_file="$LOG_DIR/${service}.log"
    local net_cmd=$(network_adapter)
    local attempt=1

    while [ $attempt -le 3 ]; do
        if ! pgrep -f "$service" >/dev/null 2>&1; then
            log "INFO" "尝试启动 $service (第${attempt}次)，配置: $config"
            $net_cmd $BIN_DIR/$service -c "$config" >> "$log_file" 2>&1 &
            sleep 5
            if pgrep -f "$service" >/dev/null 2>&1; then
                local pid=$(pgrep -f "$service")
                local mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024}')
                log "INFO" "✅ $service 启动成功 (PID: $pid, 内存: ${mem:-未知}MB)"
                return 0
            else
                log "WARN" "❌ $service 启动失败，错误日志: $(tail -n 5 $log_file 2>/dev/null)"
            fi
        else
            local pid=$(pgrep -f "$service")
            local mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024}')
            log "INFO" "🟢 $service 已在运行 (PID: $pid, 内存: ${mem:-未知}MB)"
            return 0
        fi
        attempt=$((attempt + 1))
    done
    log "ERROR" "❌ $service 启动失败，达到最大重试次数"
    return 1
}

# 主程序
{
    log "INFO" "===== 服务启动 ====="
    check_env
    start_service frps || log "ERROR" "FRPS 启动失败！"
    start_service frpc || log "ERROR" "FRPC 启动失败！"
    ip=$(curl -s icanhazip.com 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null || echo "未知")
    log "INFO" "公网IP: $ip"
    log "INFO" "控制台: http://$ip:7500"
    password=$(awk -F= '/password/{print $2}' "$CONF_DIR/frps.auto.toml" 2>/dev/null | tr -d ' "')
    [ -n "$password" ] && log "INFO" "控制台密码: $password" || log "WARN" "未找到密码"
} &

# 启动后台任务
$MODDIR/scripts/health_check.sh &
$MODDIR/scripts/log_manager.sh &
$MODDIR/scripts/status_updater.sh &

exit 0

#!/system/bin/sh
# 服务健康监测 | 增强日志

MODDIR="/data/adb/modules/frp_ultimate"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d_%H%M%S")

# 日志函数
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$level] [健康检查] $message" >> "$LOG_DIR/health_$DATE_TAG.log" 2>/dev/null
    echo "[$(date '+%s')] [$level] $message" >> "$LOG_DIR/health_debug_$DATE_TAG.log" 2>/dev/null
}

# 检查服务状态
check_service() {
    local service="$1"
    local log_file="$LOG_DIR/${service}.log"
    if ! pgrep -f "$service" >/dev/null 2>&1; then
        log "WARN" "❌ $service 服务中断"
        log "INFO" "尝试重启 $service"
        $MODDIR/service.sh &
        sleep 5
        if pgrep -f "$service" >/dev/null 2>&1; then
            local pid=$(pgrep -f "$service")
            local mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024}')
            log "INFO" "✅ $service 重启成功 (PID: $pid, 内存: ${mem:-未知}MB)"
        else
            log "ERROR" "❌ $service 重启失败，错误日志: $(tail -n 10 $log_file 2>/dev/null)"
            log "INFO" "系统资源: CPU=$(top -n 1 | grep 'CPU' | awk '{print $2}' 2>/dev/null)%, 内存=$(free -m | awk 'NR==2{print $3}' 2>/dev/null)MB"
        fi
    else
        local pid=$(pgrep -f "$service")
        local mem=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024}')
        local uptime=$(ps -o etime= -p "$pid" 2>/dev/null)
        log "INFO" "🟢 $service 正常运行 (PID: $pid, 内存: ${mem:-未知}MB, 运行时间: $uptime)"
    fi
}

# 主循环
while true; do
    check_service frps
    check_service frpc
    sleep 60
done

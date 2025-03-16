#!/system/bin/sh
# 服务健康监测

MODDIR="/data/adb/modules/frp_ultimate"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")

log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [健康] $1" >> "$LOG_DIR/health_$DATE_TAG.log" 2>/dev/null
    echo "[$(( $(date +%s) - $(stat -c %Y "$LOG_DIR/health_$DATE_TAG.log" 2>/dev/null) ))秒前] $1" >> "$LOG_DIR/health_debug.log" 2>/dev/null
}

check_service() {
    local service=$1
    local log_file="$LOG_DIR/${service}.log"
    if ! pgrep -f "$service" >/dev/null 2>/dev/null; then
        log "❌ $service 中断"
        log "重启 $service"
        $MODDIR/service.sh &
        sleep 5
        if ! pgrep -f "$service" >/dev/null 2>/dev/null; then
            log "❌ 重启失败: $(tail -n 10 $log_file 2>/dev/null)"
        else
            log "✅ 重启成功 (PID: $(pgrep -f $service))"
        fi
    else
        log "🟢 $service 正常 (PID: $(pgrep -f $service))"
    fi
}

while true; do
    check_service frps
    check_service frpc
    sleep 60
done

#!/system/bin/sh
# 服务健康监测 | 中文日志

MODDIR="/data/adb/modules/frps_frpc"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数
log() {
    local message="$1"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [健康检查] $message" >> "$LOG_DIR/health_$DATE_TAG.log"
}

check_service() {
    local service=$1
    if ! pgrep -f $service >/dev/null; then
        log "❌ ${service} 服务中断"
        $MODDIR/service.sh &
        return 1
    fi
    log "🟢 ${service} 状态正常 (PID: $(pgrep -f $service))"
    return 0
}

while true; do
    check_service frps
    check_service frpc
    sleep 60
done

#!/system/bin/sh
# 服务健康监测 | 中文日志

MODDIR="/data/adb/modules/frps_frpc"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数
log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [健康检查] $1" >> "$LOG_DIR/health_$DATE_TAG.log"
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_DIR/health_$DATE_TAG.log") ))秒前] $1" >> "$LOG_DIR/health_debug.log"
}

check_service() {
    local service=$1
    local log_file="$LOG_DIR/${service}.log"
    if ! pgrep -f $service >/dev/null; then
        log "❌ ${service} 服务中断，当前进程数: $(pgrep -f $service | wc -l)"
        log "尝试重启 ${service}，时间: $(date '+%Y年%m月%d日 %H:%M:%S')"
        $MODDIR/service.sh &
        sleep 5
        if ! pgrep -f $service >/dev/null; then
            log "❌ 重启失败，错误日志: $(tail -n 10 $log_file)"
            log "系统资源使用: CPU=$(top -n 1 | grep 'CPU' | awk '{print $2}')%, 内存=$(free -m | awk 'NR==2{print $3}')MB"
        else
            log "✅ 重启成功，PID: $(pgrep -f $service), 内存使用: $(ps -o rss= -p $(pgrep -f $service) | awk '{print $1/1024}')MB"
        fi
    else
        log "🟢 ${service} 状态正常 (PID: $(pgrep -f $service), 运行时间: $(ps -o etime= -p $(pgrep -f $service)))"
        return 0
    fi
}

while true; do
    check_service frps
    check_service frpc
    sleep 60
done

#!/system/bin/sh
# 日志管理

MODDIR="/data/adb/modules/frp_ultimate"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")
MAX_DAYS=7

log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [日志] $1" >> "$LOG_DIR/log_manager_$DATE_TAG.log" 2>/dev/null
    echo "[$(( $(date +%s) - $(stat -c %Y "$LOG_DIR/log_manager_$DATE_TAG.log" 2>/dev/null) ))秒前] $1" >> "$LOG_DIR/log_manager_debug.log" 2>/dev/null
}

process_logs() {
    local file="$1"
    sed -i -r 's/\x1B\[[0-9;]*[mG]//g; s/([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}:.*)/\1年\2月\3日 \4/; s/ warning / 警告 /g; s/ error / 错误 /g; s/ info / 信息 /g; s/connected to server/连接到服务端/g; s/listening on port/监听端口/g; s/failed to start/启动失败/g' "$file" 2>/dev/null
    log "规范化: $file"
}

rotate_logs() {
    find "$LOG_DIR" -name "*.log" -mtime +$MAX_DAYS -exec gzip {} \; 2>/dev/null
    find "$LOG_DIR" -name "*.gz" -mtime +30 -exec rm -f {} \; 2>/dev/null
    log "轮转完成"
}

while true; do
    if [ $(date +%H) -eq 3 ]; then
        log "开始任务"
        find "$LOG_DIR" -name "*.log" -exec process_logs {} \;
        rotate_logs
        sleep 86400
    else
        sleep 3600
    fi
done

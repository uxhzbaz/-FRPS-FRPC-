#!/system/bin/sh
# 状态更新

MODDIR="/data/adb/modules/frp_ultimate"
STATUS_FILE="$MODDIR/module.prop"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")

log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [状态] $1" >> "$LOG_DIR/status_$DATE_TAG.log" 2>/dev/null
    echo "[$(( $(date +%s) - $(stat -c %Y "$LOG_DIR/status_$DATE_TAG.log" 2>/dev/null) ))秒前] $1" >> "$LOG_DIR/status_debug.log" 2>/dev/null
}

update_status() {
    local date=$(date +%Y-%m-%d)
    local last=$(grep "^updateTime=" "$STATUS_FILE" 2>/dev/null | cut -d'=' -f2 | cut -d' ' -f1)
    [ "$date" != "$last" ] && log "新日期: $date"
    frps_status=$(pgrep -f frps >/dev/null 2>/dev/null && echo "运行中" || echo "停止")
    frpc_status=$(pgrep -f frpc >/dev/null 2>/dev/null && echo "运行中" || echo "停止")
    ip=$(curl -s icanhazip.com 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null || echo "未知")
    sed -i "s/^description=.*/description=FRPS: $frps_status | FRPC: $frpc_status | IP地址: $ip/" "$STATUS_FILE" 2>/dev/null
    sed -i "s/^updateTime=.*/updateTime=$(date '+%Y-%m-%d %H:%M:%S')/" "$STATUS_FILE" 2>/dev/null
    log "更新: FRPS=$frps_status, FRPC=$frpc_status, IP=$ip"
}

while true; do
    update_status
    sleep 30
done

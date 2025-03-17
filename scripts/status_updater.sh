#!/system/bin/sh
# 状态更新 | 精简显示 | 增强日志

MODDIR="/data/adb/modules/frp_ultimate"
STATUS_FILE="$MODDIR/module.prop"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d_%H%M%S")

# 日志函数
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$level] [状态更新] $message" >> "$LOG_DIR/status_$DATE_TAG.log" 2>/dev/null
    echo "[$(date '+%s')] [$level] $message" >> "$LOG_DIR/status_debug_$DATE_TAG.log" 2>/dev/null
}

# 状态更新
update_status() {
    local latest_log=$(ls -t "$LOG_DIR/service_"*".log" 2>/dev/null | head -1)
    local frps_status=$(pgrep -f frps >/dev/null 2>&1 && echo "运行中" || echo "停止")
    local frpc_status=$(pgrep -f frpc >/dev/null 2>&1 && echo "运行中" || echo "停止")
    local ip=$(grep "公网IP:" "$latest_log" 2>/dev/null | tail -1 | awk -F': ' '{print $2}' || echo "未知")
    sed -i \
        -e "s/^description=.*/description=FRPS: $frps_status | FRPC: $frpc_status | IP: $ip/" \
        -e "s/^updateTime=.*/updateTime=$(date '+%Y-%m-%d %H:%M:%S')/" \
        "$STATUS_FILE" 2>/dev/null || log "ERROR" "无法更新 $STATUS_FILE"
    log "INFO" "状态更新: FRPS=$frps_status, FRPC=$frpc_status, IP=$ip"
}

# 主循环
while true; do
    update_status
    sleep 30
done

#!/system/bin/sh
# 模块状态实时更新 | 中文显示

MODDIR="/data/adb/modules/frps_frpc"
STATUS_FILE="$MODDIR/module.prop"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数
log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [状态更新] $1" >> "$LOG_DIR/status_$DATE_TAG.log"
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_DIR/status_$DATE_TAG.log") ))秒前] $1" >> "$LOG_DIR/status_debug.log"
}

# 每日刷新函数
update_status() {
    local current_date=$(date +%Y-%m-%d)
    local last_update=$(grep "^updateTime=" "$STATUS_FILE" | cut -d'=' -f2 | cut -d' ' -f1)
    if [ "$current_date" != "$last_update" ] || [ -z "$last_update" ]; then
        log "检测到新日期 $current_date，刷新状态..."
    fi
    # 获取服务状态
    frps_status=$(pgrep -f frps && echo "🟢 运行中" || echo "🔴 停止")
    frpc_status=$(pgrep -f frpc && echo "🟢 运行中" || echo "🔴 停止")
    ip=$(curl -s icanhazip.com || echo "未知")
    password=$(awk -F= '/password/{print $2}' $CONF_DIR/frps.auto.toml | tr -d ' "')

    # 更新 module.prop
    sed -i \
        -e "s/^status=.*/status=FRPS: $frps_status | FRPC: $frpc_status/" \
        -e "s/^description=.*/description=FRPS: $frps_status | FRPC: $frpc_status/" \
        -e "s/^serverIP=.*/serverIP=$ip/" \
        -e "s/^dashboardURL=.*/dashboardURL=http:\/\/$ip:7500/" \
        -e "s/^dashboardPassword=.*/dashboardPassword=$password/" \
        -e "s/^updateTime=.*/updateTime=$(date '+%Y-%m-%d %H:%M:%S')/" \
        "$STATUS_FILE"
    log "状态更新完成：FRPS=$frps_status, FRPC=$frpc_status, IP=$ip, 密码=$password"
}

while true; do
    update_status
    sleep 30
done

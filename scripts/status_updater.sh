#!/system/bin/sh
# 模块状态实时更新 | 中文显示

MODDIR="/data/adb/modules/frps_frpc"
STATUS_FILE="$MODDIR/module.prop"

# 每日刷新函数
update_status() {
    local current_date=$(date +%Y-%m-%d)
    local last_update=$(grep "^updateTime=" "$STATUS_FILE" | cut -d'=' -f2 | cut -d' ' -f1)
    if [ "$current_date" != "$last_update" ] || [ -z "$last_update" ]; then
        # 获取服务状态
        frps_status=$(pgrep -f frps && echo "🟢 运行中" || echo "🔴 停止")
        frpc_status=$(pgrep -f frpc && echo "🟢 运行中" || echo "🔴 停止")
        ip=$(curl -s icanhazip.com || echo "未知")

        # 更新 module.prop
        sed -i \
            -e "s/^status=.*/status=FRPS: $frps_status | FRPC: $frpc_status/" \
            -e "s/^serverIP=.*/serverIP=$ip/" \
            -e "s/^dashboardURL=.*/dashboardURL=http:\/\/$ip:7500/" \
            -e "s/^updateTime=.*/updateTime=$(date '+%Y-%m-%d %H:%M:%S')/" \
            "$STATUS_FILE"
    fi
}

while true; do
    update_status
    sleep 30
done

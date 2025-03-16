#!/system/bin/sh
# 中文日志管理 | 格式规范化

MODDIR="/data/adb/modules/frps_frpc"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")
MAX_DAYS=7

# 日志格式规范化（强制中文）
process_logs() {
    local file="$1"
    sed -i -r \
        -e 's/\x1B\[[0-9;]*[mG]//g' \
        -e 's/([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}:.*)/\1年\2月\3日 \4/' \
        -e 's/ warning / 警告 /g' \
        -e 's/ error / 错误 /g' \
        -e 's/ info / 信息 /g' \
        -e 's/connected to server/连接到服务端/g' \
        -e 's/listening on port/监听端口/g' \
        -e 's/failed to start/启动失败/g' \
        "$file"
}

# 日志轮转
rotate_logs() {
    find "$LOG_DIR" -name "*.log" -mtime +$MAX_DAYS -exec gzip {} \;
    find "$LOG_DIR" -name "*.gz" -mtime +30 -delete
}

# 主循环
while true; do
    if [ $(date +%H) -eq 3 ]; then
        find "$LOG_DIR" -name "*.log" -exec process_logs {} \;
        rotate_logs
        sleep 86400  # 24小时
    else
        sleep 3600  # 1小时检查一次
    fi
done

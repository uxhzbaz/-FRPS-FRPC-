#!/system/bin/sh
# 日志管理 | 增强处理

MODDIR="/data/adb/modules/frp_ultimate"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d_%H%M%S")
MAX_DAYS=7

# 日志函数
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$level] [日志管理] $message" >> "$LOG_DIR/log_manager_$DATE_TAG.log" 2>/dev/null
    echo "[$(date '+%s')] [$level] $message" >> "$LOG_DIR/log_manager_debug_$DATE_TAG.log" 2>/dev/null
}

# 日志规范化
process_logs() {
    local file="$1"
    [ -f "$file" ] || return
    sed -i -r \
        -e 's/\x1B\[[0-9;]*[mG]//g' \
        -e 's/([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}:.*)/\1年\2月\3日 \4/' \
        -e 's/ warning / 警告 /g' \
        -e 's/ error / 错误 /g' \
        -e 's/ info / 信息 /g' \
        -e 's/connected to server/连接到服务端/g' \
        -e 's/listening on port/监听端口/g' \
        -e 's/failed to start/启动失败/g' \
        "$file" 2>/dev/null
    log "INFO" "规范化日志文件: $file, 大小: $(ls -lh $file 2>/dev/null | awk '{print $5}')"
}

# 日志轮转
rotate_logs() {
    local log_files=$(find "$LOG_DIR" -name "*.log" -mtime +$MAX_DAYS 2>/dev/null)
    [ -n "$log_files" ] && {
        for file in $log_files; do
            gzip "$file" 2>/dev/null && log "INFO" "压缩日志: $file.gz, 大小: $(ls -lh $file.gz 2>/dev/null | awk '{print $5}')"
        done
    } || log "INFO" "无过期日志需要压缩"
    local old_gz_files=$(find "$LOG_DIR" -name "*.gz" -mtime +30 2>/dev/null)
    [ -n "$old_gz_files" ] && {
        for file in $old_gz_files; do
            rm -f "$file" 2>/dev/null && log "INFO" "删除过期压缩日志: $file"
        done
    } || log "INFO" "无过期压缩日志需要删除"
}

# 主循环
while true; do
    if [ $(date +%H) -eq 3 ]; then
        log "INFO" "开始日志管理任务"
        find "$LOG_DIR" -name "*.log" -exec process_logs {} \; 2>/dev/null
        rotate_logs
        log "INFO" "日志管理完成，总大小: $(du -sh $LOG_DIR 2>/dev/null | awk '{print $1}')"
        sleep 86400
    else
        sleep 3600
    fi
done

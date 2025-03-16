#!/system/bin/sh
# 中文日志管理 | 格式规范化

MODDIR="/data/adb/modules/frps_frpc"
LOG_DIR="$MODDIR/logs"
DATE_TAG=$(date "+%Y%m%d")
MAX_DAYS=7

# 日志函数
log() {
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [日志管理] $1" >> "$LOG_DIR/log_manager_$DATE_TAG.log"
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_DIR/log_manager_$DATE_TAG.log") ))秒前] $1" >> "$LOG_DIR/log_manager_debug.log"
}

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
    log "规范化日志文件：$file，大小: $(ls -lh $file | awk '{print $5}')"
}

# 日志轮转
rotate_logs() {
    local log_files
    log_files=$(find "$LOG_DIR" -name "*.log" -mtime +$MAX_DAYS)
    if [ -n "$log_files" ]; then
        for file in $log_files; do
            gzip "$file"
            log "压缩日志文件：$file.gz，大小: $(ls -lh ${file}.gz | awk '{print $5}')"
        done
    else
        log "无过期日志文件需要压缩，当前日志数: $(ls $LOG_DIR/*.log 2>/dev/null | wc -l)"
    fi
    local old_gz_files
    old_gz_files=$(find "$LOG_DIR" -name "*.gz" -mtime +30)
    if [ -n "$old_gz_files" ]; then
        for file in $old_gz_files; do
            rm -f "$file"
            log "删除过期压缩日志：$file，剩余压缩文件: $(ls $LOG_DIR/*.gz 2>/dev/null | wc -l)"
        done
    else
        log "无过期压缩日志需要删除"
    fi
}

# 主循环
while true; do
    if [ $(date +%H) -eq 3 ]; then
        log "开始日志管理任务，当前时间: $(date '+%Y年%m月%d日 %H:%M:%S')"
        find "$LOG_DIR" -name "*.log" -exec process_logs {} \;
        rotate_logs
        log "日志管理任务完成，总日志目录大小: $(du -sh $LOG_DIR | awk '{print $1}')"
        sleep 86400  # 24小时
    else
        sleep 3600  # 1小时检查一次
    fi
done

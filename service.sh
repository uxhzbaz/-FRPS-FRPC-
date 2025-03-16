#!/system/bin/sh
# 全自动服务控制中枢 | 中文日志 | 安卓7-15适配 | 支持 KernelSU 0.9.x-1.0.x

MODDIR="${0%/*}"
LOG_DIR="$MODDIR/logs"
CONF_DIR="$MODDIR/config"
BIN_DIR="$MODDIR/bin"
TOKEN_FILE="$CONF_DIR/token.vault"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数
log() {
    local message="$1"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$(getprop ro.product.model)] [服务管理] $message" >> "$LOG_DIR/service_$DATE_TAG.log" 2>/dev/null
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_DIR/service_$DATE_TAG.log" 2>/dev/null) ))秒前] $message" >> "$LOG_DIR/service_debug.log" 2>/dev/null
}

# 环境检测
check_env() {
    mkdir -p "$LOG_DIR" "$CONF_DIR" 2>/dev/null
    log "======== 环境检测报告 ========"
    log "模块路径: $MODDIR"
    log "设备型号: $(getprop ro.product.model)"
    log "系统版本: Android $(getprop ro.build.version.release)"
    log "内核版本: $(uname -r)"
    log "CPU架构: $(uname -m)"
    log "存储空间: $(df -h /data | awk 'NR==2 {print $4}') 可用"
    if command -v curl >/dev/null 2>/dev/null; then
        log "✅ curl 可用"
    elif command -v wget >/dev/null 2>/dev/null; then
        log "✅ wget 可用"
    else
        log "⚠️ 未找到 curl 或 wget，IP 检测可能失败"
    fi
    [ -f "$BIN_DIR/frps" ] && [ -f "$BIN_DIR/frpc" ] && log "✅ frps 和 frpc 存在" || { log "❌ 未找到 frps 或 frpc"; exit 1; }
    [ -r "$CONF_DIR/frps.auto.toml" ] && [ -r "$CONF_DIR/frpc.auto.toml" ] && log "✅ 配置文件可读" || { log "❌ 配置文件不可读"; exit 1; }
}

# 网络适配器（兼容 KernelSU 0.9.x-1.0.x）
network_adapter() {
    case $(getprop ro.build.version.sdk) in
        34|35) echo "nsenter --net=/proc/1/ns/net" ;;
        30|31|32|33) echo "unshare -m --propagation private" ;;
        *) [ -d /proc/1/ns/net ] && echo "nsenter --net=/proc/1/ns/net" || echo "" ;;
    esac
}

# 服务守护
service_guard() {
    local service=$1
    local config="$CONF_DIR/${service}.auto.toml"
    local log_file="$LOG_DIR/${service}.log"
    local net_cmd=$(network_adapter)
    for attempt in 1 2 3; do
        if ! pgrep -f "$service" >/dev/null 2>/dev/null; then
            log "🔄 第$attempt次尝试启动 $service"
            $net_cmd $BIN_DIR/$service -c "$config" >> "$log_file" 2>&1 &
            sleep 5
        else
            log "🟢 $service 运行中 (PID: $(pgrep -f $service))"
            return 0
        fi
    done
    log "❌ $service 启动失败"
    log "错误: $(tail -n 10 $log_file 2>/dev/null)"
    return 1
}

# 主程序
{
    check_env
    log "网络模式: $(network_adapter | grep -q nsenter && echo '容器' || echo '直连')"
    log "安全令牌: $(cat $TOKEN_FILE 2>/dev/null || echo '未生成')"
    service_guard frps
    service_guard frpc
    ip=$(curl -s icanhazip.com 2>/dev/null || wget -qO- icanhazip.com 2>/dev/null || echo "127.0.0.1")
    password=$(awk -F= '/password/{print $2}' $CONF_DIR/frps.auto.toml 2>/dev/null | tr -d ' ')
    log "🌐 IP: $ip:6000"
    log "🕹️ 控制台: http://$ip:7500"
    log "🗝️ 密码: $password"
} >> "$LOG_DIR/service_$DATE_TAG.log" 2>/dev/null

# 后台任务
$MODDIR/scripts/health_check.sh &
$MODDIR/scripts/log_manager.sh &
$MODDIR/scripts/status_updater.sh &

exit 0

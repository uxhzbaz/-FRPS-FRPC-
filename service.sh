#!/system/bin/sh
# 全自动服务控制中枢 | 中文日志 | 安卓7-15适配

MODDIR="${0%/*}"
LOG_DIR="$MODDIR/logs"
CONF_DIR="$MODDIR/config"
TOKEN_FILE="$CONF_DIR/token.vault"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数（中文显示）
log() {
    local message="$1"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$(getprop ro.product.model)] $message" >> "$LOG_DIR/service_$DATE_TAG.log"
}

# 网络适配器
network_adapter() {
    case $(getprop ro.build.version.sdk) in
        34|35) echo "nsenter --net=/proc/1/ns/net" ;;
        30|31|32|33) echo "unshare -m --propagation private" ;;
        *) echo "" ;;
    esac
}

# 服务守护进程
service_guard() {
    local service=$1
    local config="$CONF_DIR/${service}.auto.toml"
    local log_file="$LOG_DIR/${service}.log"
    local net_cmd=$(network_adapter)
    for i in {1..3}; do
        if ! pgrep -f $service >/dev/null; then
            log "🔄 第${i}次尝试启动 ${service}..."
            $net_cmd $MODDIR/bin/arm64-v8a/$service -c $config >> "$log_file" 2>&1 &
            sleep 5
        else
            log "🟢 ${service} 运行中 (PID: $(pgrep -f $service))"
            return 0
        fi
    done
    log "❌ ${service} 启动失败！请检查日志 $log_file"
    return 1
}

# 主程序
{
    # 初始化环境
    mkdir -p "$LOG_DIR" "$CONF_DIR"
    log "======== 设备启动报告 ========"
    log "设备型号: $(getprop ro.product.model)"
    log "系统版本: Android $(getprop ro.build.version.release)"
    log "网络模式: $(network_adapter | grep -q 'nsenter' && echo 'Android 14+原生容器' || echo '传统直连')"
    log "安全令牌: $(cat $TOKEN_FILE 2>/dev/null || echo '尚未生成')"

    # 启动服务
    service_guard frps
    service_guard frpc

    # 输出访问信息
    local ip=$(curl -s icanhazip.com || echo "127.0.0.1")
    log "🌐 公网访问地址: ${ip}:6000"
    log "🕹️ 控制台地址: http://${ip}:7500"
    log "🗝️ 控制台密码: $(awk -F= '/password/{print $2}' $CONF_DIR/frps.auto.toml | tr -d ' \"')"
} >> "$LOG_DIR/service_$DATE_TAG.log" 2>&1

# 启动后台任务
$MODDIR/scripts/health_check.sh &
$MODDIR/scripts/log_manager.sh &
$MODDIR/scripts/status_updater.sh &

exit 0

#!/system/bin/sh
# 全自动服务控制中枢 | 中文日志 | 安卓7-15适配

MODDIR="${0%/*}"
LOG_DIR="$MODDIR/logs"
CONF_DIR="$MODDIR/config"
TOKEN_FILE="$CONF_DIR/token.vault"
DATE_TAG=$(date "+%Y%m%d")

# 日志函数（中文显示，增加详细信息）
log() {
    local message="$1"
    echo "[$(date '+%Y年%m月%d日 %H:%M:%S')] [$(getprop ro.product.model)] [服务管理] $message" >> "$LOG_DIR/service_$DATE_TAG.log"
    echo "[$DATE_TAG $(( $(date +%s) - $(stat -c %Y "$LOG_DIR/service_$DATE_TAG.log") ))秒前] $message" >> "$LOG_DIR/service_debug.log"
}

# 环境检测
check_env() {
    log "======== 环境检测报告 ========"
    log "设备型号: $(getprop ro.product.model)"
    log "系统版本: Android $(getprop ro.build.version.release)"
    log "内核版本: $(uname -r)"
    log "CPU架构: $(uname -m)"
    log "存储空间: $(df -h /data | awk 'NR==2 {print $4}') 可用"
    if command -v curl >/dev/null; then
        log "✅ curl 可用，IP 检测功能正常"
    else
        log "❌ curl 不可用，IP 检测可能失败，请安装 curl"
    fi
    if [ -f "$MODDIR/bin/arm64-v8a/frps" ] && [ -f "$MODDIR/bin/arm64-v8a/frpc" ]; then
        log "✅ frps 和 frpc 可执行文件存在，权限: $(ls -l $MODDIR/bin/arm64-v8a/frps | awk '{print $1}')"
    else
        log "❌ 未找到 frps 或 frpc 可执行文件，请检查 $MODDIR/bin/arm64-v8a/ 目录"
        exit 1
    fi
    if [ -r "$CONF_DIR/frps.auto.toml" ] && [ -r "$CONF_DIR/frpc.auto.toml" ]; then
        log "✅ 配置文件存在且可读，权限: $(ls -l $CONF_DIR/frps.auto.toml | awk '{print $1}')"
    else
        log "❌ 配置文件不可读，请检查 $CONF_DIR/ 目录权限"
        exit 1
    fi
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
    local attempt=1
    while [ $attempt -le 3 ]; do
        if ! pgrep -f $service >/dev/null; then
            log "🔄 第${attempt}次尝试启动 ${service}，配置: $config"
            $net_cmd $MODDIR/bin/arm64-v8a/$service -c "$config" >> "$log_file" 2>&1 &
            sleep 5
            log "启动后等待 5 秒，检查进程..."
        else
            log "🟢 ${service} 运行中 (PID: $(pgrep -f $service), 内存使用: $(ps -o rss= -p $(pgrep -f $service) | awk '{print $1/1024}')MB)"
            return 0
        fi
        attempt=$((attempt + 1))
    done
    log "❌ ${service} 启动失败！请检查日志 $log_file"
    log "错误详情: $(tail -n 10 $log_file)"
    return 1
}

# 主程序
{
    # 初始化环境
    mkdir -p "$LOG_DIR" "$CONF_DIR"
    log "======== 设备启动报告 ========"
    check_env
    log "网络模式: $(network_adapter | grep -q 'nsenter' && echo 'Android 14+原生容器' || echo '传统直连')"
    log "安全令牌: $(cat $TOKEN_FILE 2>/dev/null || echo '尚未生成')"

    # 启动服务
    service_guard frps
    service_guard frpc

    # 输出访问信息
    ip=$(curl -s icanhazip.com || echo "127.0.0.1")
    password=$(awk -F= '/password/{print $2}' $CONF_DIR/frps.auto.toml | tr -d ' "')
    log "🌐 公网访问地址: ${ip}:6000"
    log "🕹️ 控制台地址: http://${ip}:7500"
    log "🗝️ 控制台密码: $password (已记录在 module.prop)"
} >> "$LOG_DIR/service_$DATE_TAG.log" 2>&1

# 启动后台任务
$MODDIR/scripts/health_check.sh &
$MODDIR/scripts/log_manager.sh &
$MODDIR/scripts/status_updater.sh &

exit 0

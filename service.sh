#!/system/bin/sh
MODDIR="${0%/*}"
LOG_DIR="$MODDIR/logs"
TOKEN_FILE="$MODDIR/config/.vault"

# 加载工具函数
. $MODDIR/scripts/utils.sh

# 动态状态更新
update_status() {
  local status=$( [ $(pgrep -c -f 'frps|frpc') -eq 2 ] && echo "✅运行中" || echo "❌异常" )
  local conn_count=$(grep -c "连接建立" $LOG_DIR/frp.log 2>/dev/null)
  sed -i "s/#{status}#/$status/;s/#{conn}#/$conn_count次/" $MODDIR/module.prop
}

# 服务管理器
service_mgr() {
  nohup $MODDIR/bin/$1 -c $MODDIR/config/$1.auto.toml >> $LOG_DIR/$1.log 2>&1 &
  for i in {1..3}; do
    sleep 2
    if pgrep -f $1 >/dev/null; then
      log "$1 服务启动成功 PID:$(pgrep -f $1)"
      return 0
    fi
  done
  log "❌$1 服务启动失败！"
  return 1
}

# 主程序
{
  mkdir -p $LOG_DIR
  gen_config
  log "======= 系统启动 ======="
  log "设备: $(getprop ro.product.model)"
  log "安卓版本: $(getprop ro.build.version.release)"
  
  # 启动服务
  service_mgr frps && service_mgr frpc
  
  # 状态守护
  while true; do
    update_status
    log_rotate
    sleep 30
  done
} &

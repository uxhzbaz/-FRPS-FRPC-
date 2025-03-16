#!/system/bin/sh
# 通用工具函数库

# 带颜色日志
log() {
  local code="\033[0;32m"
  [ "${1:0:1}" = "❌" ] && code="\033[0;31m"
  echo -e "$(date '+%m-%d %H:%M:%S') $code$1\033[0m" >> $LOG_DIR/frp.log
}

# 配置生成
gen_config() {
  [ -f $TOKEN_FILE ] || openssl rand -hex 24 > $TOKEN_FILE
  local token=$(cat $TOKEN_FILE)
  
  cat > $MODDIR/config/frps.auto.toml << EOF
[common]
bind_port = 7000
token = "$token"

[prometheus]
enable = true
port = 7400
EOF

  cat > $MODDIR/config/frpc.auto.toml << EOF
[common]
server_addr = "127.0.0.1"
server_port = 7000
token = "$token"

[ssh]
type = "tcp"
local_ip = "127.0.0.1"
local_port = 22
remote_port = 6000
EOF
}

# 日志轮转
log_rotate() {
  find $LOG_DIR -name "*.log" -size +5M -exec gzip {} \;
  find $LOG_DIR -name "*.gz" -mtime +7 -delete
}

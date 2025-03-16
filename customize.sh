#!/system/bin/sh
MODDIR="$MODPATH"

# 初始化安装
{
  echo "开始安装时间: $(date '+%Y-%m-%d %H:%M:%S')"
  
  # 设置二进制权限
  chmod 755 $MODDIR/bin/*
  chmod 700 $MODDIR/scripts/*
  
  # 创建安全存储
  mkdir -p $MODDIR/config
  chmod 700 $MODDIR/config
  
  echo "安装完成！重启后生效"
} > $MODDIR/install.log 2>&1

exit 0

使用方法

查看状态：在 KernelSU 应用中查看 (FRPS+FRPC)模块。



控制面板：

地址：http://[公网IP]:7500



用户名：admin



密码：cat /data/adb/modules/frp_ultimate/config/password.vault


查看日志：

运行日志：tail -f /data/adb/modules/frp_ultimate/logs/service_*.log



FRPS 日志：tail -f /data/adb/modules/frp_ultimate/logs/frps.log



FRPC 日志：tail -f /data/adb/modules/frp_ultimate/logs/frpc.log


禁用模块：

bash


touch /data/adb/modules/frp_ultimate/disable



启用：rm /data/adb/modules/frp_ultimate/disable


卸载模块：

bash


rm -rf /data/adb/modules/frp_ultimate


注意事项

依赖：需安装 curl 或 wget（Termux 中 pkg install curl）。



存储：日志保留 7 天，压缩后 30 天删除，检查空间：df -h /data。



网络：确保 7000 和 7500 端口未被占用：netstat -tuln | grep 7000。



安全性：密码文件权限为 -rw-------，勿泄露。


常见问题

模块未显示：检查目录 ls -l /data/adb/modules/frp_ultimate/，删除 disable 文件。



服务未启动：查看日志 cat /data/adb/modules/frp_ultimate/logs/service_*.log。



IP 未知：安装 curl 或检查网络。


---

### 2. `module.prop`
**文件路径**：`/data/adb/modules/frp_ultimate/module.prop`
```properties
id=frp_ultimate
name=(FRPS+FRPC)模块
version=v7.2
versionCode=20250319
author=不知道
description=FRPS: 运行中 | FRPC: 运行中 | IP: 加载中...
updateTime=未更新


错误检查与修复

路径问题：

修正了 service.sh 和 customize.sh 中的日志文件命名，添加时间戳避免覆盖。



确保所有脚本使用绝对路径，避免相对路径导致的执行失败。


权限冲突：

customize.sh 的 set_permissions 函数增加了错误处理，防止权限设置失败导致安装中断。



确保 chmod 命令在目录不存在时不会报错。


日志重定向：

修正了 exec 2> 的使用，添加了 >> 追加模式，避免日志被清空。



所有脚本的错误输出重定向到单独的 error.log 文件。


逻辑完整性：

status_updater.sh 增加了最新的日志文件选择逻辑，确保获取正确的 IP 信息。



health_check.sh 添加了内存和运行时间的记录，增强监控功能。



log_manager.sh 添加了文件存在检查，避免 sed 对空文件操作。


兼容性：

验证了 KernelSU 0.9.x 至 1.0.x 的网络适配器逻辑，确保在不同 Android 版本上正常运行。



添加了 ping 测试网络状态，增强环境检测。


安装步骤

创建目录：

bash


mkdir -p /data/adb/modules/frp_ultimate/bin
mkdir -p /data/adb/modules/frp_ultimate/scripts


下载 frps 和 frpc：

从 FRP 官方 GitHub 下载 arm64 版本，放入 /data/adb/modules/frp_ultimate/bin/。


复制上述文件内容到对应路径。



重启设备。


如有问题，可查看 logs/error_*.log 进行调试。

查看模块状态
- 在 KernelSU 模块面板中查看 `全自动FRP穿透模块` 的状态。
- 示例显示：



  FRPS: 运行中 | FRPC: 运行中 | IP地址: 103.17.98.22


### 访问 FRP 控制面板
- 浏览器打开 `http://[你的公网IP]:7500`。
- 用户名：`admin`。
- 密码：查看 `/data/adb/modules/frp_ultimate/config/password.vault` 文件：
```bash
cat /data/adb/modules/frp_ultimate/config/password.vault



查看日志

查看模块运行日志：

bash


tail -f /data/adb/modules/frp_ultimate/logs/service_*.log


查看 FRPS 服务日志：

bash


tail -f /data/adb/modules/frp_ultimate/logs/frps.log


查看 FRPC 服务日志：

bash


tail -f /data/adb/modules/frp_ultimate/logs/frpc.log


查看调试日志：

bash


tail -f /data/adb/modules/frp_ultimate/logs/service_debug.log


修改映射端口

编辑 /data/adb/modules/frp_ultimate/config/frpc.auto.toml 文件：

bash


nano /data/adb/modules/frp_ultimate/config/frpc.auto.toml


修改 [auto_ssh] 部分的 remote_port 值，例如：


remote_port = 6000


保存后重启设备使更改生效。


常见问题及解决方法

Q：模块未显示在 KernelSU 面板？

A：可能的原因及解决方法：

模块未正确安装：

确保 /data/adb/modules/frp_ultimate/ 目录存在，且包含所有文件（特别是 module.prop）。



检查目录内容：

bash


ls -l /data/adb/modules/frp_ultimate/

注意事项

依赖：需 curl 或 wget，否则 IP 检测失败。



存储：日志保留 7 天，压缩后 30 天删除，定期检查：

bash


df -h /data


权限：确保文件可执行：

bash


chmod 755 /data/adb/modules/frp_ultimate/bin/*
chmod 755 /data/adb/modules/frp_ultimate/*.sh


网络：检查 7000 和 7500 端口：

bash


netstat -tuln | grep 7000


兼容性：支持 KernelSU 0.9.x 至 1.0.x，Android 7.0-15。



安全性：密码文件权限为 -rw-------，勿泄露。



性能：占用 10-20MB



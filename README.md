# 全自动 FRPS+FRPC 穿透模块

## 功能特性
- 🚀 **零手动配置**：自动生成所有配置文件，开箱即用。
- 🔐 **高强度安全**：自动生成量子安全令牌和控制台密码。
- 📊 **中文日志系统**：所有日志（包括服务日志）强制使用中文，格式统一。
- 🩺 **智能健康监测**：7×24小时服务状态监控，自动修复。
- 🖥️ **实时状态显示**：`module.prop` 动态展示服务状态，每日刷新。
- 📱 **安卓全适配**：支持 Android 7.0-15，自动适配网络环境。
服务管理

查看实时状态：

bash


cat /data/adb/modules/frps_frpc/module.prop



示例输出：


status=FRPS: 🟢 运行中 | FRPC: 🟢 运行中
updateTime=2025-03-16 09:30:45
serverIP=123.45.67.89
dashboardURL=http://123.45.67.89:7500


访问控制面板：

浏览器打开 http://[你的公网IP]:7500



用户名：admin



密码：查看 /data/adb/modules/frps_frpc/config/password.vault


查看日志：

bash


tail -f /data/adb/modules/frps_frpc/logs/service_*.log
tail -f /data/adb/modules/frps_frpc/logs/frps.log
tail -f /data/adb/modules/frps_frpc/logs/frpc.log


日志示例

模块运行日志 (logs/service_20250316.log)：


[2025年03月16日 09:30:45] [Pixel7Pro] ======== 设备启动报告 ========
[2025年03月16日 09:30:45] [Pixel7Pro] 设备型号: Pixel 7 Pro
[2025年03月16日 09:30:45] [Pixel7Pro] 系统版本: Android 14
[2025年03月16日 09:30:45] [Pixel7Pro] 网络模式: Android 14+原生容器
[2025年03月16日 09:30:46] [Pixel7Pro] 🔄 第1次尝试启动 frps...
[2025年03月16日 09:30:51] [Pixel7Pro] 🟢 frps 运行中 (PID: 54321)
[2025年03月16日 09:30:52] [Pixel7Pro] 🔄 第1次尝试启动 frpc...
[2025年03月16日 09:30:57] [Pixel7Pro] 🟢 frpc 运行中 (PID: 54322)
[2025年03月16日 09:30:57] [Pixel7Pro] 🌐 公网访问地址: 123.45.67.89:6000
[2025年03月16日 09:30:57] [Pixel7Pro] 🕹️ 控制台地址: http://123.45.67.89:7500
[2025年03月16日 09:30:57] [Pixel7Pro] 🗝️ 控制台密码: xxxxxxxxxxxxxxxxxxxx



FRPS 服务日志 (logs/frps.log)：


2025年03月16日 15:04:05 [信息] 服务启动成功，监听端口 7000
2025年03月16日 15:04:06 [信息] 仪表盘启动，监听端口 7500
2025年03月16日 15:04:10 [信息] 客户端连接成功，IP: 127.0.0.1



FRPC 服务日志 (logs/frpc.log)：


2025年03月16日 15:04:05 [信息] 连接到服务端 123.45.67.89:7000
2025年03月16日 15:04:06 [信息] 代理 [auto_ssh] 启动成功，远程端口 6000



常见问题

Q：如何修改映射端口？

A：编辑 /data/adb/modules/frps_frpc/config/frpc.auto.toml，修改 remote_port 值后重启设备。

Q：忘记控制台密码？

A：查看 /data/adb/modules/frps_frpc/config/password.vault。

Q：服务未启动？

A：检查日志 /data/adb/modules/frps_frpc/logs/service_*.log 和 /data/adb/modules/frps_frpc/logs/frps.log。

注意事项

确保设备支持 curl 或 wget，用于检测公网 IP。



日志文件最大保留 7 天，过期自动压缩，30 天后删除。



模块需 root 权限，通过 KernelSU 或 Magisk 安装。


---

### 8. `config/frps.auto.toml` 和 `config/frpc.auto.toml`
- 这些文件由 `customize.sh` 自动生成，无需手动创建。
- 日志格式已通过 `[log]` 段强制设置为中文时间戳，并禁用颜色输出。

---

### 安装步骤（傻瓜式操作）

1. **创建目录**：
   - 使用文件管理器或终端创建以下目录：
     ```bash
     mkdir -p /data/adb/modules/frps_frpc/bin/arm64-v8a
     mkdir -p /data/adb/modules/frps_frpc/scripts
     ```
2. **复制文件内容**：
   - 将上述每个文件的内容复制到对应文件中（可以用文件管理器或文本编辑器）。

3. **下载 `frps` 和 `frpc`**：
   - 从 [FRP 官方 GitHub](https://github.com/fatedier/frp/releases) 下载 Android 版 `frps` 和 `frpc`。
   - 放入 `/data/adb/modules/frps_frpc/bin/arm64-v8a/`。

4. **设置权限**：
   - 通过终端或文件管理器设置权限：
     ```bash
     chmod 755 /data/adb/modules/frps_frpc/bin/arm64-v8a/*
     chmod 755 /data/adb/modules/frps_frpc/*.sh
     chmod 755 /data/adb/modules/frps_frpc/scripts/*.sh
     ```

5. **重启设备**：
   - 重启设备后，模块会自动运行。

---

### 注意事项
- **依赖**：需支持 `curl` 或 `wget`，否则 IP 检测可能失败。
- **存储**：日志文件最大保留 7 天，建议定期检查设备存储空间。
- **权限**：确保所有脚本和二进制文件具有可执行权限。

所有文件内容已提供，直接复制粘贴即可使用，操作简单

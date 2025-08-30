# BBR 控制脚本 / BBR Control Script

[中文](#中文文档) | [English](#english-documentation)

---

## 中文文档

### 📖 简介

BBR 控制脚本是一个从 3X-UI 项目中提取的独立工具，专门用于管理 Linux 系统上的 BBR（Bottleneck Bandwidth and Round-trip propagation time）拥塞控制算法。该脚本支持多种 Linux 发行版，特别针对 Alpine Linux 系统进行了优化。

### ✨ 特性

- **🔧 多系统支持**: Ubuntu、Debian、CentOS、Alpine Linux
- **🎯 Alpine 特殊优化**: 针对 Alpine Linux 的特殊配置和错误处理
- **📊 智能检测**: 自动检测系统类型、内核版本和参数支持情况
- **🛡️ 安全验证**: Root 权限检查和操作前确认
- **📱 双模式操作**: 支持交互式菜单和命令行参数
- **🔍 详细状态**: 显示完整的 BBR 和系统状态信息
- **🌐 中文界面**: 完全中文化的用户界面

### 🚀 快速开始

#### 下载和安装

```bash
# 下载脚本
wget -O bbr_control.sh https://raw.githubusercontent.com/figozhu/enable-bbr-script/bbr_control.sh

# 或使用 curl
curl -o bbr_control.sh https://raw.githubusercontent.com/figozhu/enable-bbr-script/bbr_control.sh

# 添加执行权限
chmod +x bbr_control.sh
```

#### 基本使用

```bash
# 交互式菜单模式
sudo ./bbr_control.sh

# 启用 BBR
sudo ./bbr_control.sh enable

# 禁用 BBR
sudo ./bbr_control.sh disable

# 查看状态
sudo ./bbr_control.sh status

# 显示帮助
./bbr_control.sh help
```

### 📋 系统要求

- **操作系统**: Ubuntu 18.04+, Debian 9+, CentOS 7+, Alpine Linux 3.10+
- **内核版本**: Linux 4.9 或更高版本
- **权限**: Root 权限
- **依赖**: bash, sysctl

### 🔧 功能详解

#### 1. 启用 BBR (`enable` / `on`)

**标准系统 (Ubuntu/Debian/CentOS):**
- 检查内核版本兼容性
- 配置 `net.core.default_qdisc=fq`
- 配置 `net.ipv4.tcp_congestion_control=bbr`
- 应用配置并验证结果

**Alpine Linux 系统:**
- 自动加载 `tcp_bbr` 内核模块
- 智能检测参数支持情况
- 跳过不支持的参数配置
- 提供详细的警告和状态信息

#### 2. 禁用 BBR (`disable` / `off`)

- 移除 BBR 相关配置
- 恢复默认拥塞控制算法 (cubic)
- Alpine 系统智能选择可用算法
- 验证禁用结果

#### 3. 状态查看 (`status` / `check`)

显示详细信息包括：
- 当前拥塞控制算法
- 可用拥塞控制算法列表
- 默认队列调度算法
- BBR 启用状态
- 内核版本信息
- Alpine 系统特殊信息（内核模块状态）

### 🐧 Alpine Linux 特殊支持

Alpine Linux 使用精简内核配置，某些网络参数可能不可用。本脚本针对此问题提供了特殊处理：

#### 问题解决
```
# 原始错误
sysctl: error: 'net.core.default_qdisc' is an unknown key
sysctl: write error: No such file or directory
```

#### 解决方案
- **参数预检测**: 在配置前测试参数可用性
- **智能跳过**: 跳过不支持的参数但继续核心配置
- **模块管理**: 自动加载必要的内核模块
- **友好提示**: 清晰说明哪些配置被跳过及原因

### 📊 使用示例

#### 交互式使用
```bash
$ sudo ./bbr_control.sh

BBR 控制脚本
0. 退出脚本
————————————————
1. 启用 BBR
2. 禁用 BBR
3. 查看 BBR 状态
————————————————

请输入选择 [0-3]: 1
```

#### 命令行使用
```bash
# 在 Alpine 系统上启用 BBR
$ sudo ./bbr_control.sh enable
检测到内核版本 5.10.0，支持 BBR
开始启用 BBR...
检测到 Alpine 系统，使用特殊配置方法
警告: net.core.default_qdisc 参数不受支持，跳过此配置
BBR 在 Alpine 系统上启用成功！
注意: 队列调度算法配置被跳过，但 BBR 拥塞控制已启用

# 查看详细状态
$ sudo ./bbr_control.sh status
=== BBR 状态信息 ===
操作系统: Alpine Linux
Alpine 版本: 3.18.4
当前拥塞控制算法: bbr
可用拥塞控制算法: reno cubic bbr
默认队列调度算法: 不支持或无法获取
BBR 状态: 已启用
内核版本: 5.10.0-alpine1
=== Alpine 系统特殊信息 ===
BBR 内核模块: 已加载
```

### 🛠️ 故障排除

#### 常见问题

1. **权限错误**
   ```bash
   错误：此脚本必须以 root 权限运行！
   ```
   **解决**: 使用 `sudo` 运行脚本

2. **系统不支持**
   ```bash
   不支持的操作系统，请使用 Ubuntu、Debian、CentOS 或 Alpine Linux
   ```
   **解决**: 检查系统类型，确保使用支持的发行版

3. **内核版本过低**
   ```bash
   当前内核版本 3.10.0 不支持 BBR，需要升级内核到 4.9 或更高版本
   ```
   **解决**: 升级内核到 4.9 或更高版本

4. **Alpine 参数不支持**
   ```bash
   警告: net.core.default_qdisc 参数不受支持，跳过此配置
   ```
   **说明**: 这是正常现象，BBR 拥塞控制仍会正常启用

### 📝 更新日志

- **v1.2.0** - 添加 Alpine Linux 完整支持
- **v1.1.0** - 增强状态显示和错误处理
- **v1.0.0** - 初始版本，支持基本 BBR 控制

---

## English Documentation

### 📖 Introduction

The BBR Control Script is a standalone tool extracted from the 3X-UI project, specifically designed to manage BBR (Bottleneck Bandwidth and Round-trip propagation time) congestion control algorithm on Linux systems. This script supports multiple Linux distributions with special optimizations for Alpine Linux.

### ✨ Features

- **🔧 Multi-System Support**: Ubuntu, Debian, CentOS, Alpine Linux
- **🎯 Alpine Optimization**: Special configuration and error handling for Alpine Linux
- **📊 Smart Detection**: Automatic detection of system type, kernel version, and parameter support
- **🛡️ Security Validation**: Root permission check and pre-operation confirmation
- **📱 Dual Operation Modes**: Interactive menu and command-line parameter support
- **🔍 Detailed Status**: Complete BBR and system status information display
- **🌐 Chinese Interface**: Fully localized Chinese user interface

### 🚀 Quick Start

#### Download and Installation

```bash
# Download script
wget -O bbr_control.sh https://raw.githubusercontent.com/figozhu/enable-bbr-script/bbr_control.sh

# Or use curl
curl -o bbr_control.sh https://raw.githubusercontent.com/figozhu/enable-bbr-script/bbr_control.sh

# Add execute permission
chmod +x bbr_control.sh
```

#### Basic Usage

```bash
# Interactive menu mode
sudo ./bbr_control.sh

# Enable BBR
sudo ./bbr_control.sh enable

# Disable BBR
sudo ./bbr_control.sh disable

# Check status
sudo ./bbr_control.sh status

# Show help
./bbr_control.sh help
```

### 📋 System Requirements

- **Operating System**: Ubuntu 18.04+, Debian 9+, CentOS 7+, Alpine Linux 3.10+
- **Kernel Version**: Linux 4.9 or higher
- **Permissions**: Root privileges
- **Dependencies**: bash, sysctl

### 🔧 Feature Details

#### 1. Enable BBR (`enable` / `on`)

**Standard Systems (Ubuntu/Debian/CentOS):**
- Check kernel version compatibility
- Configure `net.core.default_qdisc=fq`
- Configure `net.ipv4.tcp_congestion_control=bbr`
- Apply configuration and verify results

**Alpine Linux Systems:**
- Automatically load `tcp_bbr` kernel module
- Intelligently detect parameter support
- Skip unsupported parameter configurations
- Provide detailed warnings and status information

#### 2. Disable BBR (`disable` / `off`)

- Remove BBR-related configurations
- Restore default congestion control algorithm (cubic)
- Intelligently select available algorithms for Alpine systems
- Verify disable results

#### 3. Status Check (`status` / `check`)

Display detailed information including:
- Current congestion control algorithm
- Available congestion control algorithms list
- Default queue discipline algorithm
- BBR enable status
- Kernel version information
- Alpine system special information (kernel module status)

### 🐧 Alpine Linux Special Support

Alpine Linux uses a minimal kernel configuration where some network parameters may be unavailable. This script provides special handling for this issue:

#### Problem Resolution
```
# Original error
sysctl: error: 'net.core.default_qdisc' is an unknown key
sysctl: write error: No such file or directory
```

#### Solution
- **Parameter Pre-detection**: Test parameter availability before configuration
- **Smart Skip**: Skip unsupported parameters but continue core configuration
- **Module Management**: Automatically load necessary kernel modules
- **Friendly Prompts**: Clear explanation of which configurations are skipped and why

### 📊 Usage Examples

#### Interactive Usage
```bash
$ sudo ./bbr_control.sh

BBR Control Script
0. Exit Script
————————————————
1. Enable BBR
2. Disable BBR
3. Check BBR Status
————————————————

Please enter choice [0-3]: 1
```

#### Command Line Usage
```bash
# Enable BBR on Alpine system
$ sudo ./bbr_control.sh enable
Detected kernel version 5.10.0, supports BBR
Starting to enable BBR...
Detected Alpine system, using special configuration method
Warning: net.core.default_qdisc parameter not supported, skipping this configuration
BBR successfully enabled on Alpine system!
Note: Queue discipline algorithm configuration was skipped, but BBR congestion control is enabled

# Check detailed status
$ sudo ./bbr_control.sh status
=== BBR Status Information ===
Operating System: Alpine Linux
Alpine Version: 3.18.4
Current Congestion Control Algorithm: bbr
Available Congestion Control Algorithms: reno cubic bbr
Default Queue Discipline Algorithm: Not supported or unable to retrieve
BBR Status: Enabled
Kernel Version: 5.10.0-alpine1
=== Alpine System Special Information ===
BBR Kernel Module: Loaded
```

### 🛠️ Troubleshooting

#### Common Issues

1. **Permission Error**
   ```bash
   Error: This script must be run with root privileges!
   ```
   **Solution**: Run script with `sudo`

2. **Unsupported System**
   ```bash
   Unsupported operating system, please use Ubuntu, Debian, CentOS or Alpine Linux
   ```
   **Solution**: Check system type, ensure using supported distribution

3. **Kernel Version Too Low**
   ```bash
   Current kernel version 3.10.0 does not support BBR, need to upgrade kernel to 4.9 or higher
   ```
   **Solution**: Upgrade kernel to 4.9 or higher

4. **Alpine Parameter Not Supported**
   ```bash
   Warning: net.core.default_qdisc parameter not supported, skipping this configuration
   ```
   **Note**: This is normal behavior, BBR congestion control will still be enabled properly

### 📝 Changelog

- **v1.2.0** - Added complete Alpine Linux support
- **v1.1.0** - Enhanced status display and error handling
- **v1.0.0** - Initial version with basic BBR control

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have questions, please:
1. Check the troubleshooting section above
2. Create an issue on GitHub
3. Join our community discussion

---

**Made with ❤️ for the Linux community**

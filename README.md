# 🚀 DevScripts 脚本工具集

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Scripts](https://img.shields.io/badge/scripts-40%2B-orange)

**跨平台开发脚本工具集合**

[功能介绍](#-功能特色) • [快速开始](#-快速开始) • [脚本列表](#-脚本列表) • [贡献指南](#-贡献指南)

</div>

---

## ✨ 功能特色

- 🌍 **跨平台支持** - 同时支持 Windows 和 Linux 系统
- 🔧 **一键安装** - 常用开发环境自动配置
- 🛠️ **系统优化** - Windows 右键菜单、环境变量管理
- 📦 **版本管理** - Node.js、Python、Java、PHP 多版本切换
- 🎯 **镜像配置** - npm、pip 国内镜像源快速切换

---

## 📁 目录结构

```
DevScripts/
├── Linux/                    # Linux 脚本
│   ├── 安装脚本/             # 环境安装（.sh）
│   │   ├── install_docker.sh
│   │   ├── install_git.sh
│   │   └── ...
│   ├── 部署脚本/             # 远程部署（.py）
│   ├── mirror_config.sh      # 镜像源配置
│   └── open_port.sh          # 开放防火墙端口
└── Windows/                  # Windows 脚本
    ├── install/              # 环境安装（.bat）
    │   ├── docker.bat
    │   ├── git.bat
    │   └── ...
    ├── 部署脚本/             # 远程部署（.py）
    ├── npm_mirror_config.bat # npm 镜像配置
    ├── pip_mirror_config.bat # pip 镜像配置
    ├── fix_cmd.ps1           # CMD 修复工具
    └── ...                   # 更多系统工具
```

---

## 🚀 快速开始

### Windows 用户

```powershell
# 克隆仓库
git clone https://github.com/yourusername/DevScripts.git
cd DevScripts

# 以管理员身份运行脚本
# 右键脚本 -> 以管理员身份运行
```

### Linux 用户

```bash
# 克隆仓库
git clone https://github.com/yourusername/DevScripts.git
cd DevScripts

# 添加执行权限
chmod +x Linux/*.sh Linux/安装脚本/*.sh

# 运行脚本
sudo ./Linux/安装脚本/install_docker.sh
```

---

## 📋 脚本列表

### 🔧 安装脚本

| 脚本 | Windows | Linux | 说明 |
|------|---------|-------|------|
| **Docker** | ✅ | ✅ | Docker/Docker Desktop 安装 |
| **Git** | ✅ | ✅ | Git 版本控制系统 |
| **Node.js** | ✅ | ✅ | Node.js 运行环境 |
| **Go** | ✅ | ✅ | Go 语言环境 |
| **Java** | ✅ | ✅ | JDK/OpenJDK |
| **Python** | ✅ | ✅ | Python + pyenv |
| **PHP** | ✅ | ✅ | PHP 运行环境 |
| **MySQL** | ✅ | ✅ | MySQL 数据库 |
| **MariaDB** | ✅ | ✅ | MariaDB 数据库 |
| **PostgreSQL** | ✅ | ✅ | PostgreSQL 数据库 |
| **Redis** | ✅ | ✅ | Redis 缓存服务 |
| **Nginx** | ✅ | ✅ | Nginx Web 服务器 |
| **ROS2** | ✅ | ✅ | ROS 2 机器人系统 |
| **MongoDB** | ✅ | — | MongoDB 便携版安装 |

### 🛠️ Windows 工具

| 脚本 | 说明 |
|------|------|
| **Win11菜单切换.bat** | 切换 Win11/Win10 菜单样式 |
| **Win11桌面右键.bat** | 修复/恢复 Win11 右键菜单 |
| **npm镜像配置.bat** | 快速切换 npm 镜像源 |
| **pip镜像配置.bat** | 快速切换 pip 镜像源 |
| **环境变量_jdk版本切换.cmd** | JDK 多版本切换 |
| **环境变量_php环境变量切换工具.bat** | PHP 多版本切换 |
| **一键安装nvm.bat** | NVM 版本管理器 |
| **一键安装Hyper-V.bat** | 启用 Hyper-V 功能 |
| **fix_cmd.ps1** | 修复 CMD 相关问题 |
| **右键_vscode 右键打开文件夹.bat** | VSCode 右键菜单管理 |
| **右键_notepad++ 添删右键菜单.bat** | Notepad++ 右键菜单管理 |
| **Windows开机自动开启.bat** | 设置开机自启动程序 |
| **Windows刷新图标缓存.bat** | 刷新图标缓存 |
| **cmd_context_menu.bat** | 添加"在此处打开 CMD"右键菜单 |

### 🐧 Linux 工具

| 脚本 | 说明 |
|------|------|
| **open_port.sh** | 一键开放防火墙端口 |

### 📝 注册表脚本

| 脚本 | 说明 |
|------|------|
| **Office预览注册表修复.reg** | 修复 Office 文件预览功能 |
| **Office预览注册表修复.bat** | 修复 Office 文件预览功能（CMD 版本）|

---

## 💡 使用示例

### 安装 Docker（Windows）

```batch
# 以管理员身份运行（部分脚本）
cd install
docker.bat
```

### 安装 Docker（Linux）

```bash
sudo ./Linux/安装脚本/install_docker.sh
```

### 切换 npm 镜像源

```batch
cd Windows
npm镜像配置.bat
# 选择 1 - 淘宝镜像
```

### Win11 菜单切换

```batch
cd Windows
Win11菜单切换.bat
# 选择 1 - 恢复 Win11 默认菜单
# 选择 2 - 切换为 Win10 经典菜单
```

---

## ⚙️ 系统要求

### Windows
- Windows 10/11
- PowerShell 5.0 或更高版本
- 管理员权限（部分脚本）
- winget 包管理器（安装脚本）

### Linux
- Ubuntu/Debian/CentOS/RHEL/Rocky/AlmaLinux
- systemd 系统
- root 权限或 sudo

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

### 提交规范

- `feat:` 新功能
- `fix:` 修复问题
- `refactor:` 代码重构
- `docs:` 文档更新
- `style:` 代码格式调整
- `test:` 测试相关
- `chore:` 构建/工具链相关

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star ⭐

---

<div align="center">

**Made with ❤️ by [Your Name]**

</div>

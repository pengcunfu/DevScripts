# 🚀 DevScripts 脚本工具集

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Scripts](https://img.shields.io/badge/scripts-40%2B-orange)

**跨平台开发脚本工具集合 — 按功能分类**

[功能介绍](#-功能特色) • [快速开始](#-快速开始) • [脚本列表](#-脚本列表) • [贡献指南](#-贡献指南)

</div>

---

## ✨ 功能特色

- 🌍 **跨平台支持** - 同时支持 Windows 和 Linux 系统
- 🔧 **一键安装** - 常用开发环境自动配置
- 🛠️ **系统优化** - Windows 右键菜单、CMD 修复、环境变量管理
- 📦 **版本管理** - JDK、Node.js、PHP、Python 多版本切换
- 🎯 **镜像配置** - npm、pip、Docker 国内镜像源快速切换

---

## 📁 目录结构

```
DevScripts/
├── install/                    # 软件环境安装
│   ├── linux/                  # Linux 安装脚本 (.sh)
│   └── windows/                # Windows 安装脚本 (.bat)
├── mirror/                     # 镜像源配置
│   ├── linux.sh                # Linux 镜像源配置
│   └── windows/                # Windows 镜像源配置 (.bat)
├── deploy/                     # 部署脚本 (.py)
├── version-switcher/           # 版本切换工具
├── system-tools/               # 系统工具
│   ├── linux/                  # Linux 系统工具
│   └── windows/                # Windows 系统工具
├── context-menu/               # 右键菜单管理 (Windows)
├── database/                   # 数据库管理
│   └── windows/                # Windows 数据库管理
├── git/                        # Git 工具
├── build/                      # 构建与打包
├── devkit/                     # 开发组件/库
├── get-pip.py                  # pip 安装工具
└── README.md
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
chmod +x install/linux/*.sh mirror/linux.sh system-tools/linux/*.sh

# 运行脚本
sudo ./install/linux/install_docker.sh
```

---

## 📋 脚本列表

### 🔧 安装脚本 (`install/`)

| 脚本 | Windows | Linux | 说明 |
|------|---------|-------|------|
| **Docker** | ✅ | ✅ | Docker/Docker Desktop 安装 |
| **Docker Compose** | ✅ | ✅ | Docker Compose 安装 |
| **Git** | ✅ | ✅ | Git 版本控制系统 |
| **Go** | ✅ | ✅ | Go 语言环境 |
| **Java** | ✅ | ✅ | JDK/OpenJDK |
| **Node.js** | ✅ | ✅ | Node.js 运行环境 |
| **NVM** | ✅ | — | Node.js 版本管理器 |
| **Python (pyenv)** | ✅ | ✅ | Python + pyenv |
| **PHP** | ✅ | ✅ | PHP 运行环境 |
| **MySQL** | ✅ | ✅ | MySQL 数据库 |
| **MariaDB** | ✅ | ✅ | MariaDB 数据库 |
| **PostgreSQL** | ✅ | ✅ | PostgreSQL 数据库 |
| **Redis** | ✅ | ✅ | Redis 缓存服务 |
| **Nginx** | ✅ | ✅ | Nginx Web 服务器 |
| **ROS2** | ✅ | ✅ | ROS 2 机器人系统 |
| **MongoDB** | ✅ | — | MongoDB 便携版安装 |
| **Hyper-V** | ✅ | — | 启用 Hyper-V 虚拟化 |

### 🎯 镜像源配置 (`mirror/`)

| 脚本 | 说明 |
|------|------|
| **linux.sh** | Linux 综合镜像源配置 (apt/yum/dnf/pacman/pip/npm/docker) |
| **go.bat** | Go 模块镜像配置 |
| **maven.bat** | Maven 仓库镜像配置 |
| **npm.bat** | npm 镜像源切换 |
| **pip.bat** | pip 镜像源切换 |

### 🚀 部署脚本 (`deploy/`)

| 脚本 | 说明 |
|------|------|
| **deploy_nodejs.py** | Node.js 项目远程部署 |
| **deploy_springboot.py** | Spring Boot 项目远程部署 |
| **deploy_vue_project.py** | Vue 项目远程部署 |

### 🔄 版本切换 (`version-switcher/`)

| 脚本 | 说明 |
|------|------|
| **jdk.cmd** | JDK 多版本切换 (8/11/17) |
| **nodejs.bat** | Node.js 多版本切换 |
| **php.bat** | PHP 多版本切换 |
| **python.bat** | Python 多版本切换 |

### 🛠️ 系统工具 (`system-tools/`)

| 脚本 | 平台 | 说明 |
|------|------|------|
| **open_port.sh** | Linux | 一键开放防火墙端口 |
| **fix_cmd.bat** | Windows | CMD 快速修复 (AutoRun) |
| **fix_cmd.ps1** | Windows | CMD 深度修复 (注册表/PATH/SFC) |
| **fix_office_preview.bat** | Windows | Office 文件预览修复 |
| **refresh_icon_cache.bat** | Windows | 刷新图标缓存 |
| **wechat_multi_instance.bat** | Windows | 微信多开 |

### 📋 右键菜单管理 (`context-menu/`)

| 脚本 | 说明 |
|------|------|
| **cmd_context_menu.bat** | 添加"在此处打开 CMD"右键菜单 |
| **notepad_context_menu.bat** | Notepad++ 右键菜单管理 |
| **vscode_context_menu.bat** | VSCode 右键菜单管理 |
| **win11_context_menu.bat** | Win11 右键菜单样式切换 |
| **win11_menu_switcher.bat** | Win11/Win10 菜单切换 |

### 🗄️ 数据库管理 (`database/`)

| 脚本 | 说明 |
|------|------|
| **mysql.bat** | MySQL 服务管理 |
| **postgresql.bat** | PostgreSQL 服务管理 |

### 🔀 Git 工具 (`git/`)

| 脚本 | 说明 |
|------|------|
| **config_info.bat** | 查看 Git 配置信息 |
| **proxy.bat** | 设置 Git 代理 |

### 📦 构建与打包 (`build/`)

| 脚本 | 说明 |
|------|------|
| **nuitka-build.py** | 使用 Nuitka 编译 Python 项目 |
| **local-install.py** | 编译后程序安装与快捷方式创建 |

### 🧩 开发组件 (`devkit/`)

| 组件 | 说明 |
|------|------|
| **pyside6_antd_components** | PySide6 Ant Design 风格组件库 |

---

## 💡 使用示例

### 安装 Docker

```bash
# Linux
sudo ./install/linux/install_docker.sh

# Windows (管理员)
.\install\windows\docker.bat
```

### 切换镜像源

```bash
# Linux
sudo ./mirror/linux.sh

# Windows
.\mirror\windows\npm.bat
```

### 切换 JDK 版本

```batch
.\version-switcher\jdk.cmd
# 选择 1 - 切换到 JDK 8
# 选择 2 - 切换到 JDK 11
# 选择 3 - 切换到 JDK 17
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

<div align="center">

**Made with ❤️ by [Your Name]**

</div>

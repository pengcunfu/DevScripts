# 🚀 DevScripts 脚本工具集

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Scripts](https://img.shields.io/badge/scripts-60%2B-orange)

**跨平台开发脚本工具集合 — 按功能分类**

[功能特色](#-功能特色) • [快速开始](#-快速开始) • [脚本列表](#-脚本列表) • [使用示例](#-使用示例) • [贡献指南](#-贡献指南)

</div>

---

## ✨ 功能特色

- 🌍 **跨平台支持** — 同时覆盖 Windows 与 Linux 系统
- 🔧 **一键安装** — 常用开发环境 / 数据库 / 运行时自动配置
- 🪞 **镜像源配置** — apt / yum / dnf / pacman / pip / npm / docker / maven / go 国内镜像
- 🔄 **版本切换** — JDK、Node.js、Python、PHP 多版本快速切换
- 🛠️ **系统工具** — 端口开放、CMD 修复、Office 预览修复、图标缓存刷新
- 🖱️ **右键菜单** — CMD / VSCode / Notepad++ / Win11 经典菜单管理

---

## 📁 目录结构

```
DevScripts/
├── install-linux/              # Linux 安装脚本 (.sh)
├── install-windows/            # Windows 安装脚本 (.bat)
├── mirrorconfig-linux/         # Linux 镜像源配置 (.sh)
├── mirrorconfig-windows/       # Windows 镜像源配置 (.bat)
├── systemtools-linux/          # Linux 系统工具 (.sh)
├── systemtools-windows/        # Windows 系统工具 (.bat / .ps1)
├── version-switcher/           # 多版本切换工具 (.cmd)
├── git/                        # Git 配置工具 (.bat)
└── README.md
```

> 目录命名规则:`<功能>-<平台>/`,平台无关时省略后缀。

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
chmod +x install-linux/*.sh mirrorconfig-linux/*.sh systemtools-linux/*.sh

# 运行脚本
sudo ./install-linux/install_docker.sh
```

---

## 📋 脚本列表

### 🔧 Linux 安装脚本 (`install-linux/`)

| 脚本 | 说明 |
|------|------|
| `install_docker.sh` | Docker 安装 |
| `install_docker_compose.sh` | Docker Compose 安装 |
| `install_git.sh` | Git 安装 |
| `install_go.sh` | Go 语言环境安装 |
| `install_java.sh` | JDK / OpenJDK 安装 |
| `install_mariadb.sh` | MariaDB 安装 |
| `install_mysql.sh` | MySQL 安装 |
| `install_nginx.sh` | Nginx 安装 |
| `install_nodejs.sh` | Node.js 安装 |
| `install_php.sh` | PHP 安装 |
| `install_postgresql.sh` | PostgreSQL 安装 |
| `install_pyenv.sh` | pyenv + Python 安装 |
| `install_redis.sh` | Redis 安装 |
| `install_ros2.sh` | ROS 2 机器人系统安装 |

### 🪟 Windows 安装脚本 (`install-windows/`)

| 脚本 | 说明 |
|------|------|
| `docker.bat` | Docker Desktop 安装 |
| `docker_compose.bat` | Docker Compose 安装 |
| `git.bat` | Git 安装 |
| `go.bat` | Go 语言环境安装 |
| `hyper-v.bat` | 启用 Hyper-V 虚拟化 |
| `java.bat` | JDK 安装 |
| `mariadb.bat` | MariaDB 安装 |
| `mongodb.bat` | MongoDB 便携版安装 |
| `mysql.bat` | MySQL 安装 |
| `nginx.bat` | Nginx 安装 |
| `nodejs.bat` | Node.js 安装 |
| `nvm.bat` | NVM (Node 版本管理器) 安装 |
| `php.bat` | PHP 安装 |
| `postgresql.bat` | PostgreSQL 安装 |
| `pyenv.bat` | pyenv + Python 安装 |
| `redis.bat` | Redis 安装 |
| `ros2.bat` | ROS 2 机器人系统安装 |

### 🪞 Linux 镜像源配置 (`mirrorconfig-linux/`)

| 脚本 | 说明 |
|------|------|
| `linux.sh` | 综合镜像源配置 (apt / yum / dnf / pacman / pip / npm / docker) |
| `apt-mirror.sh` | apt 镜像源切换 (Debian / Ubuntu) |
| `yum-mirror.sh` | yum / dnf 镜像源切换 (CentOS / RHEL / Rocky) |
| `pacman-mirror.sh` | pacman 镜像源切换 (Arch) |
| `pip-mirror.sh` | pip 镜像源切换 |
| `npm-mirror.sh` | npm 镜像源切换 |
| `docker-mirror.sh` | Docker 镜像加速器配置 |
| `common.sh` | 镜像源配置公共函数库 |

### 🪟 Windows 镜像源配置 (`mirrorconfig-windows/`)

| 脚本 | 说明 |
|------|------|
| `npm-config-mirror.bat` | npm 镜像源切换 |
| `pip-config-mirror.bat` | pip 镜像源切换 |
| `maven-config-mirror.bat` | Maven 仓库镜像配置 |
| `go-config-mirror.bat` | Go 模块代理配置 |

### 🔄 版本切换工具 (`version-switcher/`)

| 脚本 | 说明 |
|------|------|
| `jdk-version-switcher.cmd` | JDK 版本切换 (符号链接方式) |
| `nodejs-version-switcher.cmd` | Node.js 版本切换 |
| `python-version-switcher.cmd` | Python 版本切换 |
| `php-version-switcher.cmd` | PHP 版本切换 |

### 🛠️ Linux 系统工具 (`systemtools-linux/`)

| 脚本 | 说明 |
|------|------|
| `open_port_firewalld.sh` | 一键开放端口 (firewalld) |
| `open_port_ufw.sh` | 一键开放端口 (ufw) |
| `open_port_iptables.sh` | 一键开放端口 (iptables) |

### 🛠️ Windows 系统工具 (`systemtools-windows/`)

| 脚本 | 说明 |
|------|------|
| `context_menu_manager.bat` | 右键菜单管理 (CMD / VSCode / Notepad++ / 经典菜单) |
| `win11_default_menu.bat` | 恢复 Win11 默认右键菜单样式 |
| `win10_classic_menu.bat` | 切换为 Win10 经典右键菜单 |
| `fix_cmd.bat` | CMD 快速修复 (AutoRun) |
| `fix_cmd.ps1` | CMD 深度修复 (注册表 / PATH / SFC) |
| `fix_office_preview.bat` | Office 文件预览修复 |
| `refresh-icon-cache.bat` | 刷新系统图标缓存 |
| `wechat_multi_instance.bat` | 微信多开 |

### 🔀 Git 工具 (`git/`)

| 脚本 | 说明 |
|------|------|
| `git-config-user.bat` | 快速配置 Git 用户名 / 邮箱 |
| `git-config-proxy-karing.bat` | 设置 Git 代理 (Karing) |
| `git-config-proxy-viewtrubo.bat` | 设置 Git 代理 (Viewtrubo) |

---

## 💡 使用示例

### 安装 Docker

```bash
# Linux
sudo ./install-linux/install_docker.sh

# Windows (管理员)
.\install-windows\docker.bat
```

### 切换镜像源

```bash
# Linux 一键切换全部镜像
sudo ./mirrorconfig-linux/linux.sh

# Linux 仅切换 apt 镜像
sudo ./mirrorconfig-linux/apt-mirror.sh

# Windows
.\mirrorconfig-windows\npm-config-mirror.bat
```

### 切换 JDK 版本

```batch
# 编辑脚本顶部的路径变量，然后双击运行
.\version-switcher\jdk-version-switcher.cmd
```

### 在 Linux 上开放端口

```bash
# firewalld
sudo ./systemtools-linux/open_port_firewalld.sh

# ufw
sudo ./systemtools-linux/open_port_ufw.sh

# iptables
sudo ./systemtools-linux/open_port_iptables.sh
```

---

## ⚙️ 系统要求

### Windows
- Windows 10 / 11
- PowerShell 5.0 或更高版本
- 管理员权限(部分脚本)
- winget 包管理器(安装脚本)

### Linux
- Ubuntu / Debian / CentOS / RHEL / Rocky / AlmaLinux / Arch
- systemd 系统
- root 权限或 sudo

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request!

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
- `chore:` 构建 / 工具链相关

---

## 📄 许可证

本项目采用 MIT 许可证。

---

<div align="center">

**Made with ❤️ by DevScripts Contributors**

</div>

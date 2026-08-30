# 🚀 DevScripts 脚本工具集

<div align="center">

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Scripts](https://img.shields.io/badge/scripts-60%2B-orange)

**跨平台开发脚本工具集合 — 按程序分类**

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
├── git/            # Git 工具与安装
├── go/             # Go 语言脚本
├── java/           # Java 相关脚本
├── node/           # Node.js 相关脚本
├── php/            # PHP 相关脚本
├── python/         # Python 相关脚本
├── docker/         # Docker 相关脚本
├── mariadb/        # MariaDB 脚本
├── mysql/          # MySQL 脚本
├── mongodb/        # MongoDB 脚本
├── nginx/          # Nginx 脚本
├── postgresql/     # PostgreSQL 脚本
├── redis/          # Redis 脚本
├── ros2/           # ROS 2 脚本
├── mirrorconfig/   # 系统镜像源配置 (apt / yum / dnf / pacman)
├── systemtools/    # 系统工具 (端口开放 / 右键菜单 / 系统修复)
└── README.md
```

> 每个目录对应一个程序 / 语言，脚本直接放在目录下（最多两级）。Windows (`.bat` / `.cmd`) 与 Linux (`.sh`) 脚本统一按程序归入同一目录，不再按平台拆分。

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
chmod +x */*.sh

# 运行脚本
sudo ./docker/install_docker.sh
```

---

## 📋 脚本列表

### 🔵 Git (`git/`)

| 脚本 | 说明 |
|------|------|
| `git.bat` | Git Windows 安装 |
| `install_git.sh` | Git Linux 安装 |
| `git-config-user.bat` | 快速配置 Git 用户名 / 邮箱 |
| `git-config-proxy-karing.bat` | 设置 Git 代理 (Karing) |
| `git-config-proxy-viewtrubo.bat` | 设置 Git 代理 (Viewtrubo) |

### 🔵 Go (`go/`)

| 脚本 | 说明 |
|------|------|
| `go-installer.bat` | Go 语言环境 Windows 安装 |
| `install_go.sh` | Go 语言环境 Linux 安装 |
| `go-config-mirror.bat` | Go 模块代理 (GOPROXY) 配置 |
| `go-config-data-dir.bat` | 配置 GOPATH / GOMODCACHE / GOCACHE 数据目录 |

### ☕ Java (`java/`)

| 脚本 | 说明 |
|------|------|
| `java.bat` | JDK Windows 安装 |
| `install_java.sh` | JDK / OpenJDK Linux 安装 |
| `jdk-version-switcher.cmd` | JDK 版本切换 (符号链接方式) |
| `maven-config-mirror.bat` | Maven 仓库镜像配置 |

### 🟢 Node.js (`node/`)

| 脚本 | 说明 |
|------|------|
| `nodejs.bat` | Node.js Windows 安装 |
| `install_nodejs.sh` | Node.js Linux 安装 |
| `nvm.bat` | NVM (Node 版本管理器) 安装 |
| `nodejs-version-switcher.cmd` | Node.js 版本切换 |
| `npm-config-mirror.bat` | npm 镜像源切换 (Windows) |
| `npm-mirror.sh` | npm 镜像源切换 (Linux) |

### 🐘 PHP (`php/`)

| 脚本 | 说明 |
|------|------|
| `php.bat` | PHP Windows 安装 |
| `install_php.sh` | PHP Linux 安装 |
| `php-version-switcher.cmd` | PHP 版本切换 |

### 🐍 Python (`python/`)

| 脚本 | 说明 |
|------|------|
| `pyenv.bat` | pyenv Windows 安装 |
| `install_pyenv.sh` | pyenv + Python Linux 安装 |
| `python-version-switcher.cmd` | Python 版本切换 |
| `pip-config-mirror.bat` | pip 镜像源切换 (Windows) |
| `pip-mirror.sh` | pip 镜像源切换 (Linux) |

### 🐳 Docker (`docker/`)

| 脚本 | 说明 |
|------|------|
| `docker.bat` | Docker Desktop Windows 安装 |
| `install_docker.sh` | Docker Linux 安装 |
| `docker_compose.bat` | Docker Compose Windows 安装 |
| `install_docker_compose.sh` | Docker Compose Linux 安装 |
| `docker-mirror.sh` | Docker 镜像加速器配置 |

### 🗄️ 数据库

#### MariaDB (`mariadb/`)

| 脚本 | 说明 |
|------|------|
| `mariadb.bat` | MariaDB Windows 安装 |
| `install_mariadb.sh` | MariaDB Linux 安装 |

#### MySQL (`mysql/`)

| 脚本 | 说明 |
|------|------|
| `mysql.bat` | MySQL Windows 安装 |
| `install_mysql.sh` | MySQL Linux 安装 |

#### MongoDB (`mongodb/`)

| 脚本 | 说明 |
|------|------|
| `mongodb.bat` | MongoDB 便携版安装 |

#### PostgreSQL (`postgresql/`)

| 脚本 | 说明 |
|------|------|
| `postgresql.bat` | PostgreSQL Windows 安装 |
| `install_postgresql.sh` | PostgreSQL Linux 安装 |

#### Redis (`redis/`)

| 脚本 | 说明 |
|------|------|
| `redis.bat` | Redis Windows 安装 |
| `install_redis.sh` | Redis Linux 安装 |

### 🌐 服务

#### Nginx (`nginx/`)

| 脚本 | 说明 |
|------|------|
| `nginx.bat` | Nginx Windows 安装 |
| `install_nginx.sh` | Nginx Linux 安装 |

#### ROS 2 (`ros2/`)

| 脚本 | 说明 |
|------|------|
| `ros2.bat` | ROS 2 Windows 安装 |
| `install_ros2.sh` | ROS 2 机器人系统 Linux 安装 |

### 🪞 系统镜像源配置 (`mirrorconfig/`)

| 脚本 | 说明 |
|------|------|
| `linux.sh` | 综合镜像源配置 (apt / yum / dnf / pacman) |
| `apt-mirror.sh` | apt 镜像源切换 (Debian / Ubuntu) |
| `yum-mirror.sh` | yum / dnf 镜像源切换 (CentOS / RHEL / Rocky) |
| `pacman-mirror.sh` | pacman 镜像源切换 (Arch) |
| `common.sh` | 镜像源配置公共函数库 |

### 🛠️ 系统工具 (`systemtools/`)

| 脚本 | 说明 |
|------|------|
| `open_port_firewalld.sh` | 一键开放端口 (firewalld) |
| `open_port_ufw.sh` | 一键开放端口 (ufw) |
| `open_port_iptables.sh` | 一键开放端口 (iptables) |
| `hyper-v.bat` | 启用 Hyper-V 虚拟化 |
| `context_menu_manager.bat` | 右键菜单管理 (CMD / VSCode / Notepad++ / 经典菜单) |
| `win11_default_menu.bat` | 恢复 Win11 默认右键菜单样式 |
| `win10_classic_menu.bat` | 切换为 Win10 经典右键菜单 |
| `fix_cmd.bat` | CMD 快速修复 (AutoRun) |
| `fix_cmd.ps1` | CMD 深度修复 (注册表 / PATH / SFC) |
| `fix_office_preview.bat` | Office 文件预览修复 |
| `refresh-icon-cache.bat` | 刷新系统图标缓存 |
| `wechat_multi_instance.bat` | 微信多开 |

---

## 💡 使用示例

### 安装 Docker

```bash
# Linux
sudo ./docker/install_docker.sh

# Windows (管理员)
.\docker\docker.bat
```

### 切换镜像源

```bash
# Linux 一键切换系统镜像 (apt / yum / dnf / pacman)
sudo ./mirrorconfig/linux.sh

# Linux 仅切换 apt 镜像
sudo ./mirrorconfig/apt-mirror.sh

# Windows npm 镜像
.\node\npm-config-mirror.bat
```

### 切换 JDK 版本

```batch
# 编辑脚本顶部的路径变量，然后双击运行
.\java\jdk-version-switcher.cmd
```

### 在 Linux 上开放端口

```bash
# firewalld
sudo ./systemtools/open_port_firewalld.sh

# ufw
sudo ./systemtools/open_port_ufw.sh

# iptables
sudo ./systemtools/open_port_iptables.sh
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

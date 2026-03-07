@echo off
chcp 65001 >nul
title Docker Desktop 安装工具

echo ════════════════════════════════════════
echo       Docker Desktop 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    echo 请右键点击脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

:: 检查是否已安装
where docker >nul 2>&1
if %errorlevel% equ 0 (
    echo [信息] 检测到已安装 Docker
    docker --version
    echo.
    set /p reinstall=是否重新安装？(Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [信息] 正在安装 Docker Desktop...
echo.

:: 使用 winget 安装
winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] Docker Desktop 安装完成！
    echo ════════════════════════════════════════
    echo.
    echo 请注销并重新登录，或重启计算机以完成安装
    echo 启动后请在 WSL 2 或 Hyper-V 模式下运行 Docker
) else (
    echo.
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://www.docker.com/products/docker-desktop
)

pause

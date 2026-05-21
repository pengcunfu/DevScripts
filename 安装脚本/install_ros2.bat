@echo off
chcp 65001 >nul
title ROS 2 安装工具

echo ════════════════════════════════════════
echo      ROS 2 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo [提示] ROS 2 在 Windows 上的安装方式
echo.
echo ROS 2 官方支持 Windows，但推荐使用 WSL
echo.
echo [1] 使用 WSL 2 安装 ROS 2 (推荐)
echo [2] 下载 Windows 原生版本
echo [3] 查看官方文档
echo.
set /p choice=请选择安装方式:

if "%choice%"=="1" (
    echo.
    echo [步骤 1] 安装 WSL 2
    echo 请运行: wsl --install
    echo.
    echo [步骤 2] 安装 Ubuntu 后，运行 Linux/安装脚本/install_ros2.sh
    echo.
    echo [步骤 3] 启用 X11 转发（可选，用于 GUI）
    echo   下载 VcXsrv 或使用 WSLg
    echo.
    echo 按任意键打开 ROS 2 官方安装文档...
    pause >nul
    start https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html
) else if "%choice%"=="2" (
    echo.
    echo [信息] ROS 2 Windows 版本功能有限
    echo 建议使用 WSL 2 版本
    echo.
    echo 可用版本：
    echo   - ROS 2 Humble Hawksbill (推荐)
    echo   - ROS 2 Jazzy Jalisco
    echo.
    pause
    start https://docs.ros.org/en/humble/Installation/Windows-Install-Binary.html
) else if "%choice%"=="3" (
    start https://docs.ros.org/en/humble/Installation.html
)

pause

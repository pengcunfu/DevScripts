@echo off
chcp 65001 >nul
title MariaDB 安装工具

echo ════════════════════════════════════════
echo      MariaDB 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo [警告] MariaDB Windows 版本需要手动下载安装
echo.
echo 此脚本将打开 MariaDB 官方下载页面
echo 请选择适合您系统的版本（MSI 安装包）
echo.
echo 推荐版本：MariaDB 10.x 或 11.x
echo.
pause

start https://mariadb.com/downloads/

echo.
echo [提示] 下载完成后，请运行安装程序
echo        安装时请设置 root 密码
echo.

pause

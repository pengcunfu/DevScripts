@echo off
chcp 65001 >nul
title MySQL 安装工具

echo ════════════════════════════════════════
echo       MySQL 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo 请选择要安装的 MySQL 版本：
echo.
echo [1] MySQL 8.0 (推荐)
echo [2] MySQL 8.4 (最新创新版)
echo [0] 打开官网下载页面
echo.
set /p choice=请选择版本:

if "%choice%"=="1" (
    echo.
    echo [信息] 正在安装 MySQL 8.0...
    winget install Oracle.MySQL.8.0 --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [信息] 正在安装 MySQL 8.4...
    winget install Oracle.MySQL --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="0" (
    start https://dev.mysql.com/downloads/mysql/
    exit /b 0
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] MySQL 安装完成！
    echo ════════════════════════════════════════
    echo.
    echo [提示] 请配置 MySQL 服务：
    echo   1. 初始化数据库
    echo   2. 设置 root 密码
    echo   3. 启动 MySQL 服务
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://dev.mysql.com/downloads/mysql/
)

pause

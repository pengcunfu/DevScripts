@echo off
chcp 65001 >nul
title PHP 安装工具

echo ════════════════════════════════════════
echo       PHP 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo 请选择要安装的 PHP 版本：
echo.
echo [1] PHP 8.1 (LTS)
echo [2] PHP 8.2 (LTS)
echo [3] PHP 8.3 (Current)
echo [0] 打开官网下载页面
echo.
set /p choice=请选择版本:

if "%choice%"=="1" set VERSION=8.1
if "%choice%"=="2" set VERSION=8.2
if "%choice%"=="3" set VERSION=8.3

if defined VERSION (
    echo.
    echo [信息] 正在下载 PHP %VERSION%...
    echo.

    :: 下载 PHP
    powershell -Command "Invoke-WebRequest -Uri 'https://windows.php.net/downloads/releases/php-%VERSION%-Win32-vs17-x64.zip' -OutFile '$env:TEMP\php.zip'"

    if exist %TEMP%\php.zip (
        :: 创建安装目录
        if not exist "C:\php" mkdir "C:\php"

        :: 解压 PHP
        powershell -Command "Expand-Archive -Path '%TEMP%\php.zip' -DestinationPath 'C:\php' -Force"

        :: 配置 php.ini
        copy "C:\php\php.ini-development" "C:\php\php.ini"
        powershell -Command "(Get-Content 'C:\php\php.ini') -replace ';extension_dir = \"ext\"', 'extension_dir = \"C:\php\ext\"' | Set-Content 'C:\php\php.ini'"

        echo.
        echo ════════════════════════════════════════
        echo [成功] PHP 安装完成！
        echo ════════════════════════════════════════
        echo.
        echo 安装目录: C:\php
        echo.
        echo [提示] 请将 C:\php 添加到系统 PATH 环境变量
        echo        或使用提供的 PHP 环境切换工具
        echo.
        php --version
    ) else (
        echo [错误] 下载失败，请手动下载
        start https://windows.php.net/download/
    )
) else if "%choice%"=="0" (
    start https://windows.php.net/download/
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

pause

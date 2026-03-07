@echo off
chcp 65001 >nul
title Nginx 安装工具

echo ════════════════════════════════════════
echo       Nginx 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo [提示] Nginx 在 Windows 上的安装方式
echo.
echo [1] 下载官方 Windows 版本（推荐）
echo [2] 使用 WSL 运行 Linux 版本
echo [3] 打开官方文档
echo.
set /p choice=请选择安装方式:

if "%choice%"=="1" (
    echo.
    echo [信息] 正在下载 Nginx...
    echo.

    :: 获取最新版本
    for /f "tokens=*" %%i in ('powershell -Command "(Invoke-WebRequest -Uri 'https://nginx.org/en/download.html' -UseBasicParsing).Content | Select-String -Pattern 'nginx-([0-9.]+)\.zip' | Select-Object -First 1 | ForEach-Object {$_ -replace '.*nginx-([0-9.]+)\.zip.*','$1'}"') do set NGINX_VERSION=%%i

    if not defined NGINX_VERSION set NGINX_VERSION=1.26.0

    echo [信息] 下载 Nginx %NGINX_VERSION%...
    powershell -Command "Invoke-WebRequest -Uri 'https://nginx.org/download/nginx-%NGINX_VERSION%.zip' -OutFile '$env:TEMP\nginx.zip'"

    if exist %TEMP%\nginx.zip (
        echo [信息] 解压到 C:\nginx...
        powershell -Command "Expand-Archive -Path '%TEMP%\nginx.zip' -DestinationPath 'C:\' -Force"

        echo.
        echo ════════════════════════════════════════
        echo [成功] Nginx 安装完成！
        echo ════════════════════════════════════════
        echo.
        echo 安装目录: C:\nginx-%NGINX_VERSION%
        echo 使用方法:
        echo   启动: C:\nginx-%NGINX_VERSION%\nginx.exe
        echo   停止: C:\nginx-%NGINX_VERSION%\nginx.exe -s stop
        echo   重载: C:\nginx-%NGINX_VERSION%\nginx.exe -s reload
    ) else (
        echo [错误] 下载失败
    )
) else if "%choice%"=="2" (
    echo.
    echo [提示] 请先安装 WSL，然后运行 Linux 安装脚本
    echo.
    echo 安装 WSL 命令: wsl --install
) else if "%choice%"=="3" (
    start https://nginx.org/en/docs/windows.html
)

pause

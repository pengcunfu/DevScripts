@echo off
chcp 65001 >nul
title Redis 安装工具

echo ════════════════════════════════════════
echo       Redis 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo [提示] Redis 在 Windows 上的安装方式
echo.
echo [1] 下载 Memurai (Redis 兼容，推荐)
echo [2] 使用 WSL 运行原生 Redis
echo [3] 下载 Redis Windows 移植版
echo.
set /p choice=请选择安装方式:

if "%choice%"=="1" (
    echo.
    echo [信息] 打开 Memurai 官网...
    echo Memurai 是 Redis 的 Windows 兼容版本
    echo 由 Redis 原开发者维护
    start https://www.memurai.com/get-memurai
) else if "%choice%"=="2" (
    echo.
    echo [提示] 请先安装 WSL，然后运行 Linux Redis 安装脚本
    echo.
    echo 安装 WSL 命令: wsl --install
) else if "%choice%"=="3" (
    echo.
    echo [信息] 下载 Redis Windows 版本...
    echo.
    echo [警告] 这是非官方移植版，建议用于开发环境
    echo.
    pause

    :: 下载 Redis
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/microsoftarchive/redis/releases/download/win-3.2.100/Redis-x64-3.2.100.zip' -OutFile '$env:TEMP\redis.zip'"

    if exist %TEMP%\redis.zip (
        :: 创建安装目录
        if not exist "C:\redis" mkdir "C:\redis"

        :: 解压 Redis
        powershell -Command "Expand-Archive -Path '%TEMP%\redis.zip' -DestinationPath 'C:\redis' -Force"

        :: 注册为服务
        "C:\redis\redis-server.exe" --service-install

        echo.
        echo ════════════════════════════════════════
        echo [成功] Redis 安装完成！
        echo ════════════════════════════════════════
        echo.
        echo 安装目录: C:\redis
        echo.
        echo 使用方法：
        echo   启动服务: net start Redis
        echo   停止服务: net stop Redis
        echo   命令行: C:\redis\redis-cli.exe
    ) else (
        echo [错误] 下载失败
    )
)

pause

@echo off
chcp 65001 >nul
title Docker Compose 安装工具

echo ════════════════════════════════════════
echo      Docker Compose 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

:: 检查是否已安装
where docker-compose >nul 2>&1
if %errorlevel% equ 0 (
    echo [信息] 检测到已安装 Docker Compose
    docker-compose --version
    echo.
    set /p reinstall=是否重新安装？(Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [信息] 正在安装 Docker Compose...
echo.
echo [提示] Docker Desktop 已包含 Docker Compose
echo        如果已安装 Docker Desktop，无需单独安装
echo.
set /p choice=是否继续安装独立版本？(Y/N):
if /i not "!choice!"=="Y" exit /b 0

:: 下载最新版本
for /f "tokens=*" %%i in ('powershell -Command "Invoke-WebRequest -Uri https://api.github.com/repos/docker/compose/releases/latest -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"') do set COMPOSE_VERSION=%%i

echo [信息] 下载 Docker Compose %COMPOSE_VERSION%...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/docker/compose/releases/download/%COMPOSE_VERSION%/docker-compose-windows-x86_64.exe' -OutFile '%SystemRoot%\System32\docker-compose.exe'"

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] Docker Compose 安装完成！
    echo ════════════════════════════════════════
    docker-compose --version
) else (
    echo [错误] 下载失败，请检查网络连接
)

pause

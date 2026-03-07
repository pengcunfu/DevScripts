@echo off
chcp 65001 >nul
title PostgreSQL 安装工具

echo ════════════════════════════════════════
echo    PostgreSQL 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo 请选择要安装的 PostgreSQL 版本：
echo.
echo [1] PostgreSQL 16 (LTS)
echo [2] PostgreSQL 17 (最新)
echo.
set /p choice=请选择版本:

if "%choice%"=="1" (
    echo.
    echo [信息] 正在安装 PostgreSQL 16...
    winget install PostgreSQL.PostgreSQL.16 --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [信息] 正在安装 PostgreSQL 17...
    winget install PostgreSQL.PostgreSQL.17 --accept-package-agreements --accept-source-agreements
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] PostgreSQL 安装完成！
    echo ════════════════════════════════════════
    echo.
    echo [提示] 默认配置：
    echo   端口: 5432
    echo   用户: postgres
    echo   数据目录: C:\Program Files\PostgreSQL\[版本]\data
    echo.
    echo 请在安装过程中设置 postgres 用户密码
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://www.postgresql.org/download/windows/
)

pause

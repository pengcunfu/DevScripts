@echo off
chcp 65001 >nul
title JDK 安装工具

echo ════════════════════════════════════════
echo       JDK 安装工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo 请选择要安装的 JDK 版本：
echo.
echo [1] Oracle JDK 17 (推荐)
echo [2] Oracle JDK 21 (最新)
echo [3] OpenJDK 17
echo [4] OpenJDK 21
echo.
set /p choice=请选择版本:

if "%choice%"=="1" set PKG=Oracle.JDK.17
if "%choice%"=="2" set PKG=Oracle.JDK.21
if "%choice%"=="3" set PKG=AdoptOpenJDK.OpenJDK.17
if "%choice%"=="4" set PKG=AdoptOpenJDK.OpenJDK.21

if not defined PKG (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

echo.
echo [信息] 正在安装 JDK...
echo.

:: 使用 winget 安装
winget install %PKG% --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] JDK 安装完成！
    echo ════════════════════════════════════════
    echo.
    java -version
    echo.
    echo [提示] 请重新打开命令提示符以使用 Java
    echo        或运行: refreshenv
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://www.oracle.com/java/technologies/downloads/
)

pause

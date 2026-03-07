@echo off
chcp 65001 >nul
title Node.js 安装工具

echo ════════════════════════════════════════
echo      Node.js 安装工具
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
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo [信息] 检测到已安装 Node.js
    node --version
    echo.
    set /p reinstall=是否重新安装？(Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo 请选择要安装的 Node.js 版本：
echo.
echo [1] Node.js LTS (推荐)
echo [2] Node.js Current (最新)
echo [3] 使用 nvm-windows (版本管理器)
echo.
set /p choice=请选择版本:

if "%choice%"=="1" (
    echo.
    echo [信息] 正在安装 Node.js LTS...
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [信息] 正在安装 Node.js Current...
    winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="3" (
    echo.
    echo [信息] 正在安装 nvm-windows...
    echo.
    echo [提示] nvm-windows 安装完成后：
    echo   nvm install 20    安装 Node.js 20
    echo   nvm use 20        切换到 Node.js 20
    echo   nvm list          查看已安装版本
    echo.
    winget install CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] Node.js 安装完成！
    echo ════════════════════════════════════════
    echo.
    node --version
    npm --version
    echo.
    echo [提示] 请重新打开命令提示符以使用 Node.js
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://nodejs.org/
)

pause

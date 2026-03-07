@echo off
chcp 65001 >nul
title Git 安装工具

echo ════════════════════════════════════════
echo         Git 安装工具
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
where git >nul 2>&1
if %errorlevel% equ 0 (
    echo [信息] 检测到已安装 Git
    git --version
    echo.
    set /p reinstall=是否重新安装？(Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [信息] 正在安装 Git...
echo.

:: 使用 winget 安装
winget install Git.Git --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] Git 安装完成！
    echo ════════════════════════════════════════
    echo.
    git --version
    echo.
    echo [提示] 请配置 Git 用户信息：
    echo   git config --global user.name "Your Name"
    echo   git config --global user.email "your@email.com"
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://git-scm.com/download/win
)

pause

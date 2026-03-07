@echo off
chcp 65001 >nul
title Go 语言安装工具

echo ════════════════════════════════════════
echo       Go 语言安装工具
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
where go >nul 2>&1
if %errorlevel% equ 0 (
    echo [信息] 检测到已安装 Go
    go version
    echo.
    set /p reinstall=是否重新安装？(Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [信息] 正在安装 Go 语言...
echo.

:: 使用 winget 安装
winget install GoLang.Go --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ════════════════════════════════════════
    echo [成功] Go 语言安装完成！
    echo ════════════════════════════════════════
    echo.
    go version
    echo.
    echo [提示] 请重新打开命令提示符以使用 Go
    echo        或运行: refreshenv
) else (
    echo [错误] 安装失败，请手动下载安装
    echo 下载地址: https://golang.org/dl/
)

pause

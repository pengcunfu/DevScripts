@echo off
chcp 65001 >nul
title Hyper-V 安装工具

echo ════════════════════════════════════════
echo        Hyper-V 安装工具
echo ════════════════════════════════════════
echo.
echo 此脚本将启用 Windows Hyper-V 功能
echo 仅支持 Windows Pro/Enterprise 版本
echo.
pause

echo.
echo 正在启用 Hyper-V...
echo.

:: 添加所有 Hyper-V 相关包
for /f %%i in ('dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum 2^>nul') do (
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" >nul 2>&1
)

:: 启用 Hyper-V 功能
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL /NoRestart

echo.
echo ════════════════════════════════════════
echo Hyper-V 安装完成！
echo ════════════════════════════════════════
echo.
echo 请重启计算机以完成安装
echo.
set /p restart=是否立即重启？(Y/N):
if /i "%restart%"=="Y" (
    shutdown /r /t 10 /c "Hyper-V 安装完成，重启中..."
    echo 10秒后重启...
) else (
    echo 请稍后手动重启计算机
)

pause

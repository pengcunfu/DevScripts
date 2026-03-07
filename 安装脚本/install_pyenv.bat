@echo off
chcp 65001 >nul
title Python 版本管理工具

echo ════════════════════════════════════════
echo    Python 版本管理工具
echo ════════════════════════════════════════
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 此脚本需要管理员权限运行
    pause
    exit /b 1
)

echo 请选择要安装的 Python 管理工具：
echo.
echo [1] pyenv-win (推荐，类似 Linux pyenv)
echo [2] 下载官方 Python (单一版本)
echo.
set /p choice=请选择:

if "%choice%"=="1" (
    echo.
    echo [信息] 正在安装 pyenv-win...
    echo.

    :: 使用 Git 克隆 pyenv-win
    if not exist "%USERPROFILE%\.pyenv" (
        git clone https://github.com/pyenv-win/pyenv-win.git "%USERPROFILE%\.pyenv-win"
    )

    :: 设置环境变量
    setx PYENV "%USERPROFILE%\.pyenv-win\pyenv-win" /M
    setx PATH "%PATH%;%USERPROFILE%\.pyenv-win\pyenv-win\bin;%USERPROFILE%\.pyenv-win\pyenv-win\shims" /M

    echo.
    echo ════════════════════════════════════════
    echo [成功] pyenv-win 安装完成！
    echo ════════════════════════════════════════
    echo.
    echo 请重新打开命令提示符后使用：
    echo   pyenv install --list    查看可用版本
    echo   pyenv install 3.12      安装 Python 3.12
    echo   pyenv global 3.12       设置全局版本
    echo   pyenv versions          查看已安装版本
) else if "%choice%"=="2" (
    echo.
    echo [信息] 打开 Python 官网下载页面...
    start https://www.python.org/downloads/windows/
) else (
    echo [错误] 无效的选择
    pause
    exit /b 1
)

pause

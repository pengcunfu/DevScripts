@echo off
chcp 65001 >nul
title NPM 镜像配置工具

:MENU
cls
echo ════════════════════════════════════════
echo            NPM 镜像配置工具
echo ════════════════════════════════════════
echo.
echo [1] 淘宝镜像（推荐国内用户）
echo [2] 官方源（国外服务器）
echo [3] 腾讯云镜像
echo [4] 华为云镜像
echo [5] 查看当前镜像源
echo [6] 测试镜像速度
echo [0] 退出
echo.
echo ════════════════════════════════════════
set /p choice=请选择操作:

if "%choice%"=="1" goto taobao
if "%choice%"=="2" goto official
if "%choice%"=="3" goto tencent
if "%choice%"=="4" goto huawei
if "%choice%"=="5" goto view
if "%choice%"=="6" goto test
if "%choice%"=="0" exit
goto MENU

:taobao
echo.
echo 正在配置淘宝镜像...
npm config set registry https://registry.npmmirror.com
echo ✓ 已切换到淘宝镜像
pause
goto MENU

:official
echo.
echo 正在配置官方源...
npm config set registry https://registry.npmjs.org
echo ✓ 已切换到官方源
pause
goto MENU

:tencent
echo.
echo 正在配置腾讯云镜像...
npm config set registry https://mirrors.cloud.tencent.com/npm/
echo ✓ 已切换到腾讯云镜像
pause
goto MENU

:huawei
echo.
echo 正在配置华为云镜像...
npm config set registry https://mirrors.huaweicloud.com/repository/npm/
echo ✓ 已切换到华为云镜像
pause
goto MENU

:view
echo.
echo 当前镜像源:
npm config get registry
pause
goto MENU

:test
echo.
echo 正在测试镜像速度...
npm config get registry
echo.
echo 测试中，请稍候...
npm config set registry https://registry.npmmirror.com
npm install -c npm-check -s >nul 2>&1
echo ✓ 测试完成
pause
goto MENU

@echo off
title NPM Mirror Configuration Tool

:MENU
cls
echo ===========================================
echo         NPM Mirror Configuration Tool
echo ===========================================
echo.
echo [1] Taobao Mirror (Recommended for China)
echo [2] Official Source (International)
echo [3] Tencent Cloud Mirror
echo [4] Huawei Cloud Mirror
echo [5] View Current Mirror
echo [6] Test Mirror Speed
echo [0] Exit
echo.
echo ===========================================
set /p choice=Select operation:

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
echo Configuring Taobao mirror...
npm config set registry https://registry.npmmirror.com
echo Switched to Taobao mirror
pause
goto MENU

:official
echo.
echo Configuring official source...
npm config set registry https://registry.npmjs.org
echo Switched to official source
pause
goto MENU

:tencent
echo.
echo Configuring Tencent Cloud mirror...
npm config set registry https://mirrors.cloud.tencent.com/npm/
echo Switched to Tencent Cloud mirror
pause
goto MENU

:huawei
echo.
echo Configuring Huawei Cloud mirror...
npm config set registry https://mirrors.huaweicloud.com/repository/npm/
echo Switched to Huawei Cloud mirror
pause
goto MENU

:view
echo.
echo Current mirror source:
npm config get registry
pause
goto MENU

:test
echo.
echo Testing mirror speed...
npm config get registry
echo.
echo Testing, please wait...
npm config set registry https://registry.npmmirror.com
npm install -c npm-check -s >nul 2>&1
echo Test completed
pause
goto MENU

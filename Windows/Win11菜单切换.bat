@echo off
setlocal EnableDelayedExpansion
title Win11菜单切换

:menu
cls
echo Win11 菜单样式切换
echo.
echo [1] Win11 默认菜单
echo [2] Win10 经典菜单
echo [0] 退出
echo.
set /p "choice=选择: "

if "!choice!"=="1" goto win11
if "!choice!"=="2" goto win10
if "!choice!"=="0" exit
goto menu

:win11
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe
echo 已恢复 Win11 菜单
pause
goto menu

:win10
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe
echo 已切换 Win10 菜单
pause
goto menu

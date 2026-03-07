@echo off
:: Win11 Right-Click Menu Switcher
:: Supports automatic admin permission detection and Windows 11 version verification

:: ===== 1. Admin Permission Check =====
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run this script as Administrator!
    echo Right-click script -^> Select "Run as administrator"
    pause
    exit /b 1
)

:: ===== 2. Windows 11 Version Check =====
for /f "tokens=4-5 delims=. " %%i in ('ver') do (
    set OS_MAJOR=%%i
    set OS_MINOR=%%j
)
if not "%OS_MAJOR%"=="10" (
    echo Error: This script only supports Windows 10/11
    pause
    exit /b 1
)

:: ===== Main Menu =====
echo Please select operation
echo 1. Disable modern context menu (Show more options, Win10 style)
echo 2. Restore modern context menu (Win11 default style)
echo 0. Exit
set /p choice=Enter number and press Enter:

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="0" exit

:disable
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f
taskkill /f /im explorer.exe >nul
start explorer.exe
echo Context menu disabled, please refresh desktop!
goto end

:enable
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
taskkill /f /im explorer.exe >nul
start explorer.exe
echo Restored Win11 default context menu
goto end

:end
pause

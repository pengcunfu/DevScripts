@echo off
rem ============================================================================
rem Win11 Menu Switcher
rem ----------------------------------------------------------------------------
rem Switch between Windows 11 compact context menu and Windows 10 classic menu.
rem
rem Features:
rem   - Restore Win11 default right-click menu
rem   - Switch to Win10-style full context menu
rem
rem Usage: Double-click to run (no admin required). Restarts Explorer.
rem ============================================================================
setlocal EnableDelayedExpansion
title Win11 Menu Switcher

:menu
cls
echo Win11 Menu Style Switcher
echo.
echo [1] Win11 Default Menu
echo [2] Win10 Classic Menu
echo [0] Exit
echo.
set /p "choice=Select: "

if "!choice!"=="1" goto win11
if "!choice!"=="2" goto win10
if "!choice!"=="0" exit
goto menu

:win11
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe
echo Restored Win11 menu
pause
goto menu

:win10
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe
echo Switched to Win10 menu
pause
goto menu

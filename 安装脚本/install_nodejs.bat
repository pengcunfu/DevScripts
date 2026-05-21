@echo off
rem ============================================================================
rem Node.js Installer
rem ----------------------------------------------------------------------------
rem Install Node.js LTS, Current, or nvm-windows via winget.
rem
rem Features:
rem   - Node.js LTS or Current
rem   - nvm-windows version manager
rem   - Detect existing installation
rem
rem Usage: Run as Administrator.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title Node.js Installer

echo ========================================
echo      Node.js Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

:: Check if already installed
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Node.js is already installed
    node --version
    echo.
    set /p reinstall=Reinstall? (Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo Select Node.js version to install:
echo.
echo [1] Node.js LTS (recommended)
echo [2] Node.js Current (latest)
echo [3] nvm-windows (version manager)
echo.
set /p choice=Select version:

if "%choice%"=="1" (
    echo.
    echo [INFO] Installing Node.js LTS...
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Installing Node.js Current...
    winget install OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="3" (
    echo.
    echo [INFO] Installing nvm-windows...
    echo.
    echo [TIP] After nvm-windows is installed:
    echo   nvm install 20    Install Node.js 20
    echo   nvm use 20        Switch to Node.js 20
    echo   nvm list          List installed versions
    echo.
    winget install CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Node.js installed successfully!
    echo ========================================
    echo.
    node --version
    npm --version
    echo.
    echo [TIP] Open a new Command Prompt to use Node.js
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://nodejs.org/
)

pause

@echo off
rem ============================================================================
rem Go Installer
rem ----------------------------------------------------------------------------
rem Install Go programming language via winget.
rem
rem Features:
rem   - Detect existing Go installation
rem   - Optional reinstall
rem
rem Usage: Run as Administrator. Open new terminal after install.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title Go Installer

echo ========================================
echo       Go Installer
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
where go >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Go is already installed
    go version
    echo.
    set /p reinstall=Reinstall? (Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [INFO] Installing Go...
echo.

:: Install via winget
winget install GoLang.Go --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Go installed successfully!
    echo ========================================
    echo.
    go version
    echo.
    echo [TIP] Open a new Command Prompt to use Go
    echo        or run: refreshenv
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://golang.org/dl/
)

pause

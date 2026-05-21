@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Git Installer

echo ========================================
echo         Git Installer
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
where git >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Git is already installed
    git --version
    echo.
    set /p reinstall=Reinstall? (Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [INFO] Installing Git...
echo.

:: Install via winget
winget install Git.Git --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Git installed successfully!
    echo ========================================
    echo.
    git --version
    echo.
    echo [TIP] Configure Git user info:
    echo   git config --global user.name "Your Name"
    echo   git config --global user.email "your@email.com"
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://git-scm.com/download/win
)

pause

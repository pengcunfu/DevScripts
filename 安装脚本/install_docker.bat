@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Docker Desktop Installer

echo ========================================
echo       Docker Desktop Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    echo Right-click the script and select "Run as administrator".
    pause
    exit /b 1
)

:: Check if already installed
where docker >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Docker is already installed
    docker --version
    echo.
    set /p reinstall=Reinstall? (Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [INFO] Installing Docker Desktop...
echo.

:: Install via winget
winget install Docker.DockerDesktop --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Docker Desktop installed successfully!
    echo ========================================
    echo.
    echo Sign out and sign back in, or restart your computer to finish setup.
    echo After startup, run Docker in WSL 2 or Hyper-V mode.
) else (
    echo.
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://www.docker.com/products/docker-desktop
)

pause

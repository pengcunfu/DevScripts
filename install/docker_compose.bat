@echo off
rem ============================================================================
rem Docker Compose Installer
rem ----------------------------------------------------------------------------
rem Install standalone docker-compose CLI (separate from Docker Desktop).
rem
rem Features:
rem   - Detect existing docker-compose
rem   - Skip if Docker Desktop already includes Compose
rem   - Download latest release from GitHub to System32
rem
rem Usage: Run as Administrator.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title Docker Compose Installer

echo ========================================
echo      Docker Compose Installer
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
where docker-compose >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Docker Compose is already installed
    docker-compose --version
    echo.
    set /p reinstall=Reinstall? (Y/N):
    if /i not "!reinstall!"=="Y" exit /b 0
)

echo [INFO] Installing Docker Compose...
echo.
echo [TIP] Docker Desktop already includes Docker Compose.
echo        If Docker Desktop is installed, a standalone install is not required.
echo.
set /p choice=Continue with standalone install? (Y/N):
if /i not "!choice!"=="Y" exit /b 0

:: Download latest version
for /f "tokens=*" %%i in ('powershell -Command "Invoke-WebRequest -Uri https://api.github.com/repos/docker/compose/releases/latest -UseBasicParsing | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"') do set COMPOSE_VERSION=%%i

echo [INFO] Downloading Docker Compose %COMPOSE_VERSION%...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/docker/compose/releases/download/%COMPOSE_VERSION%/docker-compose-windows-x86_64.exe' -OutFile '%SystemRoot%\System32\docker-compose.exe'"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Docker Compose installed successfully!
    echo ========================================
    docker-compose --version
) else (
    echo [ERROR] Download failed. Please check your network connection.
)

pause

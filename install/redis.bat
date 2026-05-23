@echo off
rem ============================================================================
rem Redis Installer
rem ----------------------------------------------------------------------------
rem Install Redis on Windows via Memurai, WSL, or legacy Windows port.
rem
rem Features:
rem   - Memurai (Redis-compatible, recommended)
rem   - WSL native Redis instructions
rem   - Download legacy Redis zip and register Windows service
rem
rem Usage: Run as Administrator (for service install option).
rem ============================================================================
chcp 65001 >nul
title Redis Installer

echo ========================================
echo       Redis Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo [INFO] Redis installation options on Windows
echo.
echo [1] Download Memurai (Redis-compatible, recommended)
echo [2] Run native Redis via WSL
echo [3] Download Redis Windows port
echo.
set /p choice=Select installation method:

if "%choice%"=="1" (
    echo.
    echo [INFO] Opening Memurai website...
    echo Memurai is a Redis-compatible build for Windows
    echo maintained by the original Redis developers
    start https://www.memurai.com/get-memurai
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Install WSL first, then run redis.sh from the Linux install folder
    echo.
    echo Install WSL: wsl --install
) else if "%choice%"=="3" (
    echo.
    echo [INFO] Downloading Redis for Windows...
    echo.
    echo [WARNING] This is an unofficial port. Recommended for development only.
    echo.
    pause

    :: Download Redis
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/microsoftarchive/redis/releases/download/win-3.2.100/Redis-x64-3.2.100.zip' -OutFile '$env:TEMP\redis.zip'"

    if exist %TEMP%\redis.zip (
        :: Create install directory
        if not exist "C:\redis" mkdir "C:\redis"

        :: Extract Redis
        powershell -Command "Expand-Archive -Path '%TEMP%\redis.zip' -DestinationPath 'C:\redis' -Force"

        :: Register as Windows service
        "C:\redis\redis-server.exe" --service-install

        echo.
        echo ========================================
        echo [SUCCESS] Redis installed successfully!
        echo ========================================
        echo.
        echo Install directory: C:\redis
        echo.
        echo Usage:
        echo   Start service: net start Redis
        echo   Stop service:  net stop Redis
        echo   CLI:           C:\redis\redis-cli.exe
    ) else (
        echo [ERROR] Download failed
    )
)

pause

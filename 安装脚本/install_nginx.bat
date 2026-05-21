@echo off
rem ============================================================================
rem Nginx Installer
rem ----------------------------------------------------------------------------
rem Install Nginx on Windows or guide WSL-based setup.
rem
rem Features:
rem   - Download official Windows zip to C:\nginx
rem   - WSL install instructions
rem   - Open official documentation
rem
rem Usage: Run as Administrator (for extract to C:\).
rem ============================================================================
chcp 65001 >nul
title Nginx Installer

echo ========================================
echo       Nginx Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo [INFO] Nginx installation options on Windows
echo.
echo [1] Download official Windows build (recommended)
echo [2] Run Linux version via WSL
echo [3] Open official documentation
echo.
set /p choice=Select installation method:

if "%choice%"=="1" (
    echo.
    echo [INFO] Downloading Nginx...
    echo.

    :: Get latest version
    for /f "tokens=*" %%i in ('powershell -Command "(Invoke-WebRequest -Uri 'https://nginx.org/en/download.html' -UseBasicParsing).Content | Select-String -Pattern 'nginx-([0-9.]+)\.zip' | Select-Object -First 1 | ForEach-Object {$_ -replace '.*nginx-([0-9.]+)\.zip.*','$1'}"') do set NGINX_VERSION=%%i

    if not defined NGINX_VERSION set NGINX_VERSION=1.26.0

    echo [INFO] Downloading Nginx %NGINX_VERSION%...
    powershell -Command "Invoke-WebRequest -Uri 'https://nginx.org/download/nginx-%NGINX_VERSION%.zip' -OutFile '$env:TEMP\nginx.zip'"

    if exist %TEMP%\nginx.zip (
        echo [INFO] Extracting to C:\nginx...
        powershell -Command "Expand-Archive -Path '%TEMP%\nginx.zip' -DestinationPath 'C:\' -Force"

        echo.
        echo ========================================
        echo [SUCCESS] Nginx installed successfully!
        echo ========================================
        echo.
        echo Install directory: C:\nginx-%NGINX_VERSION%
        echo Usage:
        echo   Start:  C:\nginx-%NGINX_VERSION%\nginx.exe
        echo   Stop:   C:\nginx-%NGINX_VERSION%\nginx.exe -s stop
        echo   Reload: C:\nginx-%NGINX_VERSION%\nginx.exe -s reload
    ) else (
        echo [ERROR] Download failed
    )
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Install WSL first, then run install_nginx.sh from the Linux install-scripts folder
    echo.
    echo Install WSL: wsl --install
) else if "%choice%"=="3" (
    start https://nginx.org/en/docs/windows.html
)

pause

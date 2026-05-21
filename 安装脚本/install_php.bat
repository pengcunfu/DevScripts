@echo off
chcp 65001 >nul
title PHP Installer

echo ========================================
echo       PHP Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo Select PHP version to install:
echo.
echo [1] PHP 8.1 (LTS)
echo [2] PHP 8.2 (LTS)
echo [3] PHP 8.3 (Current)
echo [0] Open official download page
echo.
set /p choice=Select version:

if "%choice%"=="1" set VERSION=8.1
if "%choice%"=="2" set VERSION=8.2
if "%choice%"=="3" set VERSION=8.3

if defined VERSION (
    echo.
    echo [INFO] Downloading PHP %VERSION%...
    echo.

    :: Download PHP
    powershell -Command "Invoke-WebRequest -Uri 'https://windows.php.net/downloads/releases/php-%VERSION%-Win32-vs17-x64.zip' -OutFile '$env:TEMP\php.zip'"

    if exist %TEMP%\php.zip (
        :: Create install directory
        if not exist "C:\php" mkdir "C:\php"

        :: Extract PHP
        powershell -Command "Expand-Archive -Path '%TEMP%\php.zip' -DestinationPath 'C:\php' -Force"

        :: Configure php.ini
        copy "C:\php\php.ini-development" "C:\php\php.ini"
        powershell -Command "(Get-Content 'C:\php\php.ini') -replace ';extension_dir = \"ext\"', 'extension_dir = \"C:\php\ext\"' | Set-Content 'C:\php\php.ini'"

        echo.
        echo ========================================
        echo [SUCCESS] PHP installed successfully!
        echo ========================================
        echo.
        echo Install directory: C:\php
        echo.
        echo [TIP] Add C:\php to the system PATH
        echo        or use the provided PHP version switcher tool
        echo.
        php --version
    ) else (
        echo [ERROR] Download failed. Please download manually.
        start https://windows.php.net/download/
    )
) else if "%choice%"=="0" (
    start https://windows.php.net/download/
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

pause

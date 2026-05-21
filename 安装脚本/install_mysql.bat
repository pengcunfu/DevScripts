@echo off
rem ============================================================================
rem MySQL Installer
rem ----------------------------------------------------------------------------
rem Install MySQL 8.0 or 8.4 on Windows via winget.
rem
rem Features:
rem   - MySQL 8.0 (recommended) or 8.4
rem   - Open official download page
rem   - Post-install setup hints
rem
rem Usage: Run as Administrator.
rem ============================================================================
chcp 65001 >nul
title MySQL Installer

echo ========================================
echo       MySQL Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo Select MySQL version to install:
echo.
echo [1] MySQL 8.0 (recommended)
echo [2] MySQL 8.4 (latest innovation release)
echo [0] Open official download page
echo.
set /p choice=Select version:

if "%choice%"=="1" (
    echo.
    echo [INFO] Installing MySQL 8.0...
    winget install Oracle.MySQL.8.0 --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Installing MySQL 8.4...
    winget install Oracle.MySQL --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="0" (
    start https://dev.mysql.com/downloads/mysql/
    exit /b 0
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] MySQL installed successfully!
    echo ========================================
    echo.
    echo [TIP] Configure the MySQL service:
    echo   1. Initialize the database
    echo   2. Set the root password
    echo   3. Start the MySQL service
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://dev.mysql.com/downloads/mysql/
)

pause

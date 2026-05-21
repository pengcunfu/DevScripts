@echo off
chcp 65001 >nul
title PostgreSQL Installer

echo ========================================
echo    PostgreSQL Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo Select PostgreSQL version to install:
echo.
echo [1] PostgreSQL 16 (LTS)
echo [2] PostgreSQL 17 (latest)
echo.
set /p choice=Select version:

if "%choice%"=="1" (
    echo.
    echo [INFO] Installing PostgreSQL 16...
    winget install PostgreSQL.PostgreSQL.16 --accept-package-agreements --accept-source-agreements
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Installing PostgreSQL 17...
    winget install PostgreSQL.PostgreSQL.17 --accept-package-agreements --accept-source-agreements
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] PostgreSQL installed successfully!
    echo ========================================
    echo.
    echo [TIP] Default configuration:
    echo   Port:     5432
    echo   User:     postgres
    echo   Data dir: C:\Program Files\PostgreSQL\[version]\data
    echo.
    echo Set the postgres user password during installation.
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://www.postgresql.org/download/windows/
)

pause

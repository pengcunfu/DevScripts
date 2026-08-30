@echo off
rem ============================================================================
rem MariaDB Installer
rem ----------------------------------------------------------------------------
rem Open the official MariaDB download page (manual MSI install).
rem
rem Features:
rem   - Launch mariadb.com downloads
rem   - Version and root password setup hints
rem
rem Usage: Run as Administrator.
rem ============================================================================
chcp 65001 >nul
title MariaDB Installer

echo ========================================
echo      MariaDB Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo [WARNING] MariaDB for Windows must be installed manually.
echo.
echo This script will open the official MariaDB download page.
echo Select the MSI installer for your system.
echo.
echo Recommended: MariaDB 10.x or 11.x
echo.
pause

start https://mariadb.com/downloads/

echo.
echo [TIP] After downloading, run the installer
echo        and set the root password during setup.
echo.

pause

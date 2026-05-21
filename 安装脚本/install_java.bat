@echo off
chcp 65001 >nul
title JDK Installer

echo ========================================
echo       JDK Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo Select JDK version to install:
echo.
echo [1] Oracle JDK 17 (recommended)
echo [2] Oracle JDK 21 (latest)
echo [3] OpenJDK 17
echo [4] OpenJDK 21
echo.
set /p choice=Select version:

if "%choice%"=="1" set PKG=Oracle.JDK.17
if "%choice%"=="2" set PKG=Oracle.JDK.21
if "%choice%"=="3" set PKG=AdoptOpenJDK.OpenJDK.17
if "%choice%"=="4" set PKG=AdoptOpenJDK.OpenJDK.21

if not defined PKG (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

echo.
echo [INFO] Installing JDK...
echo.

:: Install via winget
winget install %PKG% --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] JDK installed successfully!
    echo ========================================
    echo.
    java -version
    echo.
    echo [TIP] Open a new Command Prompt to use Java
    echo        or run: refreshenv
) else (
    echo [ERROR] Installation failed. Please install manually.
    echo Download: https://www.oracle.com/java/technologies/downloads/
)

pause

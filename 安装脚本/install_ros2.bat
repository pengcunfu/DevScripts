@echo off
rem ============================================================================
rem ROS 2 Installer Guide
rem ----------------------------------------------------------------------------
rem Guide ROS 2 installation on Windows (WSL recommended).
rem
rem Features:
rem   - WSL 2 install steps and Linux script reference
rem   - Native Windows binary download links
rem   - Open official ROS 2 documentation
rem
rem Usage: Run as Administrator. Mostly opens docs and prints steps.
rem ============================================================================
chcp 65001 >nul
title ROS 2 Installer

echo ========================================
echo      ROS 2 Installer
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo [INFO] ROS 2 installation options on Windows
echo.
echo ROS 2 officially supports Windows, but WSL is recommended.
echo.
echo [1] Install ROS 2 via WSL 2 (recommended)
echo [2] Download native Windows build
echo [3] Open official documentation
echo.
set /p choice=Select installation method:

if "%choice%"=="1" (
    echo.
    echo [Step 1] Install WSL 2
    echo Run: wsl --install
    echo.
    echo [Step 2] After installing Ubuntu, run install_ros2.sh from the Linux install-scripts folder
    echo.
    echo [Step 3] Enable X11 forwarding (optional, for GUI)
    echo   Install VcXsrv or use WSLg
    echo.
    echo Press any key to open the ROS 2 installation docs...
    pause >nul
    start https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html
) else if "%choice%"=="2" (
    echo.
    echo [INFO] The native Windows ROS 2 build has limited features.
    echo WSL 2 is recommended.
    echo.
    echo Available versions:
    echo   - ROS 2 Humble Hawksbill (recommended)
    echo   - ROS 2 Jazzy Jalisco
    echo.
    pause
    start https://docs.ros.org/en/humble/Installation/Windows-Install-Binary.html
) else if "%choice%"=="3" (
    start https://docs.ros.org/en/humble/Installation.html
)

pause

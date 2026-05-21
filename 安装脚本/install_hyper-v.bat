@echo off
chcp 65001 >nul
title Hyper-V Installer

echo ========================================
echo        Hyper-V Installer
echo ========================================
echo.
echo This script enables the Windows Hyper-V feature.
echo Supported on Windows Pro/Enterprise only.
echo.
pause

echo.
echo Enabling Hyper-V...
echo.

:: Add all Hyper-V related packages
for /f %%i in ('dir /b %SystemRoot%\servicing\Packages\*Hyper-V*.mum 2^>nul') do (
    dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" >nul 2>&1
)

:: Enable Hyper-V feature
dism /online /enable-feature /featurename:Microsoft-Hyper-V-All /LimitAccess /ALL /NoRestart

echo.
echo ========================================
echo Hyper-V enabled successfully!
echo ========================================
echo.
echo Restart your computer to complete installation.
echo.
set /p restart=Restart now? (Y/N):
if /i "%restart%"=="Y" (
    shutdown /r /t 10 /c "Hyper-V setup complete. Restarting..."
    echo Restarting in 10 seconds...
) else (
    echo Please restart your computer manually later.
)

pause

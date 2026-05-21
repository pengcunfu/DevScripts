@echo off
chcp 65001 >nul
title Python Version Manager

echo ========================================
echo    Python Version Manager
echo ========================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges.
    pause
    exit /b 1
)

echo Select a Python management tool:
echo.
echo [1] pyenv-win (recommended, similar to Linux pyenv)
echo [2] Download official Python (single version)
echo.
set /p choice=Select option:

if "%choice%"=="1" (
    echo.
    echo [INFO] Installing pyenv-win...
    echo.

    :: Clone pyenv-win with Git
    if not exist "%USERPROFILE%\.pyenv" (
        git clone https://github.com/pyenv-win/pyenv-win.git "%USERPROFILE%\.pyenv-win"
    )

    :: Set environment variables
    setx PYENV "%USERPROFILE%\.pyenv-win\pyenv-win" /M
    setx PATH "%PATH%;%USERPROFILE%\.pyenv-win\pyenv-win\bin;%USERPROFILE%\.pyenv-win\pyenv-win\shims" /M

    echo.
    echo ========================================
    echo [SUCCESS] pyenv-win installed successfully!
    echo ========================================
    echo.
    echo Open a new Command Prompt, then use:
    echo   pyenv install --list    List available versions
    echo   pyenv install 3.12      Install Python 3.12
    echo   pyenv global 3.12       Set global version
    echo   pyenv versions          List installed versions
) else if "%choice%"=="2" (
    echo.
    echo [INFO] Opening Python download page...
    start https://www.python.org/downloads/windows/
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

pause

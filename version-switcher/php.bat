@echo off
rem ============================================================================
rem PHP Version Switcher
rem ----------------------------------------------------------------------------
rem Switch active PHP by updating system PATH (multiple side-by-side installs).
rem
rem Features:
rem   - Detect current PHP version
rem   - Switch among PHP 7.4, 8.0, 8.1, 8.2, 8.3 (edit base path in script)
rem   - Persist PATH via setx /M
rem   - Auto-elevate if not admin
rem
rem Usage: Run as Administrator. Edit phpBasePath before use.
rem ============================================================================
rem Check for administrator privileges
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem Set custom path and PHP base path (MODIFY TO YOUR PHP INSTALLATION PATH)
set "phpBasePath=D:\Peng\App\DevApp\php-"

rem Check PHP version
php -v > nul 2>&1
if %errorlevel% neq 0 (
    rem Failed
    echo PHP is not currently installed
    echo.
) else (
    rem Success
    for /f "tokens=* delims=" %%i in ('php -v 2^>^&1 ^| findstr /i "PHP"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*PHP =!"
    set "currentVersion=!currentVersion:~0,5!"
    echo Current PHP version: [!currentVersion!]
    echo.
)

rem Display PHP version selection
echo Select PHP version
echo.
echo   Option 1: Version [7.4]
echo.
echo   Option 2: Version [8.0]
echo.
echo   Option 3: Version [8.1]
echo.
echo   Option 4: Version [8.2]
echo.
echo   Option 5: Version [8.3]
echo.

set /p choice=Select version:
echo.

rem Set version based on user choice
if "%choice%" equ "1" set version=7.4
if "%choice%" equ "2" set version=8.0
if "%choice%" equ "3" set version=8.1
if "%choice%" equ "4" set version=8.2
if "%choice%" equ "5" set version=8.3

set "php=!phpBasePath!!version!"

rem Remove old versions, add new version
set "PATH=!PATH:%phpBasePath%7.4=!"
set "PATH=!PATH:%phpBasePath%8.0=!"
set "PATH=!PATH:%phpBasePath%8.1=!"
set "PATH=!PATH:%phpBasePath%8.2=!"
set "PATH=!PATH:%phpBasePath%8.3=!"

set "PATH=!PATH!;!php!"

echo Switched to version [!version!]

rem Write to system environment variables
setx PATH "!PATH!" /M
echo Added to PATH: [!php!]
echo.

rem Display current PHP version
php -v > nul 2>&1
if %errorlevel% neq 0 (
    rem Failed
    echo Setup failed!
) else (
    rem Success
    for /f "tokens=* delims=" %%i in ('php -v 2^>^&1 ^| findstr /i "PHP"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*PHP =!"
    set "currentVersion=!currentVersion:~0,5!"
    echo Current version: [!currentVersion!]
)

echo.
rem Pause and wait for user input
pause

endlocal

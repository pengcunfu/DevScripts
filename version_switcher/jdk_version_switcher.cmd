@echo off
rem ============================================================================
rem JDK Version Switcher
rem ----------------------------------------------------------------------------
rem Switch active JDK by updating system PATH (multiple side-by-side installs).
rem
rem Features:
rem   - Detect current Java version
rem   - Switch among JDK 8, 11, 17 (edit base path in script)
rem   - Persist PATH via setx /M
rem   - Auto-elevate if not admin
rem
rem Usage: Run as Administrator. Edit jdkBasePath before use.
rem ============================================================================
rem Check for administrator privileges
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem Set custom path and JDK base path (MODIFY TO YOUR JDK INSTALLATION PATH)
set "jdkBasePath=D:\Peng\App\DevApp\jdk-"

rem Check Java version
java -version > nul 2>&1
if %errorlevel% neq 0 (
    rem Failed
    echo JDK is not currently installed
    echo.
) else (
    rem Success
    for /f "tokens=* delims=" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*version=!"
    echo Current JDK version: [!currentVersion!]
    echo.
)

rem Display JDK version selection
echo Select JDK version
echo.
echo   Option 1: Version [8]
echo.
echo   Option 2: Version [11]
echo.
echo   Option 3: Version [17]
echo.

set /p choice=Select version:
echo.

rem Set version based on user choice
if "%choice%" equ "1" set version=8
if "%choice%" equ "2" set version=11
if "%choice%" equ "3" set version=17

set "jdk=!jdkBasePath!!version!\bin"

set "PATH=!PATH:%jdkBasePath%8\bin%=!"
set "PATH=!PATH:%jdkBasePath%11\bin%=!"
set "PATH=!PATH:%jdkBasePath%17\bin%=!"
set "PATH=!PATH!;%jdk%"

echo Switched to version [!version!]

rem Write to system environment variables
setx PATH "!PATH!" /M
echo Added to PATH: [!jdk!]
echo.

rem Display current JDK version
java -version > nul 2>&1
if %errorlevel% neq 0 (
    rem Failed
    echo Setup failed!
) else (
    rem Success
    for /f "tokens=* delims=" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*version=!"
    echo Current version: [!currentVersion!]
)

echo.
rem Pause and wait for user input
pause

endlocal

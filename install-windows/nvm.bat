@echo off
rem ============================================================================
rem Node.js PATH Switcher (Multi-Version)
rem ----------------------------------------------------------------------------
rem Switch active Node.js by updating system PATH (side-by-side installs).
rem
rem Features:
rem   - Pick among versions 12 / 16 / 18 / 20 / 22
rem   - Detect current version and skip if unchanged
rem   - Persist PATH via setx /M
rem   - Auto-elevate if not admin
rem
rem Usage: Run as Administrator. Edit basePath before use.
rem ============================================================================
chcp 65001 >nul
rem Check administrator privileges
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem Set custom base path for Node.js (MODIFY TO YOUR INSTALLATION PATH)
set "basePath=D:\Peng\App\DevApp\node"

rem Check node -v
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem Not installed
    echo Node.js is not currently installed
    echo.
) else (
    rem Installed
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"
    echo Current Node.js version: [!currentVersion!]
    echo.
)

rem Display version options
echo Select Node.js version
echo.
echo   Option 1: Version [12.22.12]
echo.
echo   Option 2: Version [16.20.2]
echo.
echo   Option 3: Version [18.20.2]
echo.
echo   Option 4: Version [20.18.2]
echo.
echo   Option 5: Version [22.14.0]
echo.

set /p choice=Select version:
echo.

rem Set version from user choice
if "%choice%" equ "1" set version=12.22.12
if "%choice%" equ "2" set version=16.20.2
if "%choice%" equ "3" set version=18.20.2
if "%choice%" equ "4" set version=20.18.2
if "%choice%" equ "5" set version=22.14.0

set "nodejs=!basePath!!version!"

rem Check node -v again
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem node -v failed, add to PATH
    set "PATH=!PATH!;%nodejs%"

    rem Write system environment variable
    setx PATH "!PATH!" /M
    echo Added to PATH: !nodejs!
    echo.
) else (
    rem node -v succeeded, compare versions
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"

    if "!currentVersion!" equ "!version!" (
        echo Node.js version already active: !version!
        echo Same version, no PATH change needed.
        echo.
    ) else (
        rem Different version: remove old paths, add new one
        set "PATH=!PATH:%basePath%12.22.12=!"
        set "PATH=!PATH:%basePath%16.20.2=!"
        set "PATH=!PATH:%basePath%18.20.2=!"
        set "PATH=!PATH:%basePath%20.18.2=!"
        set "PATH=!PATH:%basePath%22.14.0=!"

        set "PATH=!PATH!;%nodejs%"

        echo Removed old version [!currentVersion!], added new version [!version!]

        rem Write system environment variable
        setx PATH "!PATH!" /M
        echo Added to PATH: [!nodejs!]
        echo.
    )
)

rem Show current Node.js version
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem Failed
    echo Setup failed!
) else (
    rem Success
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"
    echo Current version: [!currentVersion!]
)

echo.
rem Pause before exit
pause

endlocal

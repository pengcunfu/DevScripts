@echo off
rem ============================================================================
rem MongoDB Portable Installer (Green Edition)
rem ----------------------------------------------------------------------------
rem Download and extract MongoDB Community zip — no MSI, no Windows service.
rem
rem Features:
rem   - Portable zip install to a user-writable directory
rem   - No administrator privileges required
rem   - Configurable install path (edit DEFAULT_INSTALL_ROOT)
rem   - Creates data/log dirs and mongod.cfg
rem   - Generates start_mongod.bat / stop_mongod.bat helpers
rem   - MongoDB 6.x / 7.x / 8.x version selection
rem   - Optional portable mongosh (zip)
rem
rem Usage: Double-click to run. Edit defaults below if needed.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title MongoDB Portable Installer

rem ---------- User defaults (edit before running) ----------
set "DEFAULT_INSTALL_ROOT=D:\Env\MongoDB"
set "MONGODB_VERSION=8.0"
set "MONGODB_ZIP_BUILD=8.0.23"
set "MONGOSH_ZIP_BUILD=2.3.8"
rem ---------------------------------------------------------

echo ========================================
echo   MongoDB Portable Installer
echo ========================================
echo.
echo [INFO] Green/portable install — no admin, no Windows service.
echo.

set "INSTALL_ROOT=%DEFAULT_INSTALL_ROOT%"
echo Default install path: %INSTALL_ROOT%
set /p userRoot=Enter install path (Enter = default):
if not "!userRoot!"=="" set "INSTALL_ROOT=!userRoot!"
if "!INSTALL_ROOT:~-1!"=="\" set "INSTALL_ROOT=!INSTALL_ROOT:~0,-1!"

echo.
echo Select MongoDB major version:
echo [1] 8.x  - 8.0.23 (recommended)
echo [2] 7.x  - 7.0.34
echo [3] 6.x  - 6.0.28
echo.
set /p verChoice=Select version:
if "!verChoice!"=="3" (
    set "MONGODB_VERSION=6.0"
    set "MONGODB_ZIP_BUILD=6.0.28"
) else if "!verChoice!"=="2" (
    set "MONGODB_VERSION=7.0"
    set "MONGODB_ZIP_BUILD=7.0.34"
) else if "!verChoice!"=="1" (
    set "MONGODB_VERSION=8.0"
    set "MONGODB_ZIP_BUILD=8.0.23"
) else (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

echo.
echo [1] Server only
echo [2] Server + mongosh (portable zip)
echo [0] Open official download page
echo.
set /p choice=Select option:

if "%choice%"=="0" (
    start https://www.mongodb.com/try/download/community
    exit /b 0
)

if not "%choice%"=="1" if not "%choice%"=="2" (
    echo [ERROR] Invalid selection
    pause
    exit /b 1
)

set "ZIP_NAME=mongodb-windows-x86_64-!MONGODB_ZIP_BUILD!.zip"
set "ZIP_URL=https://fastdl.mongodb.org/windows/!ZIP_NAME!"
set "ZIP_PATH=%TEMP%\!ZIP_NAME!"

if exist "!INSTALL_ROOT!\bin\mongod.exe" (
    echo.
    echo [INFO] MongoDB already exists at: !INSTALL_ROOT!
    mongod --version 2>nul
    if errorlevel 1 call "!INSTALL_ROOT!\bin\mongod.exe" --version 2>nul
    echo.
    set /p overwrite=Re-download and reinstall? [Y/N]:
    if /i not "!overwrite!"=="Y" (
        if "!choice!"=="2" goto maybe_mongosh
        goto finish
    )
)

echo.
echo [INFO] Install path: !INSTALL_ROOT!
echo [INFO] MongoDB version: !MONGODB_ZIP_BUILD!
echo [INFO] Downloading !ZIP_NAME!...
echo.

powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Invoke-WebRequest -Uri '!ZIP_URL!' -OutFile '!ZIP_PATH!' -UseBasicParsing"

if not exist "!ZIP_PATH!" (
    echo [ERROR] Download failed: !ZIP_URL!
    pause
    exit /b 1
)

echo [INFO] Extracting...
if not exist "!INSTALL_ROOT!" mkdir "!INSTALL_ROOT!"

powershell -NoProfile -Command ^
    "Expand-Archive -Path '!ZIP_PATH!' -DestinationPath '!INSTALL_ROOT!' -Force"

set "MONGODB_HOME="
for /d %%d in ("!INSTALL_ROOT!\mongodb-windows-*") do set "MONGODB_HOME=%%d"

if not defined MONGODB_HOME (
    echo [ERROR] Extracted folder not found under !INSTALL_ROOT!
    pause
    exit /b 1
)

if not exist "!INSTALL_ROOT!\bin" mkdir "!INSTALL_ROOT!\bin"
xcopy "!MONGODB_HOME!\bin\*" "!INSTALL_ROOT!\bin\" /E /Y /Q >nul 2>&1

if not exist "!INSTALL_ROOT!\bin\mongod.exe" (
    echo [ERROR] mongod.exe not found after extract.
    pause
    exit /b 1
)

if not exist "!INSTALL_ROOT!\data\db" mkdir "!INSTALL_ROOT!\data\db"
if not exist "!INSTALL_ROOT!\log" mkdir "!INSTALL_ROOT!\log"

set "CFG_FILE=!INSTALL_ROOT!\mongod.cfg"
set "CFG_ROOT=!INSTALL_ROOT:\=/!"

> "!CFG_FILE!" (
    echo systemLog:
    echo   destination: file
    echo   path: !CFG_ROOT!/log/mongod.log
    echo   logAppend: true
    echo storage:
    echo   dbPath: !CFG_ROOT!/data/db
    echo net:
    echo   port: 27017
    echo   bindIp: 127.0.0.1
)

call :write_start_script
call :write_stop_script

rd /s /q "!MONGODB_HOME!" 2>nul
del /f /q "!ZIP_PATH!" 2>nul

echo [INFO] Portable MongoDB server ready.

:maybe_mongosh
if not "%choice%"=="2" goto finish

set "MSH_ZIP=mongosh-!MONGOSH_ZIP_BUILD!-win32-x64.zip"
set "MSH_URL=https://downloads.mongodb.com/compass/!MSH_ZIP!"
set "MSH_PATH=%TEMP%\!MSH_ZIP!"
set "MSH_DIR=!INSTALL_ROOT!\mongosh"

echo.
echo [INFO] Downloading mongosh !MONGOSH_ZIP_BUILD!...

powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Invoke-WebRequest -Uri '!MSH_URL!' -OutFile '!MSH_PATH!' -UseBasicParsing"

if not exist "!MSH_PATH!" (
    echo [WARNING] mongosh download failed. Get it manually:
    echo   https://www.mongodb.com/try/download/shell
    goto finish
)

if not exist "!MSH_DIR!" mkdir "!MSH_DIR!"
powershell -NoProfile -Command "Expand-Archive -Path '!MSH_PATH!' -DestinationPath '!MSH_DIR!' -Force"
del /f /q "!MSH_PATH!" 2>nul
echo [INFO] mongosh extracted to: !MSH_DIR!

:finish
echo.
echo ========================================
echo [SUCCESS] Portable MongoDB is ready!
echo ========================================
echo.
echo   Version:      !MONGODB_ZIP_BUILD!
echo   Install dir:  !INSTALL_ROOT!
echo   mongod:       !INSTALL_ROOT!\bin\mongod.exe
echo   Data:         !INSTALL_ROOT!\data\db
echo   Config:       !INSTALL_ROOT!\mongod.cfg
echo   Start:        !INSTALL_ROOT!\start_mongod.bat
echo   Stop:         !INSTALL_ROOT!\stop_mongod.bat
if "%choice%"=="2" echo   mongosh:      !INSTALL_ROOT!\mongosh\
if "%choice%"=="2" echo   Connect:      mongosh mongodb://127.0.0.1:27017
echo.
echo [TIP] Optional — add to user PATH (no admin):
echo   setx PATH "%%PATH%%;!INSTALL_ROOT!\bin"
echo.
echo [TIP] Start server manually:
echo   "!INSTALL_ROOT!\bin\mongod.exe" --config "!INSTALL_ROOT!\mongod.cfg"
echo.

"!INSTALL_ROOT!\bin\mongod.exe" --version 2>nul

pause
exit /b 0

:write_start_script
set "START_BAT=!INSTALL_ROOT!\start_mongod.bat"
(
    echo @echo off
    echo rem Start portable MongoDB ^(foreground^)
    echo set "MONGO_HOME=%~dp0"
    echo if not exist "%%MONGO_HOME%%data\db" mkdir "%%MONGO_HOME%%data\db"
    echo echo Starting MongoDB on 127.0.0.1:27017 ...
    echo echo Data: %%MONGO_HOME%%data\db
    echo echo Press Ctrl+C to stop.
    echo "%%MONGO_HOME%%bin\mongod.exe" --config "%%MONGO_HOME%%mongod.cfg"
) > "!START_BAT!"
exit /b 0

:write_stop_script
set "STOP_BAT=!INSTALL_ROOT!\stop_mongod.bat"
(
    echo @echo off
    echo rem Stop local mongod process
    echo taskkill /IM mongod.exe /F 2^>nul
    echo if %%errorlevel%% equ 0 ^(
    echo     echo MongoDB stopped.
    echo ^) else ^(
    echo     echo No running mongod.exe found.
    echo ^)
    echo pause
) > "!STOP_BAT!"
exit /b 0

@echo off
rem ============================================================================
rem Node.js Portable Installer (Green Edition)
rem ----------------------------------------------------------------------------
rem Download and extract Node.js zip — no MSI, no winget, no nvm, no admin.
rem
rem Features:
rem   - Portable zip install to a user-writable directory (no admin required)
rem   - Auto-select the fastest mirror among npmmirror/huawei/tencent/ustc/nodejs.org
rem   - Lists ALL downloadable versions from the mirror (index.json) to pick
rem     Falls back to the hard-coded LTS below when offline
rem   - Optional: add install dir to USER PATH (no admin, via PowerShell)
rem   - Generates uninstall.bat helper
rem
rem Usage: Double-click to run. Edit defaults below if needed.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title Node.js Portable Installer

rem ---------- User defaults (edit before running) ----------
rem Install base dir: each version installs to !BASE!\nodejs<version> (no trailing backslash)
set "DEFAULT_INSTALL_ROOT=D:\Env"
rem Architecture: 1 = x64 (default), 2 = arm64
set "DEFAULT_ARCH=1"
rem Fallback versions used only when auto-detection fails (must be real releases)
set "FALLBACK_LTS=24.20.0"
rem ---------------------------------------------------------

set "INSTALL_ROOT=%DEFAULT_INSTALL_ROOT%"
set "ARCH=x64"

echo ========================================
echo   Node.js Portable Installer (Green)
echo ========================================
echo.
echo [INFO] Green/portable install - no admin, no winget, no nvm.
echo.

rem --- List existing Node.js installs under the base dir (informational only) ---
set "FOUND_ANY="
for /d %%d in ("!INSTALL_ROOT!\nodejs*") do (
    if exist "%%d\node.exe" (
        set "FOUND_ANY=1"
        echo [INFO] Found: %%d
        for /f "delims=" %%v in ('"%%d\node.exe" --version 2^>nul') do echo   version: %%v
    )
)
if not defined FOUND_ANY goto :mirror_select
echo.
echo [INFO] Each version installs into its own folder ^(e.g. nodejs24.20.0^).
echo.

:mirror_select
rem ---------- Auto-select the fastest mirror by speed test ----------
rem Entries: name|index.json URL|base URL (semicolon-separated)
set "MIRROR_LIST=npmmirror|https://npmmirror.com/mirrors/node/index.json|https://npmmirror.com/mirrors/node;huawei|https://mirrors.huaweicloud.com/nodejs/index.json|https://mirrors.huaweicloud.com/nodejs/;tencent|https://mirrors.cloud.tencent.com/nodejs-release/index.json|https://mirrors.cloud.tencent.com/nodejs-release/;ustc|https://mirrors.ustc.edu.cn/node/index.json|https://mirrors.ustc.edu.cn/node/;nodejs.org|https://nodejs.org/dist/index.json|https://nodejs.org/dist"
set "SPEED_OUT=%TEMP%\node-mirror-speed.txt"
del /f /q "!SPEED_OUT!" 2>nul
echo.
echo [INFO] Testing mirror speeds ...
powershell -NoProfile -Command "$list=$env:MIRROR_LIST -split ';';$best=$null;$bm=[int]::MaxValue;foreach($e in $list){$p=$e -split '\|';$n=$p[0];$i=$p[1];$b=$p[2];$sw=[Diagnostics.Stopwatch]::StartNew();try{Invoke-WebRequest -Uri $i -Method Head -TimeoutSec 5 -UseBasicParsing|Out-Null;$sw.Stop();$ms=$sw.ElapsedMilliseconds;if($ms -lt $bm){$bm=$ms;$best=$e}}catch{$sw.Stop()}};if($best){[IO.File]::WriteAllText($env:SPEED_OUT,$best)}"

rem --- Read the selected mirror ---
set "MIRROR_NAME="
set "INDEX_URL="
set "BASE_URL="
for /f "tokens=1,2,3 delims=|" %%a in ('type "!SPEED_OUT!" 2^>nul') do (
    set "MIRROR_NAME=%%a"
    set "INDEX_URL=%%b"
    set "BASE_URL=%%c"
)
if not defined MIRROR_NAME (
    echo [WARN] Speed test failed, fallback to npmmirror.
    set "MIRROR_NAME=npmmirror"
    set "INDEX_URL=https://npmmirror.com/mirrors/node/index.json"
    set "BASE_URL=https://npmmirror.com/mirrors/node"
)
echo [INFO] Selected mirror: !MIRROR_NAME!

rem --- Auto-detect latest LTS (default when pressing Enter) ---
set "AUTO_LTS=!FALLBACK_LTS!"
echo.
echo [INFO] Querying versions from !MIRROR_NAME! ...
for /f "delims=" %%v in ('powershell -NoProfile -Command "$j=Invoke-RestMethod '!INDEX_URL!' -TimeoutSec 15;($j.Where({$_.lts}))[0].version"') do (
    set "AUTO_LTS=%%v"
)
rem Strip leading "v" if present
if "!AUTO_LTS:~0,1!"=="v" set "AUTO_LTS=!AUTO_LTS:~1!"
if not defined AUTO_LTS set "AUTO_LTS=!FALLBACK_LTS!"

rem --- Fetch version list (latest version per major) ---
set "VER_LIST=%TEMP%\node-ver-list.txt"
del /f /q "!VER_LIST!" 2>nul
powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "$j=Invoke-RestMethod '!INDEX_URL!' -TimeoutSec 15;" ^
    "$seen=@{}; $lines=@();" ^
    "foreach($e in $j){ $v=$e.version; if($v -like 'v*'){$v=$v.Substring(1)}; $m=($v -split '\.')[0]; if($seen.ContainsKey($m)){continue}; $seen[$m]=$true; $lts=$e.lts; if($lts){$lines+=($v+'|LTS '+$lts)}else{$lines+=($v+'|-')} };" ^
    "[System.IO.File]::WriteAllLines('!VER_LIST!', [string[]]$lines)"

rem --- Version selection (latest per major) ---
:list_versions
if not exist "!VER_LIST!" (
    echo [ERROR] Could not fetch version list. Using latest LTS instead.
    set "NODE_VERSION=!AUTO_LTS!"
    goto :version_selected
)
set /a vcount=0
echo.
echo Latest version per major ^(newest first^):
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    set /a vcount+=1
    if "%%b"=="-" (
        echo   [!vcount!]  v%%a  ^(Current^)
    ) else (
        echo   [!vcount!]  v%%a  %%b
    )
)
if "!vcount!"=="0" (
    echo [ERROR] Version list is empty. Using latest LTS instead.
    set "NODE_VERSION=!AUTO_LTS!"
    goto :version_selected
)
echo.
set /p vpick=Select number or version ^(Enter = latest LTS, 0 = exit^):
if not defined vpick set "vpick="
if "!vpick!"=="" (
    echo [INFO] Using latest LTS v!AUTO_LTS!
    set "NODE_VERSION=!AUTO_LTS!"
    goto :version_selected
)
if "!vpick!"=="0" (
    echo [INFO] Exit.
    exit /b 0
)
rem Try as exact version first (e.g. 24.20.0 or v24.20.0)
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    if /i "%%a"=="!vpick!" (
        set "NODE_VERSION=%%a"
        goto :version_selected
    )
    if /i "v%%a"=="!vpick!" (
        set "NODE_VERSION=%%a"
        goto :version_selected
    )
)
rem Otherwise treat as row number
set /a vidx=0
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    set /a vidx+=1
    if "!vidx!"=="!vpick!" (
        set "NODE_VERSION=%%a"
        goto :version_selected
    )
)
echo [ERROR] Invalid selection. Using latest LTS instead.
set "NODE_VERSION=!AUTO_LTS!"

:version_selected
rem --- Architecture selection ---
echo.
echo Select architecture:
echo [1] x64 (default)
echo [2] arm64
echo.
set /p archChoice=Select:
if "!archChoice!"=="2" set "ARCH=arm64"

rem --- Install path (default: base\nodejs<version>) ---
set "DEFAULT_DIR=!INSTALL_ROOT!\nodejs!NODE_VERSION!"
echo.
echo Default install path: !DEFAULT_DIR!
echo ^(Tip: type a base dir, \nodejs<version> is appended automatically^)
set /p userRoot=Enter install path (Enter = default):
if "!userRoot!"=="" (
    set "INSTALL_ROOT=!DEFAULT_DIR!"
    goto :path_ok
)
set "INSTALL_ROOT=!userRoot!"
if "!INSTALL_ROOT:~-1!"=="\" set "INSTALL_ROOT=!INSTALL_ROOT:~0,-1!"
rem Auto-append \nodejs<version> unless the path already has a "nodejs" segment
echo !INSTALL_ROOT! | findstr /i /r /c:"\\nodejs" >nul
if errorlevel 1 set "INSTALL_ROOT=!INSTALL_ROOT!\nodejs!NODE_VERSION!"
:path_ok
if "!INSTALL_ROOT:~-1!"=="\" set "INSTALL_ROOT=!INSTALL_ROOT:~0,-1!"

rem --- Final confirmation before download ---
echo.
echo ========================================
echo   Confirm install:
echo     Version:  v!NODE_VERSION!  ^(!ARCH!^)
echo     Mirror:   !MIRROR_NAME!
echo     Path:     !INSTALL_ROOT!
echo ========================================
echo.
set /p confirm=Start download and install? [Y/N]:
if /i not "!confirm!"=="Y" (
    echo [INFO] Aborted by user.
    exit /b 0
)

rem --- Build download URL and start install ---
set "ZIP_NAME=node-v!NODE_VERSION!-win-!ARCH!.zip"
set "ZIP_URL=!BASE_URL!/v!NODE_VERSION!/!ZIP_NAME!"
set "ZIP_PATH=%TEMP%\!ZIP_NAME!"
set "TMP_EXTRACT=%TEMP%\node-extract-!NODE_VERSION!"

if exist "!TMP_EXTRACT!" rd /s /q "!TMP_EXTRACT!" 2>nul

echo.
echo [INFO] Installing Node.js v!NODE_VERSION! (!ARCH!)
echo [INFO] Mirror: !MIRROR_NAME!
echo [INFO] Path:   !INSTALL_ROOT!
echo [INFO] Downloading !ZIP_NAME! ...
echo.

powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Invoke-WebRequest -Uri '!ZIP_URL!' -OutFile '!ZIP_PATH!' -UseBasicParsing"

if not exist "!ZIP_PATH!" (
    echo [ERROR] Download failed: !ZIP_URL!
    echo [TIP]   Check network / mirror availability, or pick a version from the list.
    pause
    exit /b 1
)

echo [INFO] Extracting...
if not exist "!TMP_EXTRACT!" mkdir "!TMP_EXTRACT!"
powershell -NoProfile -Command "Expand-Archive -Path '!ZIP_PATH!' -DestinationPath '!TMP_EXTRACT!' -Force"

set "EXTRACTED="
for /d %%d in ("!TMP_EXTRACT!\node-v*") do set "EXTRACTED=%%d"
if not defined EXTRACTED (
    echo [ERROR] Extracted folder not found.
    pause
    exit /b 1
)

if exist "!INSTALL_ROOT!\node.exe" (
    echo [INFO] Removing old installation...
    rd /s /q "!INSTALL_ROOT!" 2>nul
)
if not exist "!INSTALL_ROOT!" mkdir "!INSTALL_ROOT!"
xcopy "!EXTRACTED!\*" "!INSTALL_ROOT!\" /E /Y /Q >nul 2>&1

if not exist "!INSTALL_ROOT!\node.exe" (
    echo [ERROR] node.exe not found after extract.
    pause
    exit /b 1
)

rem --- Cleanup temp files ---
rd /s /q "!TMP_EXTRACT!" 2>nul
del /f /q "!ZIP_PATH!" 2>nul

echo.
echo [INFO] Verification:
"!INSTALL_ROOT!\node.exe" --version
call "!INSTALL_ROOT!\npm.cmd" --version 2>nul

rem --- Optional: add to USER PATH (no admin) ---
echo.
set /p addPath=Add to user PATH? [Y/N]:
if /i "!addPath!"=="Y" (
    set "USERPATH="
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%b"
    echo !USERPATH! | findstr /i /c:"!INSTALL_ROOT!" >nul && (
        echo [INFO] Already in user PATH.
    ) || (
        if defined USERPATH (
            powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path','!INSTALL_ROOT!;!USERPATH!','User')"
        ) else (
            powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path','!INSTALL_ROOT!','User')"
        )
        echo [INFO] Added to user PATH.
    )
    echo [TIP] Close and reopen the terminal, or run: set PATH=!INSTALL_ROOT!;%%PATH%%
)

rem --- Generate uninstall helper ---
call :write_uninstall

echo.
echo ========================================
echo [SUCCESS] Node.js v!NODE_VERSION! installed!
echo ========================================
echo.
echo   Install dir: !INSTALL_ROOT!
echo   node.exe:    !INSTALL_ROOT!\node.exe
echo   npm global:  %%APPDATA%%\npm  (user-level, no admin)
echo   Uninstall:   !INSTALL_ROOT!\uninstall.bat
echo.
echo [TIP] Configure npm registry mirror:
echo   "%~dp0npm-config-mirror.bat"
echo.
pause
exit /b 0

:write_uninstall
set "UNINSTALL=!INSTALL_ROOT!\uninstall.bat"
set "UN_ROOT=!INSTALL_ROOT!"
(
    echo @echo off
    echo rem Remove portable Node.js and clean user PATH
    echo chcp 65001 ^>nul
    echo echo Removing portable Node.js at !UN_ROOT! ...
    echo rd /s /q "!UN_ROOT!"
    echo powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','User');$p=$p.Replace('!UN_ROOT!;','').Replace(';!UN_ROOT!','');[Environment]::SetEnvironmentVariable('Path',$p,'User')"
    echo echo Done. Close and reopen your terminal.
    echo pause
) > "!UNINSTALL!"
exit /b 0

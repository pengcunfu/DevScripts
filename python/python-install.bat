@echo off
rem ============================================================================
rem Python Silent Installer (exe, per-user)
rem ----------------------------------------------------------------------------
rem Download and install Python — no admin, no winget, no pyenv.
rem
rem Features:
rem   - Silent per-user install via the official .exe installer
rem     (includes pip / tkinter / venv, no admin required)
rem   - Auto-select the fastest mirror among huaweicloud / python.org
rem   - Lists ALL downloadable versions from the mirror to pick. Only versions
rem     whose installer file really exists on the mirror are shown.
rem     Falls back to the hard-coded version below when offline
rem   - Optional: add install dir to USER PATH (no admin, via registry/PowerShell)
rem   - Generates uninstall.bat helper
rem
rem Usage: Double-click to run. Edit defaults below if needed.
rem ============================================================================
setlocal enabledelayedexpansion
chcp 65001 >nul
title Python Silent Installer

rem ---------- User defaults (edit before running) ----------
rem Install base dir: each version installs to !BASE!\python<version> (no trailing backslash)
set "DEFAULT_INSTALL_ROOT=D:\Env"
rem Architecture: 1 = amd64/x64 (default), 2 = arm64
set "DEFAULT_ARCH=1"
rem Fallback version used only when auto-detection fails (must be a real release)
set "FALLBACK_VERSION=3.13.15"
rem ---------------------------------------------------------

set "INSTALL_ROOT=%DEFAULT_INSTALL_ROOT%"
set "ARCH=amd64"

echo ========================================
echo   Python Silent Installer (exe)
echo ========================================
echo.
echo [INFO] Silent per-user install - no admin, no winget, no pyenv.
echo.

rem --- Architecture selection ---
echo.
echo Select architecture:
echo   [1] amd64 / x64 (default)
echo   [2] arm64
echo.
set /p archChoice=Select:
if "!archChoice!"=="2" set "ARCH=arm64"

rem --- List existing Python installs under the base dir (informational only) ---
set "FOUND_ANY="
for /d %%d in ("!INSTALL_ROOT!\python*") do (
    if exist "%%d\python.exe" (
        set "FOUND_ANY=1"
        echo [INFO] Found: %%d
        for /f "delims=" %%v in ('"%%d\python.exe" --version 2^>nul') do echo   version: %%v
    )
)
if not defined FOUND_ANY goto :mirror_select
echo.
echo [INFO] Each version installs into its own folder ^(e.g. python3.13.15^).
echo.

:mirror_select
rem ---------- Auto-select the fastest mirror by speed test ----------
rem Entries: name|base URL (index page = same base for listing and files)
set "MIRROR_LIST=huaweicloud|https://mirrors.huaweicloud.com/python;python.org|https://www.python.org/ftp/python"
set "SPEED_OUT=%TEMP%\python-mirror-speed.txt"
del /f /q "!SPEED_OUT!" 2>nul
echo.
echo [INFO] Testing mirror speeds ...
powershell -NoProfile -Command "$list=$env:MIRROR_LIST -split ';';$best=$null;$bm=[int]::MaxValue;foreach($e in $list){$p=$e -split '\|';$n=$p[0];$i=$p[1];$sw=[Diagnostics.Stopwatch]::StartNew();try{Invoke-WebRequest -Uri $i -Method Head -TimeoutSec 5 -UseBasicParsing|Out-Null;$sw.Stop();$ms=$sw.ElapsedMilliseconds;if($ms -lt $bm){$bm=$ms;$best=$e}}catch{$sw.Stop()}};if($best){[IO.File]::WriteAllText($env:SPEED_OUT,$best)}"

rem --- Read the selected mirror ---
set "MIRROR_NAME="
set "INDEX_URL="
set "BASE_URL="
for /f "tokens=1,2 delims=|" %%a in ('type "!SPEED_OUT!" 2^>nul') do (
    set "MIRROR_NAME=%%a"
    set "BASE_URL=%%b"
)
if not defined MIRROR_NAME (
    echo [WARN] Speed test failed, fallback to python.org.
    set "MIRROR_NAME=python.org"
    set "BASE_URL=https://www.python.org/ftp/python"
)
set "INDEX_URL=!BASE_URL!"
echo [INFO] Selected mirror: !MIRROR_NAME!

rem --- Fetch version list (newest per minor that actually has binaries) ---
set "VER_LIST=%TEMP%\python-ver-list.txt"
call :fetch_versions

rem --- Coverage check: fall back to python.org if the mirror is incomplete ---
set /a vcount=0
for /f "delims=" %%a in ('type "!VER_LIST!" 2^>nul') do set /a vcount+=1
if !vcount! GEQ 3 goto :coverage_ok
if /i "!MIRROR_NAME!"=="python.org" goto :coverage_ok
echo [WARN] Mirror !MIRROR_NAME! has only !vcount! installable version(s) - switching to python.org.
set "MIRROR_NAME=python.org"
set "BASE_URL=https://www.python.org/ftp/python"
set "INDEX_URL=!BASE_URL!"
call :fetch_versions
:coverage_ok

rem --- Auto-detect latest available (default when pressing Enter) ---
set "AUTO_LATEST="
for /f "tokens=1 delims=|" %%a in ('type "!VER_LIST!" 2^>nul') do (
    if not defined AUTO_LATEST set "AUTO_LATEST=%%a"
)
if not defined AUTO_LATEST set "AUTO_LATEST=!FALLBACK_VERSION!"

rem --- Version selection (latest per minor, newest first) ---
:list_versions
if not exist "!VER_LIST!" (
    echo [ERROR] Could not fetch version list. Using fallback instead.
    set "PY_VERSION=!AUTO_LATEST!"
    goto :version_selected
)
set /a vcount=0
echo.
echo Latest version per minor ^(newest first^):
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    set /a vcount+=1
    echo   [!vcount!]  v%%a
)
if "!vcount!"=="0" (
    echo [ERROR] Version list is empty. Using fallback instead.
    set "PY_VERSION=!AUTO_LATEST!"
    goto :version_selected
)
echo.
set /p vpick=Select number or version ^(Enter = latest, 0 = exit^):
if "!vpick!"=="" (
    echo [INFO] Using latest Python !AUTO_LATEST!
    set "PY_VERSION=!AUTO_LATEST!"
    goto :version_selected
)
if "!vpick!"=="0" (
    echo [INFO] Exit.
    exit /b 0
)
rem Try as exact version first (e.g. 3.13.15 or v3.13.15)
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    if /i "%%a"=="!vpick!" (
        set "PY_VERSION=%%a"
        goto :version_selected
    )
    if /i "v%%a"=="!vpick!" (
        set "PY_VERSION=%%a"
        goto :version_selected
    )
)
rem Otherwise treat as row number
set /a vidx=0
for /f "tokens=1,2 delims=|" %%a in ('type "!VER_LIST!"') do (
    set /a vidx+=1
    if "!vidx!"=="!vpick!" (
        set "PY_VERSION=%%a"
        goto :version_selected
    )
)
echo [ERROR] Invalid selection. Using latest instead.
set "PY_VERSION=!AUTO_LATEST!"

:version_selected
rem --- Install path (default: base\python<version>) ---
set "DEFAULT_DIR=!INSTALL_ROOT!\python!PY_VERSION!"
echo.
echo Default install path: !DEFAULT_DIR!
echo ^(Tip: type a base dir, \python^<version^> is appended automatically^)
set /p userRoot=Enter install path (Enter = default):
if "!userRoot!"=="" (
    set "INSTALL_ROOT=!DEFAULT_DIR!"
    goto :path_ok
)
set "INSTALL_ROOT=!userRoot!"
if "!INSTALL_ROOT:~-1!"=="\" set "INSTALL_ROOT=!INSTALL_ROOT:~0,-1!"
rem Auto-append \python<version> unless the path already has a "python" segment
echo !INSTALL_ROOT! | findstr /i /r /c:"\\python" >nul
if errorlevel 1 set "INSTALL_ROOT=!INSTALL_ROOT!\python!PY_VERSION!"
:path_ok
if "!INSTALL_ROOT:~-1!"=="\" set "INSTALL_ROOT=!INSTALL_ROOT:~0,-1!"

rem --- Final confirmation before download ---
set "FILE_NAME=python-!PY_VERSION!-!ARCH!.exe"
set "KIND_NAME=Full installer"
echo.
echo ========================================
echo   Confirm install:
echo     Version:  !PY_VERSION!  ^(!ARCH!^)
echo     Type:     !KIND_NAME!
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
set "FILE_URL=!BASE_URL!/!PY_VERSION!/!FILE_NAME!"
set "FILE_PATH=%TEMP%\!FILE_NAME!"

echo.
echo [INFO] Installing Python !PY_VERSION! (!ARCH!, !KIND_NAME!)
echo [INFO] Mirror: !MIRROR_NAME!
echo [INFO] Path:   !INSTALL_ROOT!
echo [INFO] Downloading !FILE_NAME! ...
echo.

powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "Invoke-WebRequest -Uri '!FILE_URL!' -OutFile '!FILE_PATH!' -UseBasicParsing"

if not exist "!FILE_PATH!" (
    echo [ERROR] Download failed: !FILE_URL!
    echo [TIP]   Check network / mirror availability, or pick another version.
    pause
    exit /b 1
)
rem Sanity check: a valid installer is much larger than 1MB
set "DL_SIZE="
for %%F in ("!FILE_PATH!") do set "DL_SIZE=%%~zF"
if not defined DL_SIZE set "DL_SIZE=0"
if !DL_SIZE! LSS 1048576 (
    echo [ERROR] Download looks incomplete ^(!DL_SIZE! bytes^): !FILE_URL!
    del /f /q "!FILE_PATH!" 2>nul
    pause
    exit /b 1
)

rem --- Clean any existing install at the target dir ---
if exist "!INSTALL_ROOT!\python.exe" (
    echo [INFO] Removing old installation...
    rd /s /q "!INSTALL_ROOT!" 2>nul
)
if not exist "!INSTALL_ROOT!" mkdir "!INSTALL_ROOT!"

rem ===================== Silent per-user installer =====================
echo [INFO] Running silent per-user installer ^(no admin needed^)...
echo [INFO] This may take a minute...
start /wait "" "!FILE_PATH!" /quiet InstallAllUsers=0 PrependPath=0 Include_launcher=0 Include_test=0 Include_doc=0 Include_tcltk=1 Include_symbols=0 Shortcuts=0 TargetDir="!INSTALL_ROOT!"

rem The bootstrapper may fork a child; poll until python.exe appears (max ~2 min)
set /a wait_cnt=0
:wait_install
if exist "!INSTALL_ROOT!\python.exe" goto install_done
ping -n 3 127.0.0.1 >nul
set /a wait_cnt+=1
if !wait_cnt! LSS 60 goto wait_install
:install_done
if not exist "!INSTALL_ROOT!\python.exe" (
    echo [ERROR] python.exe not found after install. Check installer errors.
    pause
    exit /b 1
)
:install_finished

rem --- Cleanup temp files ---
del /f /q "!FILE_PATH!" 2>nul

echo.
echo [INFO] Verification:
"!INSTALL_ROOT!\python.exe" --version
"!INSTALL_ROOT!\python.exe" -m pip --version 2>nul
if errorlevel 1 echo [WARN] pip not available. Run pip-config-mirror.bat and then: python -m pip install --upgrade pip

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
            powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path','!INSTALL_ROOT!;!INSTALL_ROOT!\Scripts;!USERPATH!','User')"
        ) else (
            powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path','!INSTALL_ROOT!;!INSTALL_ROOT!\Scripts','User')"
        )
        echo [INFO] Added to user PATH.
    )
    echo [TIP] Close and reopen the terminal, or run: set PATH=!INSTALL_ROOT!;!INSTALL_ROOT!\Scripts;%%PATH%%
)

rem --- Generate uninstall helper ---
call :write_uninstall

echo.
echo ========================================
echo [SUCCESS] Python !PY_VERSION! installed!
echo ========================================
echo.
echo   Install dir: !INSTALL_ROOT!
echo   python.exe:  !INSTALL_ROOT!\python.exe
echo   pip:         !INSTALL_ROOT!\Scripts\pip.exe  (user-level, no admin)
echo   Uninstall:   !INSTALL_ROOT!\uninstall.bat
echo.
echo [TIP] Configure pip mirror:
echo   "%~dp0pip-config-mirror.bat"
echo [TIP] Multi-version switching:
echo   "%~dp0python-version-switcher.cmd"
echo.
pause
exit /b 0

:fetch_versions
rem Build the version list for the currently selected mirror/arch.
rem Only versions whose installer file really exists on the mirror are listed.
del /f /q "!VER_LIST!" 2>nul
echo.
echo [INFO] Querying versions from !MIRROR_NAME! ...
powershell -NoProfile -Command ^
    "$ProgressPreference='SilentlyContinue';" ^
    "$raw=Invoke-WebRequest -Uri '!INDEX_URL!' -TimeoutSec 20 -UseBasicParsing;" ^
    "$t=$raw.Content.TrimStart();" ^
    "if($t.StartsWith('[')){ $j=$raw.Content|ConvertFrom-Json; $names=@($j|Where-Object{$_.type -eq 'dir'}|ForEach-Object{$_.name.TrimEnd('/')}) } else { $names=@([regex]::Matches($raw.Content,'\d+\.\d+\.\d+(?=/)')|ForEach-Object{$_.Value}) };" ^
    "$names=$names|Where-Object{$_ -match '^\d+\.\d+\.\d+$'}|Select-Object -Unique;" ^
    "$sorted=$names|Sort-Object {[int]($_ -split '\.')[0]},{[int]($_ -split '\.')[1]},{[int]($_ -split '\.')[2]};" ^
    "$groups=@($sorted|Group-Object {($_ -split '\.')[0]+'.'+($_ -split '\.')[1]});" ^
    "$glist=$groups|Sort-Object {[int](([string]$_.Name) -split '\.')[0]},{[int](([string]$_.Name) -split '\.')[1]} -Descending;" ^
    "$lines=@();" ^
    "foreach($g in $glist){ $vs=@($g.Group)|Sort-Object {[int]($_ -split '\.')[2]} -Descending; foreach($v in $vs){ $fn='python-'+$v+'-'+'!ARCH!'+'.exe'; $u='!BASE_URL!/'+$v+'/'+$fn; try{ $r=Invoke-WebRequest -Method Head -Uri $u -TimeoutSec 8 -UseBasicParsing; if($r.StatusCode -eq 200){ $lines+=($v+'|-'); break } }catch{} } };" ^
    "[System.IO.File]::WriteAllLines('!VER_LIST!',[string[]]$lines)"
exit /b 0

:write_uninstall
set "UNINSTALL=!INSTALL_ROOT!\uninstall.bat"
set "UN_ROOT=!INSTALL_ROOT!"
(
    echo @echo off
    echo rem Remove Python and clean user PATH
    echo chcp 65001 ^>nul
    echo echo Removing Python at !UN_ROOT! ...
    echo rd /s /q "!UN_ROOT!"
    echo powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','User');$p=$p.Replace('!UN_ROOT!;','').Replace(';!UN_ROOT!','').Replace('!UN_ROOT!\Scripts;','').Replace(';!UN_ROOT!\Scripts','');[Environment]::SetEnvironmentVariable('Path',$p,'User')"
    echo echo Done. Close and reopen your terminal.
    echo pause
) > "!UNINSTALL!"
exit /b 0

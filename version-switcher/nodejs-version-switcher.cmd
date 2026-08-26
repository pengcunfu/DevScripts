@echo off
rem ============================================================================
rem Node.js Version Switcher (symlink-based)
rem ----------------------------------------------------------------------------
rem Uses a directory symlink as the stable Node.js path; switching just retargets.
rem
rem Usage:
rem   1. Edit the config section below to add/remove Node.js versions
rem   2. Double-click -> pick version -> done
rem   Requires admin (auto-elevates for mklink /D).
rem ============================================================================

rem --- Auto-elevate to admin ---
reg query "HKU\S-1-5-19" >nul 2>&1 || (
    powershell -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

chcp 65001 >nul
setlocal enabledelayedexpansion
title Node.js Version Switcher

rem ======================== EDIT BELOW ========================
rem
rem   Add/remove versions by following the pattern:
rem     set "VER[N]=<label>"    & set "DIR[N]=<full path>"
rem
rem   The label is what appears in the menu (e.g. "18", "20", "22").
rem   The directory must contain node.exe.
rem   Then set VER_COUNT to the total number of entries.
rem
rem   SYMLINK is the stable path added to PATH.
rem   It gets recreated as a junction each time you switch.
rem
set "SYMLINK=D:\Tools\Code\Env\nodejs"

set "VER[1]=18"    & set "DIR[1]=D:\Tools\Code\Env\nodejs-18"
set "VER[2]=20"    & set "DIR[2]=D:\Tools\Code\Env\nodejs-20"
set "VER[3]=22"    & set "DIR[3]=D:\Tools\Code\Env\nodejs-22"
set "VER_COUNT=3"

rem ======================== EDIT ABOVE ========================

:menu
cls
echo.
echo   Node.js Version Switcher
echo   ========================
echo.

rem --- Detect active version ---
set "ACTIVE=none"
if exist "!SYMLINK!\node.exe" (
    for /f %%v in ('"!SYMLINK!\node.exe" --version 2^>^&1') do (
        if not defined _VER_DONE (
            set "_VER_DONE=1"
            set "ACTIVE=Node.js %%v"
        )
    )
    set "_VER_DONE="
)
echo   Active: !ACTIVE!
echo.

rem --- Build menu dynamically ---
for /l %%i in (1,1,!VER_COUNT!) do (
    echo   [%%i] Node.js !VER[%%i]!   !DIR[%%i]!
)
echo.
echo   [0] Exit
echo.
set /p "CHOICE=  Select: "

if "!CHOICE!"=="0" goto :done

rem --- Validate and switch ---
if !CHOICE! geq 1 if !CHOICE! leq !VER_COUNT! (
    call :switch "!DIR[%CHOICE%]!" "!VER[%CHOICE%]!"
)
goto menu

:switch
set "TARGET=%~1"
set "VER=%~2"
echo.
echo   Switching to Node.js !VER! ...
echo.

rem --- Check node.exe exists ---
if not exist "!TARGET!\node.exe" (
    echo   [ERROR] node.exe not found: !TARGET!\node.exe
    pause
    goto :eof
)

rem --- Create symlink ---
if exist "!SYMLINK!" rmdir "!SYMLINK!" 2>nul
mklink /J "!SYMLINK!" "!TARGET!" >nul 2>&1
if not exist "!SYMLINK!" (
    echo   [ERROR] Failed to create symlink.
    pause
    goto :eof
)

rem --- Add symlink to PATH permanently (idempotent) ---
set "USERPATH="
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%b"
set "NEED_ADD=1"
if defined USERPATH (
    echo !USERPATH! | findstr /i /c:"!SYMLINK!" >nul && set "NEED_ADD=0"
)
if "!NEED_ADD!"=="1" (
    if defined USERPATH (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SYMLINK!;!USERPATH!" /f >nul
    ) else (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!SYMLINK!" /f >nul
    )
)

rem --- Update current session ---
set "PATH=!SYMLINK!;!PATH!"

rem --- Show result ---
echo   [OK] Switched to Node.js !VER!
echo   Symlink = !SYMLINK!
echo.
"!SYMLINK!\node.exe" --version 2>&1
echo.
pause
goto :eof

:done
endlocal
exit /b

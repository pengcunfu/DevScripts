@echo off
rem ============================================================================
rem PHP Version Switcher (symlink-based)
rem ----------------------------------------------------------------------------
rem Uses a directory symlink as the stable PHP path; switching just retargets it.
rem
rem Usage:
rem   1. Edit the config section below to add/remove PHP versions
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
title PHP Version Switcher

rem ======================== EDIT BELOW ========================
rem
rem   Add/remove versions by following the pattern:
rem     set "VER[N]=<label>"    & set "DIR[N]=<full path>"
rem
rem   The label is what appears in the menu (e.g. "7.4", "8.3").
rem   The directory must contain php.exe.
rem   Then set VER_COUNT to the total number of entries.
rem
rem   SYMLINK is the stable path added to PATH.
rem   It gets recreated as a junction each time you switch.
rem
set "SYMLINK=D:\Tools\Code\Env\php"

set "VER[1]=7.4"   & set "DIR[1]=D:\Tools\Code\Env\php-7.4"
set "VER[2]=8.0"   & set "DIR[2]=D:\Tools\Code\Env\php-8.0"
set "VER[3]=8.1"   & set "DIR[3]=D:\Tools\Code\Env\php-8.1"
set "VER[4]=8.2"   & set "DIR[4]=D:\Tools\Code\Env\php-8.2"
set "VER[5]=8.3"   & set "DIR[5]=D:\Tools\Code\Env\php-8.3"
set "VER_COUNT=5"

rem ======================== EDIT ABOVE ========================

:menu
cls
echo.
echo   PHP Version Switcher
echo   ====================
echo.

rem --- Detect active version ---
set "ACTIVE=none"
if exist "!SYMLINK!\php.exe" (
    for /f "tokens=2" %%v in ('"!SYMLINK!\php.exe" -v 2^>^&1') do (
        if not defined _VER_DONE (
            set "_VER_DONE=1"
            set "ACTIVE=PHP %%v"
        )
    )
    set "_VER_DONE="
)
echo   Active: !ACTIVE!
echo.

rem --- Build menu dynamically ---
for /l %%i in (1,1,!VER_COUNT!) do (
    echo   [%%i] PHP !VER[%%i]!   !DIR[%%i]!
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
echo   Switching to PHP !VER! ...
echo.

rem --- Check php.exe exists ---
if not exist "!TARGET!\php.exe" (
    echo   [ERROR] php.exe not found: !TARGET!\php.exe
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
echo   [OK] Switched to PHP !VER!
echo   Symlink = !SYMLINK!
echo.
"!SYMLINK!\php.exe" -v 2>&1
echo.
pause
goto :eof

:done
endlocal
exit /b

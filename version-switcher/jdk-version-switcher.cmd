@echo off
rem ============================================================================
rem JDK Version Switcher (symlink-based)
rem ----------------------------------------------------------------------------
rem Uses a directory symlink as JAVA_HOME; switching just retargets the symlink.
rem
rem Usage:
rem   1. Edit the config section below to add/remove JDK versions
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
title JDK Version Switcher

rem ======================== EDIT BELOW ========================
rem
rem   Add/remove versions by following the pattern:
rem     set "VER[N]=<label>"    & set "DIR[N]=<full path>"
rem
rem   The label is what appears in the menu (e.g. "8", "11", "17", "21-ea").
rem   The directory must contain bin\java.exe.
rem   Then set VER_COUNT to the total number of entries.
rem
rem   SYMLINK is the stable path that JAVA_HOME and PATH point to.
rem   It gets recreated as a junction each time you switch.
rem
set "SYMLINK=D:\Tools\Code\Env\jdk"

set "VER[1]=8"    & set "DIR[1]=D:\Tools\Code\Env\jdk-8"
set "VER[2]=11"   & set "DIR[2]=D:\Tools\Code\Env\jdk-11"
set "VER[3]=17"   & set "DIR[3]=D:\Tools\Code\Env\jdk-17"
set "VER_COUNT=3"

rem ======================== EDIT ABOVE ========================

:menu
cls
echo.
echo   JDK Version Switcher
echo   ====================
echo.

rem --- Detect active version ---
set "ACTIVE=none"
if exist "!SYMLINK!\bin\java.exe" (
    for /f "tokens=3" %%v in ('"!SYMLINK!\bin\java.exe" -version 2^>^&1') do (
        if not defined _VER_DONE (
            set "_VER_DONE=1"
            set "_RAW=%%v"
            set "_RAW=!_RAW:"=!"
            if "!_RAW:~0,2!"=="1." (set "ACTIVE=JDK 8") else (set "ACTIVE=JDK !_RAW:~0,2!")
        )
    )
    set "_VER_DONE="
)
echo   Active: !ACTIVE!
echo.

rem --- Build menu dynamically ---
for /l %%i in (1,1,!VER_COUNT!) do (
    echo   [%%i] JDK !VER[%%i]!   !DIR[%%i]!
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
echo   Switching to JDK !VER! ...
echo.

rem --- Check java.exe exists ---
if not exist "!TARGET!\bin\java.exe" (
    echo   [ERROR] java.exe not found: !TARGET!\bin\java.exe
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

rem --- Set JAVA_HOME permanently ---
reg add "HKCU\Environment" /v JAVA_HOME /t REG_SZ /d "!SYMLINK!" /f >nul

rem --- Add to PATH permanently (only if not already present) ---
reg query "HKCU\Environment" /v Path 2>nul | findstr /i "JAVA_HOME" >nul || (
    set "USERPATH="
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USERPATH=%%b"
    if defined USERPATH (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%%JAVA_HOME%%\bin;!USERPATH!" /f >nul
    ) else (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%%JAVA_HOME%%\bin" /f >nul
    )
)

rem --- Update current session ---
set "JAVA_HOME=!SYMLINK!"
set "PATH=!SYMLINK!\bin;!PATH!"

rem --- Show result ---
echo   [OK] Switched to JDK !VER!
echo   JAVA_HOME = !SYMLINK!
echo.
"!SYMLINK!\bin\java.exe" -version 2>&1
echo.
pause
goto :eof

:done
endlocal
exit /b

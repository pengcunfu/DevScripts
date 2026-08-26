@echo off
rem ============================================================================
rem Universal Context Menu Manager
rem ----------------------------------------------------------------------------
rem Add or remove any program from the Windows right-click context menu.
rem
rem Supports:
rem   - Files only (right-click on any file)
rem   - Directories only (right-click on folder/drive/background)
rem   - Files and Directories (both)
rem
rem Usage: Run as Administrator (auto re-launches elevated).
rem ============================================================================

reg query "HKU\S-1-5-19" >nul 2>&1 || (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

chcp 65001 >nul
setlocal enabledelayedexpansion
title Context Menu Manager

:menu
cls
echo.
echo   Context Menu Manager
echo   ====================
echo.
echo   [1] Add to context menu
echo   [2] Remove from context menu
echo   [0] Exit
echo.
set /p "CHOICE=  Select: "

if "!CHOICE!"=="1" goto :add
if "!CHOICE!"=="2" goto :remove
if "!CHOICE!"=="0" goto :done
goto menu

rem ====================================================================
rem  ADD
rem ====================================================================
:add
cls
echo.
echo   Add to Context Menu
echo   ====================
echo.

rem --- Get exe path ---
set "EXE_PATH="
set /p "EXE_PATH=  Program path (e.g. D:\Tools\Code.exe): "
if not defined EXE_PATH goto menu

rem --- Validate exe exists ---
if not exist "!EXE_PATH!" (
    echo.
    echo   [ERROR] File not found: !EXE_PATH!
    pause
    goto menu
)

rem --- Extract exe name for registry key (remove spaces and special chars) ---
for %%f in ("!EXE_PATH!") do set "EXE_NAME=%%~nxf"

rem --- Get display name ---
set "MENU_NAME="
set /p "MENU_NAME=  Menu display name (e.g. Open with Code): "
if not defined MENU_NAME set "MENU_NAME=Open with !EXE_NAME!"

rem --- Get scope ---
echo.
echo   Scope:
echo   [1] Files only
echo   [2] Directories only
echo   [3] Files and Directories
echo.
set /p "SCOPE=  Select: "

if "!SCOPE!"=="1" (call :add_files) & goto :add_done
if "!SCOPE!"=="2" (call :add_dirs)  & goto :add_done
if "!SCOPE!"=="3" (call :add_files & call :add_dirs) & goto :add_done
goto menu

:add_files
rem --- File context menu (* means all file types) ---
reg add "HKCR\*\shell\!EXE_NAME!" /ve /t REG_SZ /d "!MENU_NAME!" /f >nul
reg add "HKCR\*\shell\!EXE_NAME!" /v "Icon" /t REG_SZ /d "\"!EXE_PATH!\"" /f >nul
reg add "HKCR\*\shell\!EXE_NAME!\command" /ve /t REG_SZ /d "\"!EXE_PATH!\" \"%%1\"" /f >nul
goto :eof

:add_dirs
rem --- Directory context menu (folder right-click) ---
reg add "HKCR\Directory\shell\!EXE_NAME!" /ve /t REG_SZ /d "!MENU_NAME!" /f >nul
reg add "HKCR\Directory\shell\!EXE_NAME!" /v "Icon" /t REG_SZ /d "\"!EXE_PATH!\"" /f >nul
reg add "HKCR\Directory\shell\!EXE_NAME!\command" /ve /t REG_SZ /d "\"!EXE_PATH!\" \"%%V\"" /f >nul

rem --- Directory background context menu (right-click empty area) ---
reg add "HKCR\Directory\Background\shell\!EXE_NAME!" /ve /t REG_SZ /d "!MENU_NAME!" /f >nul
reg add "HKCR\Directory\Background\shell\!EXE_NAME!" /v "Icon" /t REG_SZ /d "\"!EXE_PATH!\"" /f >nul
reg add "HKCR\Directory\Background\shell\!EXE_NAME!\command" /ve /t REG_SZ /d "\"!EXE_PATH!\" \"%%V\"" /f >nul

rem --- Drive context menu (right-click on drive) ---
reg add "HKCR\Drive\shell\!EXE_NAME!" /ve /t REG_SZ /d "!MENU_NAME!" /f >nul
reg add "HKCR\Drive\shell\!EXE_NAME!" /v "Icon" /t REG_SZ /d "\"!EXE_PATH!\"" /f >nul
reg add "HKCR\Drive\shell\!EXE_NAME!\command" /ve /t REG_SZ /d "\"!EXE_PATH!\" \"%%V\"" /f >nul
goto :eof

:add_done
echo.
echo   [OK] Added: !MENU_NAME!
pause
goto menu

rem ====================================================================
rem  REMOVE
rem ====================================================================
:remove
cls
echo.
echo   Remove from Context Menu
echo   ========================
echo.

rem --- List existing entries ---
echo   Scanning registry...
echo.
set "IDX=0"
for /f "tokens=* delims=" %%k in ('reg query "HKCR\*\shell" /k 2^>nul ^| findstr /i "HKEY"') do (
    for %%n in ("%%k") do (
        set "KEY_NAME=%%~nxn"
        for /f "tokens=2*" %%a in ('reg query "%%k" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "DISP=%%b"
        set /a IDX+=1
        echo   [!IDX!] !KEY_NAME!  (!DISP!)
        set "RM_KEY[!IDX!]=%%k"
    )
)
for /f "tokens=* delims=" %%k in ('reg query "HKCR\Directory\shell" /k 2^>nul ^| findstr /i "HKEY"') do (
    for %%n in ("%%k") do (
        set "KEY_NAME=%%~nxn"
        for /f "tokens=2*" %%a in ('reg query "%%k" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "DISP=%%b"
        set /a IDX+=1
        echo   [!IDX!] !KEY_NAME!  (!DISP!)
        set "RM_KEY[!IDX!]=%%k"
    )
)

if !IDX!==0 (
    echo   No custom context menu entries found.
    pause
    goto menu
)

echo.
set /p "RM_CHOICE=  Select entry to remove (0 to cancel): "

if "!RM_CHOICE!"=="0" goto menu
if !RM_CHOICE! geq 1 if !RM_CHOICE! leq !IDX! (
    set "TARGET_KEY=!RM_KEY[%RM_CHOICE%]!"
    for %%n in ("!TARGET_KEY!") do set "KEY_NAME=%%~nxn"

    rem Delete file entry
    reg delete "HKCR\*\shell\!KEY_NAME!" /f >nul 2>&1
    rem Delete directory entry
    reg delete "HKCR\Directory\shell\!KEY_NAME!" /f >nul 2>&1
    reg delete "HKCR\Directory\Background\shell\!KEY_NAME!" /f >nul 2>&1
    reg delete "HKCR\Drive\shell\!KEY_NAME!" /f >nul 2>&1

    echo.
    echo   [OK] Removed: !KEY_NAME!
    pause
)
goto menu

:done
endlocal
exit /b

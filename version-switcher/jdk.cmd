@echo off
rem ============================================================================
rem JDK Version Switcher
rem ----------------------------------------------------------------------------
rem Configure JDK 8 / 11 / 17 install paths, then switch via user env vars.
rem
rem Features:
rem   - Per-version path config (saved to jdk.config beside this script)
rem   - Update user JAVA_HOME and PATH (no admin required)
rem   - Detect current Java version
rem
rem Usage: Double-click or run jdk.cmd. Configure paths on first use.
rem ============================================================================
chcp 65001 >nul
setlocal enabledelayedexpansion
title JDK Version Switcher

set "CONFIG=%~dp0jdk.config"

call :load_config
goto menu

:menu
cls
echo ===========================================
echo         JDK Version Switcher
echo ===========================================
echo.
call :show_current_java
echo.
echo Config: %CONFIG%
echo.
echo [1] Switch to JDK 8
echo [2] Switch to JDK 11
echo [3] Switch to JDK 17
echo [4] Configure JDK paths
echo [5] View configuration
echo [0] Exit
echo.
echo ===========================================
set /p choice=Select:

if "%choice%"=="1" call :switch_jdk 8
if "%choice%"=="2" call :switch_jdk 11
if "%choice%"=="3" call :switch_jdk 17
if "%choice%"=="4" call :configure
if "%choice%"=="5" call :view_config
if "%choice%"=="0" exit /b 0
goto menu

:load_config
set "JDK8="
set "JDK11="
set "JDK17="
if not exist "%CONFIG%" exit /b 0
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%CONFIG%") do (
    if /i "%%~a"=="JDK8" set "JDK8=%%~b"
    if /i "%%~a"=="JDK11" set "JDK11=%%~b"
    if /i "%%~a"=="JDK17" set "JDK17=%%~b"
)
exit /b 0

:save_config
(
    echo JDK8=%JDK8%
    echo JDK11=%JDK11%
    echo JDK17=%JDK17%
) > "%CONFIG%"
exit /b 0

:normalize_var
set "NP=!%~1!"
if not defined NP exit /b 0
if "!NP:~-1!"=="\" set "NP=!NP:~0,-1!"
set "%~1=!NP!"
exit /b 0

:get_jdk_path
set "TARGET_JDK="
if "%~1"=="8" set "TARGET_JDK=%JDK8%"
if "%~1"=="11" set "TARGET_JDK=%JDK11%"
if "%~1"=="17" set "TARGET_JDK=%JDK17%"
exit /b 0

:validate_jdk
set "CHECK_PATH=%~1"
if not defined CHECK_PATH (
    echo [ERROR] JDK path is not configured.
    exit /b 1
)
if not exist "%CHECK_PATH%\bin\java.exe" (
    echo [ERROR] java.exe not found: %CHECK_PATH%\bin\java.exe
    exit /b 1
)
exit /b 0

:get_user_path
set "USER_PATH="
for /f "skip=2 tokens=1,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
if not defined USER_PATH (
    for /f "skip=2 tokens=1,*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "USER_PATH=%%b"
)
exit /b 0

:strip_jdk_bins
set "CLEAN_PATH=!%~1!"
if not defined CLEAN_PATH exit /b 0
if defined JDK8 (
    call :normalize_var JDK8
    set "CLEAN_PATH=!CLEAN_PATH:%JDK8%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JDK8%\bin=!"
    set "CLEAN_PATH=!CLEAN_PATH:%JDK8%\bin=!"
)
if defined JDK11 (
    call :normalize_var JDK11
    set "CLEAN_PATH=!CLEAN_PATH:%JDK11%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JDK11%\bin=!"
    set "CLEAN_PATH=!CLEAN_PATH:%JDK11%\bin=!"
)
if defined JDK17 (
    call :normalize_var JDK17
    set "CLEAN_PATH=!CLEAN_PATH:%JDK17%\bin;=!"
    set "CLEAN_PATH=!CLEAN_PATH:;%JDK17%\bin=!"
    set "CLEAN_PATH=!CLEAN_PATH:%JDK17%\bin=!"
)
set "%~1=!CLEAN_PATH!"
exit /b 0

:apply_jdk
set "NEW_JAVA_HOME=%~1"
call :normalize_var NEW_JAVA_HOME
set "NEW_BIN=%NEW_JAVA_HOME%\bin"

call :get_user_path
set "NEW_PATH=%USER_PATH%"
call :strip_jdk_bins NEW_PATH

if defined NEW_PATH (
    set "NEW_PATH=%NEW_BIN%;%NEW_PATH%"
) else (
    set "NEW_PATH=%NEW_BIN%"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$javaHome='%NEW_JAVA_HOME:\=\\%'; $userPath='%NEW_PATH:\=\\%';" ^
  "[Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User');" ^
  "[Environment]::SetEnvironmentVariable('Path', $userPath, 'User')"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to update user environment variables.
    exit /b 1
)

set "JAVA_HOME=%NEW_JAVA_HOME%"
call :strip_jdk_bins PATH
set "PATH=%NEW_BIN%;!PATH!"

echo.
echo [SUCCESS] Switched to JDK !ACTIVE_VERSION!
echo   JAVA_HOME=%NEW_JAVA_HOME%
echo   PATH added: %NEW_BIN%
exit /b 0

:switch_jdk
set "ACTIVE_VERSION=%~1"
call :get_jdk_path %ACTIVE_VERSION%
if not defined TARGET_JDK (
    echo.
    echo [ERROR] JDK %ACTIVE_VERSION% path is not configured.
    echo Use menu option [4] to configure paths first.
    pause
    exit /b 1
)
call :validate_jdk "%TARGET_JDK%"
if %errorlevel% neq 0 (
    pause
    exit /b 1
)
call :apply_jdk "%TARGET_JDK%"
echo.
call :show_current_java
pause
exit /b 0

:configure
cls
echo ===========================================
echo         Configure JDK Paths
echo ===========================================
echo.
echo JDK root directory (folder containing bin\java.exe)
echo.
echo [1] JDK 8  : %JDK8%
echo [2] JDK 11 : %JDK11%
echo [3] JDK 17 : %JDK17%
echo [0] Back
echo.
set /p cfg=Select:

if "%cfg%"=="0" exit /b 0
if "%cfg%"=="1" set "CFG_KEY=JDK8" & set "CFG_LABEL=JDK 8"
if "%cfg%"=="2" set "CFG_KEY=JDK11" & set "CFG_LABEL=JDK 11"
if "%cfg%"=="3" set "CFG_KEY=JDK17" & set "CFG_LABEL=JDK 17"
if not defined CFG_KEY goto configure

echo.
echo Enter %CFG_LABEL% root path (leave empty to clear):
set /p CFG_VALUE=Path:

if defined CFG_VALUE call :validate_jdk "!CFG_VALUE!"
if defined CFG_VALUE if !errorlevel! neq 0 (
    pause
    goto configure
)

set "!CFG_KEY!=!CFG_VALUE!"
if defined CFG_VALUE call :normalize_var !CFG_KEY!
call :save_config
echo.
echo [SUCCESS] %CFG_LABEL% path saved.
pause
set "CFG_KEY="
set "CFG_LABEL="
goto configure

:view_config
cls
echo ===========================================
echo         JDK Configuration
echo ===========================================
echo.
echo JDK 8  : %JDK8%
echo JDK 11 : %JDK11%
echo JDK 17 : %JDK17%
echo.
for /f "skip=2 tokens=1,*" %%a in ('reg query "HKCU\Environment" /v JAVA_HOME 2^>nul') do echo User JAVA_HOME: %%b
echo.
call :show_current_java
echo.
pause
exit /b 0

:show_current_java
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo Current Java: not available in this session
    exit /b 0
)
for /f "tokens=* delims=" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do set "CURRENT_VERSION=%%i"
set "CURRENT_VERSION=!CURRENT_VERSION:*version=!"
echo Current Java:!CURRENT_VERSION!
if defined JAVA_HOME echo Session JAVA_HOME: %JAVA_HOME%
exit /b 0

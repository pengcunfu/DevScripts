@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Git Fix Cert

rem ============================================================================
rem Git CAfile Fix
rem ----------------------------------------------------------------------------
rem Fix git "CAfile verify locations error" by pointing global config at the
rem correct ca-bundle.crt. Uses global (user-level) config, no admin required.
rem
rem Locates ca-bundle.crt by walking up from git.exe until a directory
rem containing "mingw64\ssl\certs\ca-bundle.crt" is found, which works for
rem both standard and portable (git.exe under mingw64\bin) installs.
rem ============================================================================

echo ========================================
echo         Git CAfile Fix
echo ========================================
echo.

:: Locate git executable
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] git not found in PATH
    pause
    exit /b 1
)

for /f "delims=" %%i in ('where git') do (
    set "gitExe=%%i"
    goto :gitfound
)
:gitfound

:: Find git root by walking up until mingw64\ssl\certs\ca-bundle.crt is found
for %%i in ("%gitExe%") do set "gitBin=%%~dpi"
for %%i in ("%gitBin%..") do set "cur=%%~fi"

set "crtPath="
for /l %%n in (1,1,6) do (
    if exist "!cur!\mingw64\ssl\certs\ca-bundle.crt" (
        set "crtPath=!cur!\mingw64\ssl\certs\ca-bundle.crt"
        goto :certfound
    )
    for %%i in ("!cur!\..") do set "cur=%%~fi"
)
:certfound

if "%crtPath%"=="" (
    echo [ERROR] ca-bundle.crt not found. Check your Git installation.
    pause
    exit /b 1
)

:: Use forward slashes for git config
set "crtGitPath=%crtPath:\=/%"
echo [INFO] Found: %crtGitPath%
echo.

:: Write to global config (user level, no admin needed)
git config --global http.sslCAInfo "%crtGitPath%"

:: Verify result
for /f "delims=" %%v in ('git config --global --get http.sslCAInfo') do set "checkVal=%%v"
echo http.sslCAInfo (global): %checkVal%

if "%checkVal%"=="%crtGitPath%" (
    echo [SUCCESS] git ca certificate path updated.
) else (
    echo [WARNING] config change may not take effect.
)

pause

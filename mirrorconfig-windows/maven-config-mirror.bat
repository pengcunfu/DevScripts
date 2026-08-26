@echo off
rem ============================================================================
rem Maven Mirror Configuration Tool
rem ----------------------------------------------------------------------------
rem One-click China mirror setup via %%USERPROFILE%%\.m2\settings.xml
rem
rem Features:
rem   - Aliyun / Huawei / Tencent mirrors
rem   - Backup existing settings.xml to settings.xml.bak before change
rem   - Merge <mirrors> when possible; create file if missing
rem   - Restore backup or reset to official (no mirror)
rem
rem Usage: Double-click to run. Maven not required to update settings.
rem ============================================================================
setlocal
chcp 65001 >nul
title Maven Mirror Configuration

set "M2_DIR=%USERPROFILE%\.m2"
set "SETTINGS=%M2_DIR%\settings.xml"
set "BACKUP=%M2_DIR%\settings.xml.bak"

if not exist "%M2_DIR%" mkdir "%M2_DIR%"

:menu
cls
echo ===========================================
echo       Maven Mirror Configuration
echo ===========================================
echo.
echo Config file: %SETTINGS%
echo.
echo [1] Aliyun (recommended)
echo [2] Huawei Cloud
echo [3] Tencent Cloud
echo [4] Official (remove mirror override)
echo [5] View current mirrors
echo [6] Restore from settings.xml.bak
echo [0] Exit
echo.
echo ===========================================
set /p choice=Select:

if "%choice%"=="1" call :apply_mirror aliyunmaven "Aliyun Maven" https://maven.aliyun.com/repository/public
if "%choice%"=="2" call :apply_mirror huaweicloud "Huawei Maven" https://repo.huaweicloud.com/repository/maven/
if "%choice%"=="3" call :apply_mirror tencent "Tencent Maven" https://mirrors.cloud.tencent.com/nexus/repository/maven-public/
if "%choice%"=="4" call :apply_official
if "%choice%"=="5" call :view
if "%choice%"=="6" call :restore
if "%choice%"=="0" exit /b 0
goto menu

:apply_mirror
if exist "%SETTINGS%" copy /y "%SETTINGS%" "%BACKUP%" >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$id='%1'; $name='%2'; $url='%3'; $path='%SETTINGS:\=\\%';" ^
  "$mirror=@\"`n    <mirror>`n      <id>$id</id>`n      <mirrorOf>*</mirrorOf>`n      <name>$name</name>`n      <url>$url</url>`n    </mirror>`n\"@;" ^
  "if (-not (Test-Path $path)) {" ^
  "  @\"<?xml version=`\"1.0`\" encoding=`\"UTF-8`\"?>`n<settings xmlns=`\"http://maven.apache.org/SETTINGS/1.2.0`\"`n  xmlns:xsi=`\"http://www.w3.org/2001/XMLSchema-instance`\"`n  xsi:schemaLocation=`\"http://maven.apache.org/SETTINGS/1.2.0 https://maven.apache.org/xsd/settings-1.2.0.xsd`\">`n  <mirrors>`n$mirror  </mirrors>`n</settings>`n\"@ | Set-Content -Path $path -Encoding UTF8;" ^
  "  exit 0 }" ^
  "$c = Get-Content -Path $path -Raw -Encoding UTF8;" ^
  "if ($c -match '(?s)<mirrors>.*?</mirrors>') { $c = $c -replace '(?s)<mirrors>.*?</mirrors>', (`"<mirrors>`n$mirror  </mirrors>`"); }" ^
  "elseif ($c -match '</settings>') { $c = $c -replace '</settings>', (`"  <mirrors>`n$mirror  </mirrors>`n</settings>`"); }" ^
  "else { throw 'Unrecognized settings.xml format' }" ^
  "Set-Content -Path $path -Value $c -Encoding UTF8 -NoNewline"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to update settings.xml
    pause
    goto menu
)
echo.
echo [SUCCESS] Mirror configured: %3
echo [INFO] Backup: %BACKUP%
pause
goto menu

:apply_official
if exist "%SETTINGS%" copy /y "%SETTINGS%" "%BACKUP%" >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$path='%SETTINGS:\=\\%';" ^
  "if (-not (Test-Path $path)) { Write-Host 'No settings.xml'; exit 0 };" ^
  "$c = Get-Content -Path $path -Raw -Encoding UTF8;" ^
  "if ($c -match '(?s)<mirrors>.*?</mirrors>') { $c = $c -replace '(?s)\s*<mirrors>.*?</mirrors>\s*', \"`n\" };" ^
  "Set-Content -Path $path -Value $c -Encoding UTF8 -NoNewline"
echo.
echo [SUCCESS] Mirror override removed. Maven uses default Central repo.
echo [INFO] Backup: %BACKUP%
pause
goto menu

:view
echo.
if not exist "%SETTINGS%" (
    echo [INFO] settings.xml does not exist yet.
    pause
    goto menu
)
findstr /i /c:"<mirror" /c:"<url" /c:"<id" /c:"mirrorOf" "%SETTINGS%" 2>nul
if %errorlevel% neq 0 type "%SETTINGS%"
echo.
pause
goto menu

:restore
if not exist "%BACKUP%" (
    echo [ERROR] Backup not found: %BACKUP%
    pause
    goto menu
)
copy /y "%BACKUP%" "%SETTINGS%" >nul
echo [SUCCESS] Restored from settings.xml.bak
pause
goto menu

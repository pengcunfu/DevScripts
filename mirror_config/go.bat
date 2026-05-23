@echo off
rem ============================================================================
rem Go Mirror Configuration Tool
rem ----------------------------------------------------------------------------
rem One-click GOPROXY setup for China mirrors.
rem
rem Features:
rem   - goproxy.cn, Aliyun, Official proxy
rem   - Set GOSUMDB for China (optional on mirror [1][2])
rem   - View current Go env
rem
rem Usage: Double-click to run (requires Go installed).
rem ============================================================================
chcp 65001 >nul
title Go Mirror Configuration

where go >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Go is not installed or not in PATH.
    pause
    exit /b 1
)

:menu
cls
echo ===========================================
echo         Go Mirror Configuration
echo ===========================================
echo.
echo [1] goproxy.cn (recommended)
echo [2] Aliyun mirror
echo [3] Official (proxy.golang.org)
echo [4] View current GOPROXY / GOSUMDB
echo [0] Exit
echo.
echo ===========================================
set /p choice=Select:

if "%choice%"=="1" goto goproxy_cn
if "%choice%"=="2" goto aliyun
if "%choice%"=="3" goto official
if "%choice%"=="4" goto view
if "%choice%"=="0" exit /b 0
goto menu

:goproxy_cn
echo.
echo Configuring goproxy.cn...
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GOSUMDB=sum.golang.google.cn
goto done

:aliyun
echo.
echo Configuring Aliyun mirror...
go env -w GO111MODULE=on
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
go env -w GOSUMDB=sum.golang.google.cn
goto done

:official
echo.
echo Configuring official proxy...
go env -w GO111MODULE=on
go env -w GOPROXY=https://proxy.golang.org,direct
go env -w GOSUMDB=sum.golang.google.com
goto done

:view
echo.
echo GOPROXY:
go env GOPROXY
echo GOSUMDB:
go env GOSUMDB
echo GO111MODULE:
go env GO111MODULE
pause
goto menu

:done
echo.
echo Configuration completed.
echo.
echo GOPROXY:
go env GOPROXY
echo GOSUMDB:
go env GOSUMDB
pause
goto menu

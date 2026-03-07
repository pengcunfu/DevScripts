@echo off
chcp 65001 >nul
title PIP Mirror Configuration

echo ===========================================
echo Please select PIP mirror source:
echo [1] Douban
echo [2] Official
echo [3] Huawei
echo [4] Tsinghua
echo [5] Aliyun
echo ===========================================
set /p choice=Enter number 1-5:

if "%choice%"=="1" (
    echo Configuring Douban mirror...
    python -m pip config set global.index-url http://pypi.douban.com/simple/
    python -m pip config set install.trusted-host pypi.douban.com
    goto done
)

if "%choice%"=="2" (
    echo Configuring Official mirror...
    python -m pip config set global.index-url https://pypi.python.org/simple
    python -m pip config set install.trusted-host pypi.python.org
    goto done
)

if "%choice%"=="3" (
    echo Configuring Huawei mirror...
    python -m pip config set global.index-url https://repo.huaweicloud.com/repository/pypi/simple
    python -m pip config set global.trusted-host repo.huaweicloud.com
    python -m pip config set global.timeout 120
    goto done
)

if "%choice%"=="4" (
    echo Configuring Tsinghua mirror...
    python -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    python -m pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn
    goto done
)

if "%choice%"=="5" (
    echo Configuring Aliyun mirror...
    python -m pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
    python -m pip config set global.trusted-host mirrors.aliyun.com
    goto done
)

echo Invalid input, please run again
goto end

:done
echo Configuration completed
pause
:end

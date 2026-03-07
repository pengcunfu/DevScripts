@echo off
chcp 65001 >nul
rem 检测管理员权限
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem 设置用户自定义路径及 Node.js 路径
set "basePath=D:\Peng\App\DevApp\node"

rem 检测执行 node -v 命令
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 当前未安装 Node 程序
    echo.
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"
    echo 当前 Node 版本号：[!currentVersion!]
    echo.
)

rem 显示用户选择 Node.js 版本
echo 选择 Nodejs 版本
echo.
echo   选项1：版本[12.22.12]
echo.
echo   选项2：版本[16.20.2]
echo.
echo   选项3：版本[18.20.2]
echo.
echo   选项4：版本[20.18.2]
echo.
echo   选项5：版本[22.14.0]
echo.

set /p choice=请选择版本:
echo.

rem 根据用户选择的 Node.js 版本
if "%choice%" equ "1" set version=12.22.12
if "%choice%" equ "2" set version=16.20.2
if "%choice%" equ "3" set version=18.20.2
if "%choice%" equ "4" set version=20.18.2
if "%choice%" equ "5" set version=22.14.0

set "nodejs=!basePath!!version!"

rem 检测执行 node -v 命令
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行 node -v 失败，则添加路径到 PATH
    set "PATH=!PATH!;%nodejs%"

    rem 写入系统环境变量
    setx PATH "!PATH!" /M
    echo 已添加到 PATH: !nodejs!
    echo.
) else (
    rem 执行 node -v 成功，则比较版本号
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"

    if "!currentVersion!" equ "!version!" (
        echo Node.js 版本一致: !version!
        echo 版本相同，无需修改 PATH。
        echo.
    ) else (
        rem 版本不相同，删除旧版本，添加当前版本
        set "PATH=!PATH:%basePath%12.22.12=!"
        set "PATH=!PATH:%basePath%16.20.2=!"
        set "PATH=!PATH:%basePath%18.20.2=!"
        set "PATH=!PATH:%basePath%20.18.2=!"
        set "PATH=!PATH:%basePath%22.14.0=!"

        set "PATH=!PATH!;%nodejs%"

        echo 删除旧版本[!currentVersion!]，添加新版本[!version!]

        rem 写入系统环境变量
        setx PATH "!PATH!" /M
        echo 已添加到 PATH: [!nodejs!]
        echo.
    )
)

rem 显示当前 Node.js 版本
node -v > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 没有设置成功！
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('node -v') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:~1!"
    echo 当前版本：[!currentVersion!]
)

echo.
rem 暂停等待用户按键后退出
pause

endlocal

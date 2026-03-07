@echo off
chcp 65001 >nul
rem 检测管理员权限
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem 设置用户自定义路径及 PHP 路径
set "phpBasePath=D:\Peng\App\DevApp\php-"

rem 检测执行 php -v 命令
php -v > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 当前没有安装 PHP 程序
    echo.
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('php -v 2^>^&1 ^| findstr /i "PHP"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*PHP =!"
    set "currentVersion=!currentVersion:~0,5!"
    echo 当前 PHP 版本号：[!currentVersion!]
    echo.
)

rem 显示用户选择 PHP 版本
echo 选择 PHP 版本
echo.
echo   选项1：版本[7.4]
echo.
echo   选项2：版本[8.0]
echo.
echo   选项3：版本[8.1]
echo.
echo   选项4：版本[8.2]
echo.
echo   选项5：版本[8.3]
echo.

set /p choice=请选择版本:
echo.

rem 根据用户选择的 PHP 版本
if "%choice%" equ "1" set version=7.4
if "%choice%" equ "2" set version=8.0
if "%choice%" equ "3" set version=8.1
if "%choice%" equ "4" set version=8.2
if "%choice%" equ "5" set version=8.3

set "php=!phpBasePath!!version!"

rem 删除旧版本，添加新版本
set "PATH=!PATH:%phpBasePath%7.4=!"
set "PATH=!PATH:%phpBasePath%8.0=!"
set "PATH=!PATH:%phpBasePath%8.1=!"
set "PATH=!PATH:%phpBasePath%8.2=!"
set "PATH=!PATH:%phpBasePath%8.3=!"

set "PATH=!PATH!;!php!"

echo 切换到版本[!version!]

rem 写入系统环境变量
setx PATH "!PATH!" /M
echo 已添加到 PATH: [!php!]
echo.

rem 显示当前 PHP 版本
php -v > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 没有设置成功！
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('php -v 2^>^&1 ^| findstr /i "PHP"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*PHP =!"
    set "currentVersion=!currentVersion:~0,5!"
    echo 当前版本：[!currentVersion!]
)

echo.
rem 暂停等待用户按键后退出
pause

endlocal

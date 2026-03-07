@echo off
chcp 65001 >nul
rem 检测管理员权限
(pushd "%~dp0") && (reg query "HKU\S-1-5-19" > nul 2>&1) || (powershell -command "& { Start-Process '%~sdpnx0' -Verb RunAs }" && exit)
setlocal enabledelayedexpansion

rem 设置用户自定义路径及 JDK 路径
set "jdkBasePath=D:\Peng\App\DevApp\jdk-"

rem 检测执行 java -version 命令
java -version > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 当前没有安装 JDK 程序
    echo.
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*version=!"
    echo 当前 JDK 当前版本：[!currentVersion!]
    echo.
)

rem 显示用户选择 JDK 版本
echo 选择 JDK 版本
echo.
echo   选项1：版本[8]
echo.
echo   选项2：版本[11]
echo.
echo   选项3：版本[17]
echo.

set /p choice=请选择版本:
echo.

rem 根据用户选择的 JDK 版本
if "%choice%" equ "1" set version=8
if "%choice%" equ "2" set version=11
if "%choice%" equ "3" set version=17

set "jdk=!jdkBasePath!!version!\bin"

set "PATH=!PATH:%jdkBasePath%8\bin%=!"
set "PATH=!PATH:%jdkBasePath%11\bin%=!"
set "PATH=!PATH:%jdkBasePath%17\bin%=!"
set "PATH=!PATH!;%jdk%"

echo 切换到版本[!version!]

rem 写入系统环境变量
setx PATH "!PATH!" /M
echo 已添加到 PATH: [!jdk!]
echo.

rem 显示当前 JDK 版本
java -version > nul 2>&1
if %errorlevel% neq 0 (
    rem 执行失败
    echo 没有设置成功！
) else (
    rem 执行成功
    for /f "tokens=* delims=" %%i in ('java -version 2^>^&1 ^| findstr /i "version"') do set "currentVersion=%%i"
    set "currentVersion=!currentVersion:*version=!"
    echo 当前版本：[!currentVersion!]
)

echo.
rem 暂停等待用户按键后退出
pause

endlocal

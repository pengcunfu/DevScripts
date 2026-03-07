@echo off
chcp 65001 >nul
:: Win11 右键菜单切换脚本，支持自动管理员权限检测及 Win11 版本校验

:: ===== 1. 管理员权限检测 =====
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo 请以管理员身份运行此脚本！
    echo 右键脚本 -^> 选择"以管理员身份运行"
    pause
    exit /b 1
)

:: ===== 2. Windows 11 版本校验 =====
for /f "tokens=4-5 delims=. " %%i in ('ver') do (
    set OS_MAJOR=%%i
    set OS_MINOR=%%j
)
if not "%OS_MAJOR%"=="10" (
    echo 错误：此脚本仅支持 Windows 10/11
    pause
    exit /b 1
)

:: ===== 主菜单 =====
echo 请选择操作
echo 1. 禁用右键菜单（显示更多选项，即 Win10 的样式）
echo 2. 恢复右键菜单（Win11 默认样式）
echo 0. 退出
set /p choice=请输入数字后回车：

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="0" exit

:disable
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f
taskkill /f /im explorer.exe >nul
start explorer.exe
echo 已禁用右键菜单，请刷新桌面！
goto end

:enable
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
taskkill /f /im explorer.exe >nul
start explorer.exe
echo 已恢复 Win11 默认菜单
goto end

:end
pause

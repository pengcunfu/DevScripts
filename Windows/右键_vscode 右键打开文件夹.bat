@ECHO OFF&chcp 65001 >nul&(PUSHD "%~DP0")&(REG QUERY "HKU\S-1-5-19">NUL 2>&1)||(
powershell -Command "Start-Process '%~sdpnx0' -Verb RunAs"&&EXIT)

REM 此辅助脚本的目的是检测脚本是否以管理员权限运行，如果没有管理员权限，则以管理员权限重新运行脚本。

VER|FINDSTR "5\.[0-9]\.[0-9][0-9]*" > NUL && (
ECHO.&ECHO 当前不支持WinXP &PAUSE>NUL&EXIT)

REM 设置菜单根名称：
set "menuRoot=VSCode"
REM 设置菜单路径：
set "menuPath=D:\Peng\App\DevApp\Microsoft VS Code\Code.exe"
REM 设置菜单显示名称：
set "menuName=通过 Code 打开"

:MENU
CLS
ECHO.&ECHO ════════════════════════════════════
ECHO.&ECHO       VSCode 右键菜单管理工具
ECHO.&ECHO ════════════════════════════════════
ECHO.&ECHO 1. 添加系统右键 %menuRoot% 菜单
ECHO.&ECHO 2. 移除系统右键 %menuRoot% 菜单
ECHO.&ECHO 0. 退出
ECHO.&ECHO ════════════════════════════════════
IF EXIST "%WinDir%\System32\CHOICE.exe" CHOICE /C 120 /N /M "请选择操作："
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="3" EXIT
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="2" GOTO RemoveMenu
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="1" GOTO AddMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" ECHO.&SET /p choice=请输入选项后回车：
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF NOT "%choice%"=="" SET choice=%choice:~0,1%
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="0" EXIT
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="1" GOTO AddMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="2" GOTO RemoveMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" ECHO.&ECHO 输入无效 &PAUSE&CLS&GOTO MENU

:AddMenu
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /ve /d "%menuName%" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /v "Icon" /d "\"%menuPath%\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%\command" /ve /d "\"%menuPath%\" \"%%V\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /ve /d "%menuName%" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /v "Icon" /d "\"%menuPath%\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%\command" /ve /d "\"%menuPath%\" \"%%V\"" /f >nul
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO 添加成功！
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO 添加成功！按任意键继续... &PAUSE>NUL&CLS&GOTO MENU
)

:RemoveMenu
reg delete "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /f >nul 2>nul
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /f >nul 2>nul
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO 移除成功！
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO 已删除菜单，按任意键继续... &PAUSE>NUL&CLS&GOTO MENU
)

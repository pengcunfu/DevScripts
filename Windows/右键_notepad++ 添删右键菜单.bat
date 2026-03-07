@ECHO OFF&chcp 65001 >nul&(PUSHD "%~DP0")&(REG QUERY "HKU\S-1-5-19">NUL 2>&1)||(
powershell -Command "Start-Process '%~sdpnx0' -Verb RunAs"&&EXIT)

VER|FINDSTR "5\.[0-9]\.[0-9][0-9]*" > NUL && (
ECHO.&ECHO 当前不支持WinXP &PAUSE>NUL&EXIT)

rd/s/q "%AppData%\notepad++" 2>NUL

:MENU
CLS
ECHO.&ECHO ════════════════════════════════════
ECHO.&ECHO     Notepad++ 右键菜单管理工具
ECHO.&ECHO ════════════════════════════════════
ECHO.&ECHO 1. 添加系统右键 Notepad++ 菜单
ECHO.&ECHO 2. 移除系统右键 Notepad++ 菜单
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
reg add "HKCR\*\shell\notepad++" /f /v "" /d "用 &Notepad++ 打开" >NUL 2>NUL
reg add "HKCR\*\shell\notepad++" /f /v "Icon" /d "%~dp0notepad++.exe" >NUL 2>NUL
reg add "HKCR\*\shell\notepad++\command" /f /v "" /d "%~dp0notepad++.exe \"%%1\"" >NUL 2>NUL
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO 添加成功！
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO 添加成功！按任意键继续... &PAUSE>NUL&CLS&GOTO MENU
)

:RemoveMenu
reg delete "HKCR\*\shell\notepad++" /f >NUL 2>NUL
reg delete "HKLM\*\shell\notepad++" /f >NUL 2>NUL
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO 移除成功！
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO 已删除菜单，按任意键继续... &PAUSE>NUL&CLS&GOTO MENU
)

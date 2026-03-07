@ECHO OFF&(PUSHD "%~DP0")&(REG QUERY "HKU\S-1-5-19">NUL 2>&1)||(
powershell -Command "Start-Process '%~sdpnx0' -Verb RunAs"&&EXIT)

VER|FINDSTR "5\.[0-9]\.[0-9][0-9]*" > NUL && (
ECHO.&ECHO Windows XP not supported &PAUSE>NUL&EXIT)

rd/s/q "%AppData%\notepad++" 2>NUL

:MENU
CLS
ECHO.&ECHO ==========================================
ECHO.&ECHO     Notepad++ Context Menu Manager
ECHO.&ECHO ==========================================
ECHO.&ECHO 1. Add Notepad++ to system context menu
ECHO.&ECHO 2. Remove Notepad++ from system context menu
ECHO.&ECHO 0. Exit
ECHO.&ECHO ==========================================
IF EXIST "%WinDir%\System32\CHOICE.exe" CHOICE /C 120 /N /M "Select operation:"
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="3" EXIT
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="2" GOTO RemoveMenu
IF EXIST "%WinDir%\System32\CHOICE.exe" IF "%ERRORLEVEL%"=="1" GOTO AddMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" ECHO.&SET /p choice=Enter option:
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF NOT "%choice%"=="" SET choice=%choice:~0,1%
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="0" EXIT
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="1" GOTO AddMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" IF /I "%choice%"=="2" GOTO RemoveMenu
IF NOT EXIST "%WinDir%\System32\CHOICE.exe" ECHO.&ECHO Invalid input &PAUSE&CLS&GOTO MENU

:AddMenu
reg add "HKCR\*\shell\notepad++" /f /v "" /d "Open with &Notepad++" >NUL 2>NUL
reg add "HKCR\*\shell\notepad++" /f /v "Icon" /d "%~dp0notepad++.exe" >NUL 2>NUL
reg add "HKCR\*\shell\notepad++\command" /f /v "" /d "%~dp0notepad++.exe \"%%1\"" >NUL 2>NUL
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO Added successfully!
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO Added successfully! Press any key to continue... &PAUSE>NUL&CLS&GOTO MENU
)

:RemoveMenu
reg delete "HKCR\*\shell\notepad++" /f >NUL 2>NUL
reg delete "HKLM\*\shell\notepad++" /f >NUL 2>NUL
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO Removed successfully!
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO Removed successfully! Press any key to continue... &PAUSE>NUL&CLS&GOTO MENU
)

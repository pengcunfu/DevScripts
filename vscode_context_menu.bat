@ECHO OFF
rem ============================================================================
rem VSCode Context Menu Manager
rem ----------------------------------------------------------------------------
rem Add or remove "Open with Code" on folder right-click menus.
rem
rem Features:
rem   - Add VSCode to Directory and Background context menus
rem   - Remove VSCode context menu entries
rem   - Auto-elevate if not admin
rem
rem Usage: Run as Administrator. Edit menuPath to your Code.exe path.
rem ============================================================================
(PUSHD "%~DP0") && (REG QUERY "HKU\S-1-5-19">NUL 2>&1) || (
powershell -Command "Start-Process '%~sdpnx0' -Verb RunAs" && EXIT)

REM This helper script checks for admin rights and re-runs with elevation if needed

VER|FINDSTR "5\.[0-9]\.[0-9][0-9]*" > NUL && (
ECHO.&ECHO Windows XP not supported &PAUSE>NUL&EXIT)

REM Set menu root name:
set "menuRoot=VSCode"
REM Set menu path (MODIFY THIS TO YOUR VSCODE INSTALLATION PATH):
set "menuPath=D:\Peng\App\DevApp\Microsoft VS Code\Code.exe"
REM Set menu display name:
set "menuName=Open with Code"

:MENU
CLS
ECHO.&ECHO ==========================================
ECHO.&ECHO       VSCode Context Menu Manager
ECHO.&ECHO ==========================================
ECHO.&ECHO 1. Add %menuRoot% to system context menu
ECHO.&ECHO 2. Remove %menuRoot% from system context menu
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
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /ve /d "%menuName%" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /v "Icon" /d "\"%menuPath%\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%\command" /ve /d "\"%menuPath%\" \"%%V\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /ve /d "%menuName%" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /v "Icon" /d "\"%menuPath%\"" /f >nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%\command" /ve /d "\"%menuPath%\" \"%%V\"" /f >nul
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO Added successfully!
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO Added successfully! Press any key to continue... &PAUSE>NUL&CLS&GOTO MENU
)

:RemoveMenu
reg delete "HKEY_CLASSES_ROOT\Directory\shell\%menuRoot%" /f >nul 2>nul
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\%menuRoot%" /f >nul 2>nul
IF EXIST "%WinDir%\System32\CHOICE.exe" (
	ECHO.&ECHO Removed successfully!
	TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE (
	ECHO.&ECHO Removed successfully! Press any key to continue... &PAUSE>NUL&CLS&GOTO MENU
)

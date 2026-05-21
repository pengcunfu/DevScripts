@echo off
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
echo  CMD Context Menu
echo.
echo [1] Add CMD
echo [2] Add CMD Admin
echo [3] Remove CMD
echo [4] Remove CMD Admin
echo [5] Exit
echo.
set /p choice=Select (1-5):

if "%choice%"=="1" goto add_cmd
if "%choice%"=="2" goto add_admin
if "%choice%"=="3" goto remove_cmd
if "%choice%"=="4" goto remove_cmd_admin
if "%choice%"=="5" goto end
goto menu

:add_cmd
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
echo Done!
pause
goto menu

:add_admin
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
echo Done!
pause
goto menu

:add_both
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here" /ve /t REG_SZ /d "Open CMD here" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_here\command" /ve /t REG_SZ /d "cmd.exe /s /k pushd \"%%V\"" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin" /ve /t REG_SZ /d "Open CMD Admin here" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin" /v Icon /t REG_SZ /d "cmd.exe" /f
reg add "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin\command" /ve /t REG_SZ /d "powershell.exe -windowstyle hidden -command \"Start-Process cmd.exe -ArgumentList '/s /k pushd \"%%V\"' -Verb RunAs\"" /f
echo Done!
pause
goto menu

:remove_cmd
reg delete "HKEY_CLASSES_ROOT\Directory\shell\cmd_here" /f >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_here" /f >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Drive\shell\cmd_here" /f >nul 2>&1
echo Done!
pause
goto menu

:remove_cmd_admin
reg delete "HKEY_CLASSES_ROOT\Directory\shell\cmd_admin" /f >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\cmd_admin" /f >nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Drive\shell\cmd_admin" /f >nul 2>&1
echo Done!
pause
goto menu

:end
exit /b 0

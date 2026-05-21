@echo off
echo Fixing CMD startup errors...

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Please run this script as Administrator!
    pause
    exit /b
)

:: Remove CMD AutoRun registry entry
reg delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
if %errorLevel% equ 0 (
    echo AutoRun removed successfully. CMD should start normally now.
) else (
    echo AutoRun not found or delete failed. Please check the registry manually.
)

:: Prompt user to test CMD
echo Please open CMD again to verify the issue is resolved.
pause

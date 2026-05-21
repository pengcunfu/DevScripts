@echo off
rem ============================================================================
rem CMD Startup Fix (Quick)
rem ----------------------------------------------------------------------------
rem Fix CMD that fails to open due to a bad AutoRun registry entry.
rem
rem Features:
rem   - Remove HKCU Command Processor AutoRun value
rem   - Quick one-step repair
rem
rem Usage: Run as Administrator.
rem ============================================================================
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

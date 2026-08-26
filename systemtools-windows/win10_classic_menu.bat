@echo off
rem ============================================================================
rem Switch to Win10 Classic Context Menu
rem ----------------------------------------------------------------------------
rem Enables the Windows 10-style full right-click context menu on Windows 11.
rem Restarts Explorer to apply immediately.
rem
rem Usage: Double-click to run. No admin required.
rem ============================================================================

reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe

echo [OK] Switched to Win10 classic context menu.
pause

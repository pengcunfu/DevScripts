@echo off
rem ============================================================================
rem Restore Win11 Default Context Menu
rem ----------------------------------------------------------------------------
rem Restores the Windows 11 compact right-click context menu (default style).
rem Restarts Explorer to apply immediately.
rem
rem Usage: Double-click to run. No admin required.
rem ============================================================================

reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1 & start explorer.exe

echo [OK] Restored Win11 default context menu.
pause

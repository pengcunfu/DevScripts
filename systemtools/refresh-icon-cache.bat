@echo off
title Refresh Icon and Thumbnail Cache
echo ============================================
echo   Refresh Icon and Thumbnail Cache
echo ============================================
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo [1/5] Stopping Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/5] Clearing thumbnail cache...
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1

echo [3/5] Clearing icon cache...
del /f /s /q "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

echo [4/5] Clearing IE cache (icons)...
del /f /s /q "%LocalAppData%\Microsoft\Windows\INetCache\*ico*" >nul 2>&1

echo [5/5] Restarting Windows Explorer...
start explorer.exe

echo.
echo ============================================
echo   Done! Icon and thumbnail cache cleared.
echo ============================================
echo.
echo If some icons still look wrong, try:
echo   - Right-click the desktop, select Refresh
echo   - Or reboot your computer
echo.
pause

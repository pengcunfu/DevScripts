@echo off
setlocal EnableExtensions
rem ============================================================================
rem Enable Windows Update
rem ----------------------------------------------------------------------------
rem Restores the default Windows Update configuration after running
rem disable_windows_update.bat.
rem
rem What it restores:
rem   - Services -> default start types
rem       wuauserv      Manual
rem       UsoSvc        Automatic (Delayed Start)
rem       WaaSMedicSvc  Manual
rem       DoSvc         Automatic (Delayed Start)
rem   - Removes the Windows Update policy values and pause values
rem   - Re-enables the update related scheduled tasks
rem   - Refreshes group policy and starts an update scan
rem
rem Usage: right-click -> Run as administrator (the script self-elevates)
rem ============================================================================
chcp 65001 >nul
title Enable Windows Update

:: --- self-elevate -----------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

echo ============================================================
echo   Enable Windows Update
echo ============================================================
echo.
echo This restores the default Windows Update configuration.
echo.
pause
echo.

:: --- restore service start types --------------------------------------------
echo [1/4] Restoring service startup types...
sc config wuauserv start= demand >nul 2>&1
sc config UsoSvc start= delayed-auto >nul 2>&1
sc config WaaSMedicSvc start= demand >nul 2>&1
sc config DoSvc start= delayed-auto >nul 2>&1
echo     [OK]   wuauserv=Manual   UsoSvc=Automatic (Delayed)
echo     [OK]   WaaSMedicSvc=Manual   DoSvc=Automatic (Delayed)

:: --- remove policy values ----------------------------------------------------
echo.
echo [2/4] Removing Windows Update policies and pause values...
set "WU_KEY=HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
set "UX_KEY=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

reg delete "%WU_KEY%" /v SetDisableUXWUAccess /f >nul 2>&1
reg delete "%WU_KEY%" /v DisableWindowsUpdateAccess /f >nul 2>&1
reg delete "%WU_KEY%\AU" /v NoAutoUpdate /f >nul 2>&1
reg delete "%WU_KEY%\AU" /v AUOptions /f >nul 2>&1

for %%V in (PauseUpdatesExpiryTime PauseFeatureUpdatesStartTime PauseFeatureUpdatesEndTime PauseQualityUpdatesStartTime PauseQualityUpdatesEndTime FlightSettingsMaxPauseDays) do (
    reg delete "%UX_KEY%" /v %%V /f >nul 2>&1
)
echo     [OK]   policies removed, pause cleared

:: --- re-enable scheduled tasks ----------------------------------------------
echo.
echo [3/4] Re-enabling update scheduled tasks...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$paths='\Microsoft\Windows\UpdateOrchestrator\','\Microsoft\Windows\WindowsUpdate\','\Microsoft\Windows\InstallService\','\Microsoft\Windows\WaaSMedic\';$n=0;foreach($p in $paths){$r=@(Get-ScheduledTask -TaskPath $p -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue);$n+=$r.Count};Write-Host ('    [OK]   ' + $n + ' task(s) enabled')"

:: --- start services ---------------------------------------------------------
echo.
echo [4/4] Starting services and refreshing policy...
sc start wuauserv >nul 2>&1
sc start UsoSvc >nul 2>&1
sc start DoSvc >nul 2>&1
gpupdate /force >nul 2>&1
timeout /t 2 /nobreak >nul
schtasks /Run /TN "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan" >nul 2>&1

echo.
echo ============================================================
echo   Windows Update has been re-enabled.
echo ============================================================
echo.
echo   If the scan did not start automatically, open Settings
echo   ^> Windows Update and click "Check for updates".
echo.
pause
endlocal

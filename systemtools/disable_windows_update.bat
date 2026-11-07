@echo off
setlocal EnableExtensions
rem ============================================================================
rem Disable Windows Update (permanent)
rem ----------------------------------------------------------------------------
rem Stops Windows Update from downloading or installing anything until it is
rem explicitly restored by enable_windows_update.bat.
rem
rem What it changes:
rem   - Services wuauserv / UsoSvc / WaaSMedicSvc / DoSvc -> Disabled
rem   - Policy keys: NoAutoUpdate=1, AUOptions=2, Windows Update UI blocked
rem   - Feature and quality updates paused until 2099-12-31
rem   - Scheduled tasks under UpdateOrchestrator / WindowsUpdate /
rem     InstallService / WaaSMedic -> Disabled
rem
rem WaaSMedicSvc (Windows Update Medic) is the service that re-enables updates
rem behind your back. It is handled last; if its registry key is ACL-locked the
rem script takes ownership before changing its Start value.
rem
rem Usage : right-click -> Run as administrator (the script self-elevates)
rem Undo  : run enable_windows_update.bat
rem ============================================================================
chcp 65001 >nul
title Disable Windows Update

:: --- self-elevate -----------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

echo ============================================================
echo   Disable Windows Update
echo ============================================================
echo.
echo This will permanently disable Windows Update on this machine.
echo Undo at any time with: enable_windows_update.bat
echo.
pause
echo.

:: --- stop services ----------------------------------------------------------
echo [1/4] Stopping update services...
for %%S in (wuauserv UsoSvc WaaSMedicSvc DoSvc) do (
    sc stop %%S >nul 2>&1
)
timeout /t 2 /nobreak >nul

:: --- disable services -------------------------------------------------------
echo.
echo [2/4] Setting services to Disabled...
for %%S in (wuauserv UsoSvc DoSvc) do (
    sc config %%S start= disabled >nul 2>&1
    if errorlevel 1 (echo     [WARN] %%S could not be disabled) else (echo     [OK]   %%S)
)

sc config WaaSMedicSvc start= disabled >nul 2>&1
if errorlevel 1 (
    echo     [*] WaaSMedicSvc is ACL-protected, taking ownership...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='SYSTEM\CurrentControlSet\Services\WaaSMedicSvc';$k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($p,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::TakeOwnership);$a=$k.GetAccessControl();$a.SetOwner([System.Security.Principal.NTAccount]'BUILTIN\Administrators');$k.SetAccessControl($a);$k.Close();$k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($p,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions);$a=$k.GetAccessControl();$r=New-Object System.Security.AccessControl.RegistryAccessRule('BUILTIN\Administrators','FullControl','Allow');$a.SetAccessRule($r);$k.SetAccessControl($a);$k.Close();$key='HKLM:\'+$p;Set-ItemProperty -Path $key -Name Start -Value 4 -Type DWord" >nul 2>&1
    if errorlevel 1 (echo     [WARN] WaaSMedicSvc could not be disabled) else (echo     [OK]   WaaSMedicSvc)
) else (
    echo     [OK]   WaaSMedicSvc
)

:: --- policy registry --------------------------------------------------------
echo.
echo [3/4] Applying Windows Update policies...
set "WU_KEY=HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
set "AU_KEY=%WU_KEY%\AU"
set "UX_KEY=HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

reg add "%AU_KEY%" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%AU_KEY%" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
reg add "%WU_KEY%" /v SetDisableUXWUAccess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%WU_KEY%" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul 2>&1

reg add "%UX_KEY%" /v PauseUpdatesExpiryTime /t REG_SZ /d "2099-12-31T00:00:00Z" /f >nul 2>&1
reg add "%UX_KEY%" /v PauseFeatureUpdatesStartTime /t REG_SZ /d "2020-01-01T00:00:00Z" /f >nul 2>&1
reg add "%UX_KEY%" /v PauseFeatureUpdatesEndTime /t REG_SZ /d "2099-12-31T00:00:00Z" /f >nul 2>&1
reg add "%UX_KEY%" /v PauseQualityUpdatesStartTime /t REG_SZ /d "2020-01-01T00:00:00Z" /f >nul 2>&1
reg add "%UX_KEY%" /v PauseQualityUpdatesEndTime /t REG_SZ /d "2099-12-31T00:00:00Z" /f >nul 2>&1
reg add "%UX_KEY%" /v FlightSettingsMaxPauseDays /t REG_DWORD /d 5000 /f >nul 2>&1
echo     [OK]   NoAutoUpdate / UI access blocked / updates paused

:: --- scheduled tasks --------------------------------------------------------
echo.
echo [4/4] Disabling update scheduled tasks...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$paths='\Microsoft\Windows\UpdateOrchestrator\','\Microsoft\Windows\WindowsUpdate\','\Microsoft\Windows\InstallService\','\Microsoft\Windows\WaaSMedic\';$n=0;foreach($p in $paths){$r=@(Get-ScheduledTask -TaskPath $p -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue);$n+=$r.Count};Write-Host ('    [OK]   ' + $n + ' task(s) disabled')"

echo.
echo ============================================================
echo   Windows Update is now disabled.
echo ============================================================
echo.
echo   - A reboot is recommended to fully apply the changes.
echo   - Settings ^> Windows Update may show errors; expected.
echo   - Run enable_windows_update.bat to restore updates.
echo.
pause
endlocal

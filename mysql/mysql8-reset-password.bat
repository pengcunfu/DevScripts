@echo off
setlocal EnableExtensions
rem ============================================================================
rem MySQL 8 Password Reset (forgot the root password)
rem ----------------------------------------------------------------------------
rem Resets the configured root account without knowing the old password, using the
rem official --init-file method:
rem   1. Stop the MySQL service
rem   2. Start mysqld once with a temporary init file containing ALTER USER
rem   3. Shut that temporary server down
rem   4. Start the service again and verify the new password
rem
rem Requirements:
rem   - MySQL 8.x installed as a Windows service. A manual (zip) install also
rem     works: the script asks for mysqld.exe and my.ini.
rem   - Administrator privileges (the script self-elevates).
rem   - The root account user and host default to root and localhost. Change
rem     ROOT_USER and ROOT_HOST in the configuration block below.
rem
rem The new password may contain any printable ASCII character. Quote and
rem backslash characters are escaped automatically.
rem
rem After running this, update every application that uses the old password.
rem ============================================================================
chcp 65001 >nul
title MySQL 8 Password Reset

rem ============================================================================
rem User configuration: edit these values for your environment.
rem For a Windows service set SERVICE; for a manual (zip) install set MYSQLD.
rem Empty service, path and port values are detected automatically.
rem ============================================================================
rem MySQL root account name (example: root)
set "ROOT_USER=root"

rem Root account host (example: localhost; use 127.0.0.1 for a TCP-only account)
set "ROOT_HOST=localhost"

rem Windows service name (example: MySQL80). Set it to force service mode.
set "SERVICE="

rem Full path to mysqld.exe (example: C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe).
rem Set it to force manual mode; leave empty to detect it from the service.
set "MYSQLD="

rem Full path to my.ini (example: C:\ProgramData\MySQL\MySQL Server 8.0\my.ini).
rem Leave empty to detect it automatically.
set "MYINI="

rem TCP port for the temporary client (example: 3306). Leave empty to read my.ini.
set "MYSQL_PORT="

rem Strip optional quotes around the paths configured above.
set "MYSQLD=%MYSQLD:"=%"
set "MYINI=%MYINI:"=%"

:: --- self-elevate -----------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [*] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

echo ============================================================
echo   MySQL 8 Password Reset
echo ============================================================
echo.
echo This resets the password of '%ROOT_USER%'@'%ROOT_HOST%' without the old one.
echo Close any other MySQL instance before continuing.
echo.
pause
echo.

set "WAS_RUNNING=0"
set "SERVICE_STOPPED=0"
set "TEMP_STARTED=0"
set "TMPD=%TEMP%\mysql_reset_%RANDOM%%RANDOM%"
set "MYSQL_INIT=%TMPD%\init.sql"
set "MYSQL_CNF=%TMPD%\client.ini"
set "MYSQLERR=%TMPD%\mysqld.err"
mkdir "%TMPD%" >nul 2>&1
if not exist "%TMPD%" (
    echo [ERROR] Cannot create temporary directory: %TMPD%
    goto abort
)

:: --- locate the MySQL service ----------------------------------------------
if defined SERVICE goto service_ready
if defined MYSQLD goto paths_ready
set "SVC_TMP=%TMPD%\services.txt"
powershell -NoProfile -Command "Get-CimInstance Win32_Service | Where-Object { $_.PathName -match 'mysqld\.exe' } | ForEach-Object { $_.Name }" > "%SVC_TMP%" 2>nul
set "SVCCOUNT=0"
for /f "usebackq delims=" %%A in ("%SVC_TMP%") do set /a SVCCOUNT+=1

if "%SVCCOUNT%"=="0" goto ask_service
if "%SVCCOUNT%"=="1" (
    for /f "usebackq delims=" %%A in ("%SVC_TMP%") do set "SERVICE=%%A"
    goto service_ready
)
echo Detected MySQL services:
type "%SVC_TMP%"
echo.
set /p SERVICE=Enter the service name to reset:
goto service_ready

:ask_service
echo [WARN] No MySQL service detected.
echo Enter the full path to mysqld.exe (leave empty to abort):
set /p MYSQLD=
if not defined MYSQLD goto abort
set "MYSQLD=%MYSQLD:"=%"
if not exist "%MYSQLD%" (
    echo [ERROR] mysqld.exe not found: %MYSQLD%
    goto abort
)
goto paths_ready

:service_ready
if not defined SERVICE goto abort
sc query "%SERVICE%" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Service not found: %SERVICE%
    goto abort
)
set "MYSQL_SVC=%SERVICE%"
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$s=Get-CimInstance Win32_Service | Where-Object { $_.Name -eq $env:MYSQL_SVC }; if($s){$m=[regex]::Match($s.PathName,'^\x22?(.*?mysqld\.exe)');$d=[regex]::Match($s.PathName,'--defaults-file=(?:\x22([^\x22]+)\x22|(\S+))');$ini=$d.Groups[1].Value;if(-not $ini){$ini=$d.Groups[2].Value};Write-Output ($m.Groups[1].Value + '|' + $ini)}"`) do (
    for /f "tokens=1,2 delims=|" %%B in ("%%A") do (
        if not defined MYSQLD set "MYSQLD=%%B"
        if not defined MYINI set "MYINI=%%C"
    )
)

:paths_ready
if not exist "%MYSQLD%" (
    echo [ERROR] mysqld.exe not found: %MYSQLD%
    goto abort
)
for %%P in ("%MYSQLD%") do set "BINDIR=%%~dpP"
set "MYSQL=%BINDIR%mysql.exe"
set "MYSQLADMIN=%BINDIR%mysqladmin.exe"
if not exist "%MYSQL%" (
    echo [ERROR] mysql.exe not found next to mysqld.exe.
    goto abort
)
if not exist "%MYSQLADMIN%" (
    echo [ERROR] mysqladmin.exe not found next to mysqld.exe.
    goto abort
)
if defined MYINI if not exist "%MYINI%" (
    echo [ERROR] my.ini not found: %MYINI%
    goto abort
)
if exist "%MYINI%" goto myini_ready
for %%P in ("%BINDIR%..") do set "MYSQLHOME=%%~fP"
for %%P in ("%MYSQLHOME%") do set "MYSQLVER=%%~nxP"
if exist "%ProgramData%\MySQL\%MYSQLVER%\my.ini" set "MYINI=%ProgramData%\MySQL\%MYSQLVER%\my.ini"
if not exist "%MYINI%" if exist "%MYSQLHOME%\my.ini" set "MYINI=%MYSQLHOME%\my.ini"
if exist "%MYINI%" goto myini_ready
echo [WARN] my.ini not found automatically.
set /p MYINI=Enter the full path to my.ini:
:myini_ready
set "MYINI=%MYINI:"=%"
if not exist "%MYINI%" (
    echo [ERROR] my.ini not found.
    goto abort
)

:: --- version check ----------------------------------------------------------
for /f "tokens=3" %%V in ('"%MYSQLD%" --version 2^>^&1') do set "MYSQLVER_FULL=%%V"
if not defined MYSQLVER_FULL goto version_checked
for /f "tokens=1 delims=.-" %%M in ("%MYSQLVER_FULL%") do set "MYSQLMAJOR=%%M"
if "%MYSQLMAJOR%"=="8" goto version_checked
echo.
echo [WARN] Detected server version: %MYSQLVER_FULL%
echo        This script is for MySQL 8.x.
set /p OK=Continue anyway? (Y/N):
if /i not "%OK%"=="Y" goto abort
:version_checked

:: --- port used by the temporary server --------------------------------------
if defined MYSQL_PORT goto port_ready
set "MYSQL_PORT=3306"
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$m=Select-String -LiteralPath $env:MYINI -Pattern '^\s*port\s*=\s*(\d+)' -ErrorAction SilentlyContinue | Select-Object -First 1; if($m){$m.Matches[0].Groups[1].Value}"`) do set "MYSQL_PORT=%%P"
:port_ready

echo.
echo Service : "%SERVICE%"
echo mysqld  : "%MYSQLD%"
echo my.ini  : "%MYINI%"
echo Account : '%ROOT_USER%'@'%ROOT_HOST%'
echo Port    : %MYSQL_PORT%

:: --- ask for the new password ----------------------------------------------
set /a PWTRIES=0
:ask_pass
set /a PWTRIES+=1
if %PWTRIES% gtr 4 goto abort
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s1=Read-Host -AsSecureString 'New password'; $s2=Read-Host -AsSecureString 'Confirm password'; $b1=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1); $b2=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2); $p1=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b1); $p2=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b2); [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b1); [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b2); if($p1 -cne $p2){exit 2}; if([string]::IsNullOrEmpty($p1)){exit 1}; if($p1 -match '[^\x20-\x7E]'){exit 3}; $q=[char]39; $bs=[string][char]92; $sq=$p1.Replace($bs,($bs+$bs)).Replace([string]$q,([string]$q+[string]$q)); $sql='ALTER USER ' + $q + $env:ROOT_USER + $q + '@' + $q + $env:ROOT_HOST + $q + ' IDENTIFIED BY ' + $q + $sq + $q + ' ACCOUNT UNLOCK;'; $ev=$p1.Replace($bs,($bs+$bs)).Replace([string][char]34,($bs+[string][char]34)); $cnf='[client]',('user=' + $env:ROOT_USER),('password=' + [char]34 + $ev + [char]34),'host=127.0.0.1',('port=' + $env:MYSQL_PORT); try { Set-Content -LiteralPath $env:MYSQL_INIT -Value $sql -Encoding ASCII -ErrorAction Stop; Set-Content -LiteralPath $env:MYSQL_CNF -Value $cnf -Encoding ASCII -ErrorAction Stop } catch { exit 4 }"
if errorlevel 4 (
    echo [ERROR] Cannot write temporary files.
    goto abort
)
if errorlevel 3 (
    echo [ERROR] The password must use printable ASCII characters only.
    goto ask_pass
)
if errorlevel 2 (
    echo [ERROR] Passwords do not match.
    goto ask_pass
)
if errorlevel 1 (
    echo [ERROR] Password cannot be empty.
    goto ask_pass
)

:: --- stop the service -------------------------------------------------------
if not defined SERVICE goto stray_check
set "MYSQL_SVC=%SERVICE%"
powershell -NoProfile -Command "$s=Get-Service -Name $env:MYSQL_SVC -ErrorAction SilentlyContinue; if(-not $s){exit 1}; if($s.Status -eq 'Running'){exit 0}else{exit 2}"
if errorlevel 2 goto service_already_stopped
if errorlevel 1 (
    echo [ERROR] Service disappeared: %SERVICE%
    goto fail
)
set "WAS_RUNNING=1"
echo.
echo [1/5] Stopping service %SERVICE%...
net stop "%SERVICE%" /y >nul 2>&1
set "SERVICE_STOPPED=1"
set /a W=0
:wait_stop
powershell -NoProfile -Command "if((Get-Service -Name $env:MYSQL_SVC).Status -eq 'Stopped'){exit 0}else{exit 1}"
if not errorlevel 1 goto service_stopped_ok
set /a W+=1
if %W% geq 30 (
    echo [ERROR] Service did not stop within 30 seconds.
    goto fail
)
timeout /t 1 /nobreak >nul
goto wait_stop
:service_stopped_ok
:service_already_stopped

:: --- make sure no other mysqld is running -----------------------------------
:stray_check
powershell -NoProfile -Command "if(Get-Process mysqld -ErrorAction SilentlyContinue){exit 0}else{exit 1}"
if errorlevel 1 goto no_stray
echo.
echo [WARN] Another mysqld.exe process is running.
echo        It would conflict with the temporary server.
set /p KILL=Kill all mysqld.exe processes now? (Y/N):
if /i "%KILL%"=="Y" goto kill_stray
echo [ERROR] Aborted. Stop the other MySQL instance first.
goto fail
:kill_stray
taskkill /f /im mysqld.exe >nul 2>&1
timeout /t 2 /nobreak >nul
:no_stray

:: --- start the temporary server ---------------------------------------------
echo.
echo [2/5] Starting temporary server with the init file...
start "MySQLReset" /b "%MYSQLD%" --defaults-file="%MYINI%" --init-file="%MYSQL_INIT%" --log-error="%MYSQLERR%"
set "TEMP_STARTED=1"
timeout /t 2 /nobreak >nul

echo [3/5] Waiting for the new password to take effect...
set /a W=0
:wait_ready
"%MYSQL%" --defaults-extra-file="%MYSQL_CNF%" --connect-timeout=2 -e "SELECT 1" > "%TMPD%\client.out" 2>&1
if not errorlevel 1 goto reset_ok
set /a W+=1
if %W% geq 30 goto reset_timeout
timeout /t 1 /nobreak >nul
goto wait_ready

:reset_timeout
echo [ERROR] The temporary server did not accept the new password.
echo.
echo --- mysqld error log ---
type "%MYSQLERR%" 2>nul
echo --- client output ---
type "%TMPD%\client.out" 2>nul
echo ------------------------
goto fail

:reset_ok
echo [OK] Password changed on the temporary server.

:: --- stop the temporary server ----------------------------------------------
echo.
echo [4/5] Stopping the temporary server...
"%MYSQLADMIN%" --defaults-extra-file="%MYSQL_CNF%" shutdown >nul 2>&1
set /a W=0
:wait_shutdown
powershell -NoProfile -Command "if(Get-Process mysqld -ErrorAction SilentlyContinue){exit 0}else{exit 1}"
if errorlevel 1 goto shutdown_done
set /a W+=1
if %W% geq 20 (
    echo [WARN] Temporary server did not stop, forcing it...
    taskkill /f /im mysqld.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    goto shutdown_done
)
timeout /t 1 /nobreak >nul
goto wait_shutdown

:shutdown_done
set "TEMP_STARTED=0"

:: --- restore the service ----------------------------------------------------
echo [5/5] Starting the MySQL service...
if not defined SERVICE goto no_service_finish
if not "%WAS_RUNNING%"=="1" goto service_was_stopped
net start "%SERVICE%" > "%TMPD%\netstart.out" 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to start service %SERVICE%:
    type "%TMPD%\netstart.out"
    goto fail
)
set /a W=0
:wait_start
powershell -NoProfile -Command "if((Get-Service -Name $env:MYSQL_SVC).Status -eq 'Running'){exit 0}else{exit 1}"
if not errorlevel 1 goto service_running
set /a W+=1
if %W% geq 30 goto service_start_timeout
timeout /t 1 /nobreak >nul
goto wait_start
:service_start_timeout
echo [WARN] Service did not report Running within 30 seconds.
:service_running

set /a W=0
:verify
"%MYSQL%" --defaults-extra-file="%MYSQL_CNF%" -e "SELECT VERSION();" > "%TMPD%\verify.out" 2>&1
if not errorlevel 1 goto verify_ok
set /a W+=1
if %W% geq 15 goto verify_fail
timeout /t 1 /nobreak >nul
goto verify
:verify_fail
echo [WARN] The service is running but rejected the new password.
echo        Check ROOT_USER and ROOT_HOST against mysql.user.
goto fail
:verify_ok
type "%TMPD%\verify.out"
echo.
echo ============================================================
echo   [SUCCESS] The root password has been reset.
echo ============================================================
echo.
echo   Update every application that used the old password.
echo.
goto cleanup

:service_was_stopped
echo [INFO] The service was already stopped and was left stopped.
echo [SUCCESS] The new password was verified on the temporary server.
echo.
goto cleanup

:no_service_finish
echo [SUCCESS] The new password has been set.
echo [INFO] Start your MySQL server the usual way, then test the password.
echo.
goto cleanup

:: --- failure and cleanup ----------------------------------------------------
:fail
echo.
echo [ERROR] Password reset failed.
if not "%TEMP_STARTED%"=="1" goto fail_no_temp
taskkill /f /im mysqld.exe >nul 2>&1
set "TEMP_STARTED=0"
timeout /t 2 /nobreak >nul
:fail_no_temp
if not "%SERVICE_STOPPED%"=="1" goto fail_no_restart
if not "%WAS_RUNNING%"=="1" goto fail_no_restart
echo [*] Restarting the MySQL service...
net start "%SERVICE%" >nul 2>&1
:fail_no_restart
goto cleanup_fail

:abort
echo.
echo [INFO] Aborted. No changes were made.
goto cleanup_fail

:cleanup
del /f /q "%MYSQL_INIT%" >nul 2>&1
del /f /q "%MYSQL_CNF%" >nul 2>&1
del /f /q "%MYSQLERR%" >nul 2>&1
del /f /q "%TMPD%\*.out" >nul 2>&1
rmdir /s /q "%TMPD%" >nul 2>&1
echo Done.
pause
exit /b 0

:cleanup_fail
del /f /q "%MYSQL_INIT%" >nul 2>&1
del /f /q "%MYSQL_CNF%" >nul 2>&1
del /f /q "%MYSQLERR%" >nul 2>&1
del /f /q "%TMPD%\*.out" >nul 2>&1
rmdir /s /q "%TMPD%" >nul 2>&1
pause
exit /b 1

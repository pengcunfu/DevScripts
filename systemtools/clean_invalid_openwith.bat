@echo off
setlocal
rem ============================================================================
rem Clean Invalid "Open With" Entries (Windows, pure batch, no PowerShell)
rem ----------------------------------------------------------------------------
rem Scans every file extension under:
rem   HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\<.ext>
rem and removes "Open With" entries whose target program no longer exists
rem (deleted or moved), which is what leaves dead options in the "Open with"
rem picker. It also deletes the UserChoice subkey when its associated program
rem is gone -- this fixes extensions that "refuse to change", because
rem UserChoice carries a hash and cannot be edited directly. After removal the
rem extension reverts to the system default and can be re-associated via
rem "Open with" once.
rem
rem Safety: only entries that can be POSITIVELY confirmed as dead are removed.
rem   - Quoted / unquoted full paths  -- removed if the path is missing
rem   - App Paths entry whose target is missing -- removed
rem   - Empty placeholder values      -- removed
rem   - UserChoice -- removed when its ProgId is gone or its exe is missing
rem   - Bare exe names with no App Paths (portable apps, Store shims)
rem     -- left untouched (reported), cannot be safely confirmed as dead
rem   - UWP AppUserModelIDs and GUID references -- left untouched
rem
rem Usage:
rem   clean_invalid_openwith.bat            clean all extensions
rem   clean_invalid_openwith.bat .pdf       clean only one extension
rem   clean_invalid_openwith.bat /dry       preview only, remove nothing
rem ============================================================================

set "BASE=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts"
set "APP=SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"

set "ONLY="
set "DRYRUN="
if /i "%~1"=="/dry" (set "DRYRUN=1") else (set "ONLY=%~1")
if /i "%~2"=="/dry" set "DRYRUN=1"

set /a CNT_EXT=0
set /a CNT_VAL=0
set /a CNT_CHOICE=0
set /a CNT_KEPT=0

title Clean Invalid Open With Entries
echo.
echo   Clean Invalid Open With Entries
echo   ===============================
echo.
if defined DRYRUN echo   MODE: DRY RUN (preview only, nothing will be deleted)
echo.
echo   Scanning: %BASE%
if defined ONLY (echo   Scope: only %ONLY%) else (echo   Scope: all registered extensions)
echo.

for /f "delims=" %%K in ('reg query "%BASE%" 2^>nul') do call :process_key "%%K"

echo.
echo   ==================== Summary ====================
echo     Extensions touched  : %CNT_EXT%
echo     OpenWithList dead   : %CNT_VAL%
echo     UserChoice unlocked : %CNT_CHOICE%
echo     Left unconfirmed    : %CNT_KEPT%
echo   ================================================
if %CNT_CHOICE% gtr 0 (
    echo.
    echo   NOTE: UserChoice removed for dead associations. Those extensions
    echo         now use the system default. Re-associate them via
    echo         Right-click  Open with  Choose another app.
)
if defined DRYRUN (
    echo.
    echo   Dry run finished - no changes were made. Re-run without /dry to apply.
    goto :eof
)
echo.
set /p "RE=   Restart Windows Explorer now? [Y/N]: "
if /i "%RE%"=="y" (
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    start explorer.exe
    echo   Explorer restarted.
) else (
    echo   Skip. Restart Explorer later or reboot to apply.
)
goto :eof

rem ============================================================================
rem :process_key - handle one extension
rem %1 = full registry key path
rem ============================================================================
:process_key
for %%E in ("%~1") do set "EXT=%%~nxE"
if not defined EXT goto :eof
if "%EXT%"=="." goto :eof
if not "%EXT:~0,1%"=="." goto :eof
if defined ONLY if /i not "%EXT%"=="%ONLY%" goto :eof

set "CHG="

rem ---- 1. OpenWithList: dead "Open with" entries ----
for /f "skip=2 tokens=1,2,* delims= " %%A in ('reg query "%BASE%\%EXT%\OpenWithList" 2^>nul') do (
    if /i not "%%A"=="MRUList" call :check_owl "%%A" "%%C"
)

rem ---- 2. UserChoice: locked association pointing to a gone program ----
set "PROGID="
for /f "skip=2 tokens=3 delims= " %%P in ('reg query "%BASE%\%EXT%\UserChoice" /v ProgId 2^>nul') do set "PROGID=%%P"
if defined PROGID call :check_choice

if defined CHG set /a CNT_EXT+=1
goto :eof

rem ============================================================================
rem :check_owl - inspect one OpenWithList value, remove if confirmed dead
rem %1 = value name, %2 = value data; sets AVAL (quote-stripped) for :assess
rem ============================================================================
:check_owl
set "VN=%~1"
if "%VN:~0,1%"=="(" goto :eof          rem skip (default) rows
set "AVAL=%~2"
set "AVAL=%AVAL:"=%"                    rem strip all embedded quotes
if not defined AVAL goto :owl_dead      rem empty placeholder -- dead
call :assess
if "%VERDICT%"=="DEAD" goto :owl_dead
if not "%VERDICT%"=="UNKNOWN" goto :eof    rem alive / other -- nothing to report
set /a CNT_KEPT+=1
echo   [%EXT%] kept    : '%VN%' = %AVAL%  (cannot confirm, portable/Store app?)
goto :eof

:owl_dead
set /a CNT_VAL+=1
set "CHG=1"
if not defined AVAL goto :owl_dead_empty
if defined DRYRUN (
    echo   [%EXT%] would remove : '%VN%' = %AVAL%  - program not found
) else (
    echo   [%EXT%] removed : '%VN%' = %AVAL%  - program not found
)
goto :owl_dead_act
:owl_dead_empty
if defined DRYRUN (
    echo   [%EXT%] would remove : empty placeholder '%VN%'
) else (
    echo   [%EXT%] removed : empty placeholder '%VN%'
)
:owl_dead_act
if not defined DRYRUN reg delete "%BASE%\%EXT%\OpenWithList" /v "%VN%" /f >nul 2>&1
goto :eof

rem ============================================================================
rem :assess - verdict for AVAL (quote-stripped path / exe / other value)
rem sets VERDICT = DEAD | KEEP | UNKNOWN
rem   DEAD    - positively confirmed the target is gone
rem   UNKNOWN - bare exe name with no App Paths (portable/Store app), kept
rem   KEEP    - alive, or an AUMID/GUID/ProgId reference we never touch
rem ============================================================================
:assess
set "VERDICT=KEEP"
set "TV=%AVAL%"
if not defined TV goto :assess_dead
if not "%TV:\=%"=="%TV%" goto :assess_path   rem contains a backslash -- path
if /i not "%TV:~-4%"==".exe" goto :eof       rem not *.exe -- keep (AUMID/GUID/ProgId)
goto :assess_bare

:assess_bare
set "AP="
call :try_app "HKLM" "%TV%"
if not defined AP call :try_app "HKCU" "%TV%"
if defined AP goto :assess_ap
%SystemRoot%\System32\where.exe "%TV%" >nul 2>&1
if not errorlevel 1 goto :eof                rem found on PATH -- alive
goto :assess_unknown                         rem no App Paths / PATH -- cannot confirm

:assess_ap
set "P=%AP%"
call set "P=%P:"=%"
if exist "%P%" goto :eof                     rem alive
set "VERDICT=DEAD"
goto :eof

:assess_unknown
set "VERDICT=UNKNOWN"
goto :eof

:assess_path
set "P=%TV%"
call set "P=%P:"=%"                          rem expand env vars, strip quotes
if exist "%P%" goto :eof                     rem alive
set "VERDICT=DEAD"
goto :eof

:assess_dead
set "VERDICT=DEAD"
goto :eof

rem ============================================================================
rem :try_app - read App Paths default for an exe name
rem %1 = HKLM|HKCU, %2 = exe name; sets AP (empty if not registered)
rem ============================================================================
:try_app
set "AP="
reg query "%1\%APP%\%~2" /ve >nul 2>&1
if errorlevel 1 goto :eof
for /f "skip=2 tokens=2,* delims= " %%X in ('reg query "%1\%APP%\%~2" /ve 2^>nul') do set "AP=%%Y"
goto :eof

rem ============================================================================
rem :check_choice - inspect one extension's UserChoice, unlock if dead
rem uses %PROGID%
rem ============================================================================
:check_choice
if /i "%PROGID:~0,4%"=="AppX" goto :eof          rem UWP package ProgId -- keep
set "AF=%PROGID:*!=%"
if not "%AF%"=="%PROGID%" goto :eof              rem contains '!' -- UWP AUMID -- keep
reg query "HKCR\%PROGID%" >nul 2>&1
if errorlevel 1 goto :choice_dead                rem ProgId not registered -- dead
rem Extract the exe from the open command. Commands are typically:
rem   "C:\path with space\app.exe" args      -- quoted path (+ args)
rem   %SystemRoot%\Explorer.exe /idlist      -- unquoted path + args
rem Both candidates (quote-token and first word) are passed to :choice_cmd,
rem which tries the quote-token first and falls back to the first word.
for /f "skip=2 tokens=2,* delims= " %%X in ('reg query "HKCR\%PROGID%\shell\open\command" /ve 2^>nul') do (
    for /f "tokens=1 delims= " %%W in ("%%Y") do (
        for /f tokens^=1^,2^ delims^=^" %%A in ("%%Y") do call :choice_cmd "%%A" "%%W"
    )
)
goto :eof

:choice_cmd
rem %1 = quote-token (exe for quoted commands, whole line for unquoted ones)
rem %2 = first space-word (fallback for unquoted commands)
set "AVAL=%~1"
call :assess
if not "%VERDICT%"=="DEAD" goto :eof            rem alive or unverifiable -- keep
set "AVAL=%~2"
if not defined AVAL goto :choice_dead
call :assess
if not "%VERDICT%"=="DEAD" goto :eof
goto :choice_dead

:choice_dead
set /a CNT_CHOICE+=1
set "CHG=1"
if defined DRYRUN (
    echo   [%EXT%] would remove : UserChoice ProgId '%PROGID%'  - association unlocked
) else (
    echo   [%EXT%] removed : UserChoice ProgId '%PROGID%'  - association unlocked
)
if not defined DRYRUN reg delete "%BASE%\%EXT%\UserChoice" /f >nul 2>&1
goto :eof

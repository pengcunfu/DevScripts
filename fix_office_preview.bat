@echo off
title Office Preview Fix Tool

echo ==========================================
echo      Office Preview Fix Tool
echo ==========================================
echo.
echo This script will fix Office file preview
echo Supports: Word/Excel/PowerPoint files
echo.
pause

echo.
echo Fixing registry...

:: Word (.docx)
reg add "HKEY_CLASSES_ROOT\.docx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{84F66100-FF7C-4fb4-B0C0-02CD7FB668FE}" /f >nul
if %errorlevel% equ 0 (echo [OK] .docx preview fixed) else (echo [FAIL] .docx preview fix failed)

:: Word (.doc)
reg add "HKEY_CLASSES_ROOT\.doc\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{84F66100-FF7C-4fb4-B0C0-02CD7FB668FE}" /f >nul
if %errorlevel% equ 0 (echo [OK] .doc preview fixed) else (echo [FAIL] .doc preview fix failed)

:: Excel (.xlsx)
reg add "HKEY_CLASSES_ROOT\.xlsx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{00020827-0000-0000-C000-000000000046}" /f >nul
if %errorlevel% equ 0 (echo [OK] .xlsx preview fixed) else (echo [FAIL] .xlsx preview fix failed)

:: Excel (.xls)
reg add "HKEY_CLASSES_ROOT\.xls\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{00020827-0000-0000-C000-000000000046}" /f >nul
if %errorlevel% equ 0 (echo [OK] .xls preview fixed) else (echo [FAIL] .xls preview fix failed)

:: PowerPoint (.pptx)
reg add "HKEY_CLASSES_ROOT\.pptx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{65235197-874B-4A07-BDC5-E65EA825B718}" /f >nul
if %errorlevel% equ 0 (echo [OK] .pptx preview fixed) else (echo [FAIL] .pptx preview fix failed)

:: PowerPoint (.ppt)
reg add "HKEY_CLASSES_ROOT\.ppt\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{65235197-874B-4A07-BDC5-E65EA825B718}" /f >nul
if %errorlevel% equ 0 (echo [OK] .ppt preview fixed) else (echo [FAIL] .ppt preview fix failed)

echo.
echo ==========================================
echo Fix completed! Please restart Explorer or computer
echo ==========================================
echo.
echo [1] Restart Explorer now
echo [0] Exit
echo.
set /p choice=Select option:
if "%choice%"=="1" (
    taskkill /f /im explorer.exe >nul 2>&1
    start explorer.exe
    echo Explorer restarted
)

pause

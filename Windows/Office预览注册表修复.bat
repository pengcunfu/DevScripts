@echo off
chcp 65001 >nul
title Office 预览功能修复工具

echo ════════════════════════════════════════
echo      Office 预览功能修复工具
echo ════════════════════════════════════════
echo.
echo 此脚本将修复 Office 文件预览功能
echo 支持：Word/Excel/PowerPoint 文件
echo.
pause

echo.
echo 正在修复注册表...

:: Word (.docx)
reg add "HKEY_CLASSES_ROOT\.docx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{84F66100-FF7C-4fb4-B0C0-02CD7FB668FE}" /f >nul
if %errorlevel% equ 0 (echo [√] .docx 预览修复成功) else (echo [×] .docx 预览修复失败)

:: Word (.doc)
reg add "HKEY_CLASSES_ROOT\.doc\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{84F66100-FF7C-4fb4-B0C0-02CD7FB668FE}" /f >nul
if %errorlevel% equ 0 (echo [√] .doc 预览修复成功) else (echo [×] .doc 预览修复失败)

:: Excel (.xlsx)
reg add "HKEY_CLASSES_ROOT\.xlsx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{00020827-0000-0000-C000-000000000046}" /f >nul
if %errorlevel% equ 0 (echo [√] .xlsx 预览修复成功) else (echo [×] .xlsx 预览修复失败)

:: Excel (.xls)
reg add "HKEY_CLASSES_ROOT\.xls\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{00020827-0000-0000-C000-000000000046}" /f >nul
if %errorlevel% equ 0 (echo [√] .xls 预览修复成功) else (echo [×] .xls 预览修复失败)

:: PowerPoint (.pptx)
reg add "HKEY_CLASSES_ROOT\.pptx\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{65235197-874B-4A07-BDC5-E65EA825B718}" /f >nul
if %errorlevel% equ 0 (echo [√] .pptx 预览修复成功) else (echo [×] .pptx 预览修复失败)

:: PowerPoint (.ppt)
reg add "HKEY_CLASSES_ROOT\.ppt\ShellEx\{8895b1c6-b41f-4c1c-a562-0d564250836f}" /ve /t REG_SZ /d "{65235197-874B-4A07-BDC5-E65EA825B718}" /f >nul
if %errorlevel% equ 0 (echo [√] .ppt 预览修复成功) else (echo [×] .ppt 预览修复失败)

echo.
echo ════════════════════════════════════════
echo 修复完成！请重启资源管理器或重启计算机
echo ════════════════════════════════════════
echo.
echo [1] 立即重启资源管理器
echo [0] 退出
echo.
set /p choice=请选择:
if "%choice%"=="1" (
    taskkill /f /im explorer.exe >nul 2>&1
    start explorer.exe
    echo 已重启资源管理器
)

pause

@echo off
echo 正在修复 CMD 启动错误...

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit /b
)

:: 删除 CMD 自动运行的 AutoRun 注册表项
reg delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
if %errorLevel% equ 0 (
    echo 成功删除 AutoRun ！CMD 应该可以正常启动了。
) else (
    echo 未找到 AutoRun，或删除失败，请手动检查注册表！
)

:: 提示用户重启 CMD 进行测试
echo 请尝试重新打开 CMD 以检查问题是否解决！
pause

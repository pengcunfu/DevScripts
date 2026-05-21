# 以管理员权限运行 PowerShell
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本！" -ForegroundColor Red
    exit
}

Write-Host "开始修复 CMD 相关问题..." -ForegroundColor Green

# 1. 修改 cmd.exe 相关注册表
Write-Host "修改 cmd.exe 注册表..."
$cmdRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmd.exe"
if (-not (Test-Path $cmdRegPath)) {
    New-Item -Path $cmdRegPath -Force | Out-Null
}
Set-ItemProperty -Path $cmdRegPath -Name "(Default)" -Value "C:\Windows\System32\cmd.exe"
Set-ItemProperty -Path $cmdRegPath -Name "Path" -Value "C:\Windows\System32"

# 2. 确保 cmd.exe 存在
Write-Host "检查 CMD 文件..."
$cmdPath = "C:\Windows\System32\cmd.exe"
if (-Not (Test-Path $cmdPath)) {
    Write-Host "cmd.exe 丢失，尝试从备份恢复..." -ForegroundColor Yellow
    Copy-Item "C:\Windows\WinSxS\amd64_microsoft-windows-commandprompt_*\cmd.exe" -Destination "C:\Windows\System32\" -Force -ErrorAction SilentlyContinue
    if (-Not (Test-Path $cmdPath)) {
        Write-Host "恢复失败，请运行 sfc /scannow 试图修复" -ForegroundColor Red
        exit
    }
}

# 3. 检查用户环境变量 PATH（修复 CMD 无法找到问题）
Write-Host "修改环境变量..."
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($envPath -notmatch "C:\\Windows\\System32") {
    $newPath = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;" + $envPath
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "已修改系统环境变量 PATH。" -ForegroundColor Green
}

# 4. 修改 CMD 执行权限
Write-Host "修改 CMD 权限..."
icacls $cmdPath /grant Everyone:F /T /C /Q
icacls $cmdPath /grant Administrators:F /T /C /Q

# 5. 运行系统文件检查工具 SFC
Write-Host "运行系统文件检查器 (sfc /scannow)..."
sfc /scannow

# 6. 使用 DISM 修复 Windows 镜像
Write-Host "运行 DISM 修复 Windows 镜像..."
DISM /Online /Cleanup-Image /RestoreHealth

Write-Host "CMD 修复完成，请重启计算机" -ForegroundColor Green

# ============================================================================
# CMD Repair Tool (Full)
# ----------------------------------------------------------------------------
# Deep repair when CMD is broken, missing, or not on PATH.
#
# Features:
#   - Restore cmd.exe registry App Paths
#   - Restore missing cmd.exe from WinSxS backup
#   - Fix system PATH if System32 is missing
#   - Reset cmd.exe ACLs
#   - Run sfc /scannow and DISM RestoreHealth
#
# Usage: Run PowerShell as Administrator.
# ============================================================================

# Run PowerShell as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "Starting CMD repair..." -ForegroundColor Green

# 1. Fix cmd.exe registry entries
Write-Host "Updating cmd.exe registry..."
$cmdRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmd.exe"
if (-not (Test-Path $cmdRegPath)) {
    New-Item -Path $cmdRegPath -Force | Out-Null
}
Set-ItemProperty -Path $cmdRegPath -Name "(Default)" -Value "C:\Windows\System32\cmd.exe"
Set-ItemProperty -Path $cmdRegPath -Name "Path" -Value "C:\Windows\System32"

# 2. Ensure cmd.exe exists
Write-Host "Checking CMD executable..."
$cmdPath = "C:\Windows\System32\cmd.exe"
if (-Not (Test-Path $cmdPath)) {
    Write-Host "cmd.exe is missing, attempting restore from backup..." -ForegroundColor Yellow
    Copy-Item "C:\Windows\WinSxS\amd64_microsoft-windows-commandprompt_*\cmd.exe" -Destination "C:\Windows\System32\" -Force -ErrorAction SilentlyContinue
    if (-Not (Test-Path $cmdPath)) {
        Write-Host "Restore failed. Run sfc /scannow to repair system files." -ForegroundColor Red
        exit
    }
}

# 3. Fix system PATH (CMD not found issues)
Write-Host "Updating environment variables..."
$envPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($envPath -notmatch "C:\\Windows\\System32") {
    $newPath = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;" + $envPath
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "System PATH updated." -ForegroundColor Green
}

# 4. Fix CMD permissions
Write-Host "Updating CMD permissions..."
icacls $cmdPath /grant Everyone:F /T /C /Q
icacls $cmdPath /grant Administrators:F /T /C /Q

# 5. Run System File Checker
Write-Host "Running System File Checker (sfc /scannow)..."
sfc /scannow

# 6. Repair Windows image with DISM
Write-Host "Running DISM image repair..."
DISM /Online /Cleanup-Image /RestoreHealth

Write-Host "CMD repair complete. Please restart your computer." -ForegroundColor Green

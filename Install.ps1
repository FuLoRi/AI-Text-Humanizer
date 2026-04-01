<#
.SYNOPSIS
    Installs AI Text Humanizer and creates Windows shortcuts.
.DESCRIPTION
    Copies the application files to %LOCALAPPDATA%\AI-Text-Humanizer and
    creates shortcuts on the Desktop, Start Menu, or a custom location.
    No admin elevation is required.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File Install.ps1
#>

# ============================================================
# Helpers
# ============================================================

# Always use Windows PowerShell (not pwsh) for the shortcut target.
# PowerShell 7 runs on .NET 6+ which defaults to per-monitor DPI awareness,
# causing WinForms controls to render tiny on high-DPI displays.
# Windows PowerShell 5.1 on .NET Framework scales WinForms correctly.
$script:PSExePath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

function New-Shortcut {
    param(
        [string]$Path,
        [string]$TargetExe,
        [string]$Arguments,
        [string]$IconPath,
        [string]$WorkingDirectory
    )
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($Path)
    $sc.TargetPath = $TargetExe
    $sc.Arguments = $Arguments
    $sc.IconLocation = "$IconPath, 0"
    $sc.WorkingDirectory = $WorkingDirectory
    $sc.Save()
}

# ============================================================
# Main
# ============================================================

Write-Host ""
Write-Host "  AI Text Humanizer - Installer" -ForegroundColor Cyan
Write-Host "  =============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Shortcuts will use: Windows PowerShell" -ForegroundColor Gray
Write-Host ""

# Install directory
$installDir = Join-Path $env:LOCALAPPDATA 'AI-Text-Humanizer'
$sourceDir = $PSScriptRoot

# Verify source files exist
$requiredFiles = @('AI-Text-Humanizer.ps1', 'icon.ico', 'Uninstall.ps1')
foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path $sourceDir $file))) {
        Write-Host "  ERROR: $file not found in $sourceDir" -ForegroundColor Red
        Write-Host "  Make sure all files are extracted from the zip." -ForegroundColor Red
        Write-Host ""
        Read-Host "  Press Enter to close"
        exit 1
    }
}

# Copy files
Write-Host "  Installing to: $installDir" -ForegroundColor Yellow
Write-Host ""

try {
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }
    foreach ($file in $requiredFiles) {
        Copy-Item (Join-Path $sourceDir $file) -Destination $installDir -Force
    }
    Write-Host "  Files copied." -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to copy files - $_" -ForegroundColor Red
    Read-Host "  Press Enter to close"
    exit 1
}

# ============================================================
# Shortcut placement menu
# ============================================================

$desktop    = $true
$startMenu  = $true
$customPath = $null

Write-Host ""
Write-Host "  Where should shortcuts be created?" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    $d = if ($desktop)   { 'X' } else { ' ' }
    $s = if ($startMenu) { 'X' } else { ' ' }
    $c = if ($customPath) { 'X' } else { ' ' }

    Write-Host "    [$d] 1. Desktop"
    Write-Host "    [$s] 2. Start Menu"
    Write-Host "    [$c] 3. Custom path$(if ($customPath) { " ($customPath)" })"
    Write-Host ""
    $choice = Read-Host "  Toggle an option (1-3) or press Enter to continue"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        if (-not $desktop -and -not $startMenu -and -not $customPath) {
            Write-Host "  Please select at least one location." -ForegroundColor Yellow
            Write-Host ""
            continue
        }
        break
    }

    switch ($choice.Trim()) {
        '1' { $desktop = -not $desktop }
        '2' { $startMenu = -not $startMenu }
        '3' {
            if ($customPath) {
                $customPath = $null
            } else {
                $p = Read-Host "  Enter folder path"
                if ($p -and (Test-Path $p -PathType Container)) {
                    $customPath = $p
                } else {
                    Write-Host "  Folder not found. Please enter a valid path." -ForegroundColor Yellow
                }
            }
        }
        default { Write-Host "  Enter 1, 2, or 3." -ForegroundColor Yellow }
    }
    Write-Host ""
}

# ============================================================
# Create shortcuts
# ============================================================

$scriptPath = Join-Path $installDir 'AI-Text-Humanizer.ps1'
$iconPath   = Join-Path $installDir 'icon.ico'
$arguments  = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

Write-Host ""

$created = 0

if ($desktop) {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AI Text Humanizer.lnk'
    try {
        New-Shortcut -Path $lnk -TargetExe $script:PSExePath -Arguments $arguments -IconPath $iconPath -WorkingDirectory $installDir
        Write-Host "  Shortcut created: Desktop" -ForegroundColor Green
        $created++
    } catch {
        Write-Host "  ERROR: Desktop shortcut failed - $_" -ForegroundColor Red
    }
}

if ($startMenu) {
    $lnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'AI Text Humanizer.lnk'
    try {
        New-Shortcut -Path $lnk -TargetExe $script:PSExePath -Arguments $arguments -IconPath $iconPath -WorkingDirectory $installDir
        Write-Host "  Shortcut created: Start Menu" -ForegroundColor Green
        $created++
    } catch {
        Write-Host "  ERROR: Start Menu shortcut failed - $_" -ForegroundColor Red
    }
}

if ($customPath) {
    $lnk = Join-Path $customPath 'AI Text Humanizer.lnk'
    try {
        New-Shortcut -Path $lnk -TargetExe $script:PSExePath -Arguments $arguments -IconPath $iconPath -WorkingDirectory $installDir
        Write-Host "  Shortcut created: $customPath" -ForegroundColor Green
        $created++
    } catch {
        Write-Host "  ERROR: Custom shortcut failed - $_" -ForegroundColor Red
    }
}

# ============================================================
# Done
# ============================================================

Write-Host ""
if ($created -gt 0) {
    Write-Host "  Installation complete! ($created shortcut(s) created)" -ForegroundColor Green
} else {
    Write-Host "  Files installed but no shortcuts were created." -ForegroundColor Yellow
}
Write-Host "  Install directory: $installDir" -ForegroundColor Gray
Write-Host "  To uninstall, run Uninstall.ps1 from that directory." -ForegroundColor Gray
Write-Host ""
Read-Host "  Press Enter to close"

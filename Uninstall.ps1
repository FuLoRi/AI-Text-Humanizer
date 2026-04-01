<#
.SYNOPSIS
    Uninstalls AI Text Humanizer.
.DESCRIPTION
    Removes shortcuts from Desktop and Start Menu, then deletes
    the install directory at %LOCALAPPDATA%\AI-Text-Humanizer.
#>

Write-Host ""
Write-Host "  AI Text Humanizer - Uninstaller" -ForegroundColor Cyan
Write-Host "  ================================" -ForegroundColor Cyan
Write-Host ""

$installDir = Join-Path $env:LOCALAPPDATA 'AI-Text-Humanizer'

if (-not (Test-Path $installDir)) {
    Write-Host "  Nothing to uninstall. Directory not found:" -ForegroundColor Yellow
    Write-Host "  $installDir" -ForegroundColor Gray
    Write-Host ""
    Read-Host "  Press Enter to close"
    exit 0
}

# Remove shortcuts
$locations = @(
    @{ Name = 'Desktop';    Path = Join-Path ([Environment]::GetFolderPath('Desktop'))  'AI Text Humanizer.lnk' }
    @{ Name = 'Start Menu'; Path = Join-Path ([Environment]::GetFolderPath('Programs')) 'AI Text Humanizer.lnk' }
)

foreach ($loc in $locations) {
    if (Test-Path $loc.Path) {
        Remove-Item $loc.Path -Force
        Write-Host "  Removed shortcut: $($loc.Name)" -ForegroundColor Green
    }
}

# Remove install directory
try {
    Remove-Item $installDir -Recurse -Force
    Write-Host "  Removed directory: $installDir" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Could not remove directory - $_" -ForegroundColor Red
    Write-Host "  You may need to delete it manually." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Uninstall complete." -ForegroundColor Green
Write-Host "  If you created shortcuts in a custom location, delete those manually." -ForegroundColor Gray
Write-Host ""
Read-Host "  Press Enter to close"

<#
.SYNOPSIS
    Generates icon.ico for AI Text Humanizer.
.DESCRIPTION
    Creates a "no AI" icon: red prohibition circle with black "AI" text
    on white background. Produces 32x32 and 16x16 sizes in ICO format.
    Run under powershell.exe (Windows PowerShell 5.1), not pwsh.
.EXAMPLE
    powershell -File New-Icon.ps1
#>

Add-Type -AssemblyName System.Drawing

function New-ProhibitionIcon ([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::White)

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 38, 38)), ([math]::Max(2, [int]($size * 0.12)))
    $pen.Alignment = 'Center'

    # Circle inset so the thick pen doesn't clip
    $inset = [int]($pen.Width / 2) + 1
    $rect = New-Object System.Drawing.Rectangle $inset, $inset, ($size - 2 * $inset), ($size - 2 * $inset)
    $g.DrawEllipse($pen, $rect)

    # "AI" text
    $fontSize = [math]::Max(6, [int]($size * 0.32))
    $font = New-Object System.Drawing.Font 'Arial', $fontSize, ([System.Drawing.FontStyle]::Bold)
    $brush = [System.Drawing.Brushes]::Black
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'
    $sf.LineAlignment = 'Center'
    $textRect = New-Object System.Drawing.RectangleF 0, 0, $size, $size
    $g.DrawString('AI', $font, $brush, $textRect, $sf)

    # Diagonal slash (top-right to bottom-left)
    $cx = $size / 2.0
    $cy = $size / 2.0
    $r = ($size - 2 * $inset) / 2.0
    $angle = 135 * [math]::PI / 180
    $x1 = $cx + $r * [math]::Cos($angle)
    $y1 = $cy - $r * [math]::Sin($angle)
    $x2 = $cx - $r * [math]::Cos($angle)
    $y2 = $cy + $r * [math]::Sin($angle)
    $g.DrawLine($pen, [float]$x1, [float]$y1, [float]$x2, [float]$y2)

    $g.Dispose()
    $font.Dispose()
    $pen.Dispose()
    return $bmp
}

function Save-Ico ([System.Drawing.Bitmap[]]$images, [string]$path) {
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter $ms

    # ICO header: reserved(2) + type(2) + count(2)
    $bw.Write([uint16]0)
    $bw.Write([uint16]1)          # 1 = icon
    $bw.Write([uint16]$images.Count)

    # Collect PNG data for each image
    $pngStreams = @()
    foreach ($img in $images) {
        $pngMs = New-Object System.IO.MemoryStream
        $img.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngStreams += $pngMs
    }

    # Directory entries (16 bytes each)
    $dataOffset = 6 + ($images.Count * 16)
    for ($i = 0; $i -lt $images.Count; $i++) {
        $w = $images[$i].Width
        $h = $images[$i].Height
        $bw.Write([byte]$(if ($w -ge 256) { 0 } else { $w }))
        $bw.Write([byte]$(if ($h -ge 256) { 0 } else { $h }))
        $bw.Write([byte]0)        # color palette
        $bw.Write([byte]0)        # reserved
        $bw.Write([uint16]1)      # color planes
        $bw.Write([uint16]32)     # bits per pixel
        $bw.Write([uint32]$pngStreams[$i].Length)
        $bw.Write([uint32]$dataOffset)
        $dataOffset += $pngStreams[$i].Length
    }

    # Image data
    foreach ($pngMs in $pngStreams) {
        $bw.Write($pngMs.ToArray())
        $pngMs.Dispose()
    }

    [System.IO.File]::WriteAllBytes($path, $ms.ToArray())
    $bw.Dispose()
    $ms.Dispose()
}

# Generate and save
$icon32 = New-ProhibitionIcon 32
$icon16 = New-ProhibitionIcon 16

$outPath = Join-Path $PSScriptRoot 'icon.ico'
Save-Ico -images @($icon32, $icon16) -path $outPath

$icon32.Dispose()
$icon16.Dispose()

Write-Host "Created $outPath" -ForegroundColor Green

# Mirrors gamemodes/swgrp/materials into gamemodes/swgrp/content/materials
# and generates menu logo.png + icon24.png from server.png at correct sizes.
#
# GMod requires:
#   icon24.png  - 24x24 to 32x32 (gamemode picker + server list)
#   logo.png    - 128px tall banner (default 288x128)

$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root "materials"
$dst = Join-Path $root "content\materials"

if (-not (Test-Path $src)) {
	Write-Host "No materials folder at: $src"
	exit 1
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force
Write-Host "Synced materials -> content/materials"
Write-Host "  from: $src"
Write-Host "  to:   $dst"

$iconCandidates = @(
	Join-Path $src "server.png"
	Join-Path $src "swgrp\server.png"
	Join-Path $dst "server.png"
	Join-Path $dst "swgrp\server.png"
)

$iconSrc = $null
foreach ($path in $iconCandidates) {
	if (Test-Path $path) {
		$iconSrc = $path
		break
	}
}

if (-not $iconSrc) {
	Write-Host "No server.png found for gamemode menu icon."
	exit 0
}

Add-Type -AssemblyName System.Drawing

function Resize-Png {
	param(
		[string]$SourcePath,
		[string]$DestPath,
		[int]$Width,
		[int]$Height
	)

	$srcImg = [System.Drawing.Image]::FromFile($SourcePath)
	$bmp = New-Object System.Drawing.Bitmap $Width, $Height
	$bmp.SetResolution($srcImg.HorizontalResolution, $srcImg.VerticalResolution)

	$graphics = [System.Drawing.Graphics]::FromImage($bmp)
	$graphics.Clear([System.Drawing.Color]::Transparent)
	$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
	$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
	$graphics.DrawImage($srcImg, 0, 0, $Width, $Height)
	$graphics.Dispose()

	$bmp.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
	$bmp.Dispose()
	$srcImg.Dispose()
}

$logo = Join-Path $root "logo.png"
$icon24 = Join-Path $root "icon24.png"

# Gamemode sidebar icon (32x32 in picker)
Resize-Png -SourcePath $iconSrc -DestPath $icon24 -Width 32 -Height 32

# Menu banner: 128px tall, width scaled (288 minimum like default GMod logos)
$sourceImg = [System.Drawing.Image]::FromFile($iconSrc)
$logoHeight = 128
$logoWidth = [int][Math]::Round(($sourceImg.Width / $sourceImg.Height) * $logoHeight)
if ($logoWidth -lt 288) { $logoWidth = 288 }
if ($logoWidth -gt 1024) { $logoWidth = 1024 }
$sourceImg.Dispose()

Resize-Png -SourcePath $iconSrc -DestPath $logo -Width $logoWidth -Height $logoHeight

Write-Host "Gamemode menu assets generated from server.png:"
Write-Host "  icon24.png  (32x32)  -> $icon24"
Write-Host "  logo.png    ($logoWidth x $logoHeight) -> $logo"
Write-Host "Restart GMod or return to main menu to refresh the gamemode icon."

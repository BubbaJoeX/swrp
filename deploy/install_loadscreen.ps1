# Copies the Galaxies RP loading screen into garrysmod/html/swgrp/
# Run from anywhere. Pass -GmodRoot if auto-detection fails.

param(
	[string]$GmodRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
)

$source = Join-Path $PSScriptRoot "..\loadscreen\index.html"
$targetDir = Join-Path $GmodRoot "html\swgrp"
$target = Join-Path $targetDir "loadscreen.html"

if (-not (Test-Path $source)) {
	Write-Error "Source file not found: $source"
	exit 1
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -Force $source $target

Write-Host "Installed loading screen to:"
Write-Host "  $target"
Write-Host ""
Write-Host "Add to cfg/server.cfg (if not already set):"
Write-Host '  sv_loadingurl "asset://garrysmod/html/swgrp/loadscreen.html"'

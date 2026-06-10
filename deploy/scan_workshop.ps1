# Scan subscribed Workshop addons against SWGRP CSV/Lua references.
# Usage: .\deploy\scan_workshop.ps1
#        .\deploy\scan_workshop.ps1 -GmaDir "D:\path\to\gma\folder"

param(
	[string]$GmaDir = (Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\workshop\content\4000"),
	[string]$JsonOut = ""
)

$root = Split-Path $PSScriptRoot -Parent
$py = Join-Path $root "tools\scan_gma_assets.py"

if (-not (Test-Path $py)) {
	Write-Error "Missing $py"
	exit 1
}

if (-not (Test-Path $GmaDir)) {
	Write-Host "Workshop folder not found: $GmaDir"
	Write-Host "Pass -GmaDir pointing at a folder that contains .gma files."
	exit 1
}

$args = @($py, "--gma-dir", $GmaDir, "--root", $root)
if ($JsonOut -ne "") {
	$args += @("--json", $JsonOut)
}

& python @args
exit $LASTEXITCODE

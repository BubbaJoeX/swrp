--[[---------------------------------------------------------------------------
    Register gamemode assets for client download.

    Scans:
      gamemodes/<gm>/content/   → virtual paths (materials/, models/, sound/, ...)
      gamemodes/<gm>/materials/ → materials/<relative path>

    Run deploy/sync_materials.ps1 to mirror materials/ into content/materials/
    for local Material() resolution on listen servers without FastDL.
---------------------------------------------------------------------------]]

if not SERVER then return end

SWGRP = SWGRP or {}
SWGRP.Resources = SWGRP.Resources or {}

local R = SWGRP.Resources
local gmFolder = GM.FolderName or "swgrp"
local gmRoot = "gamemodes/" .. gmFolder

R._registered = R._registered or {}

local SEND_EXTS = {
	".vmt", ".png", ".jpg", ".jpeg", ".vtf",
	".mdl", ".wav", ".mp3", ".ogg",
}

local function ShouldSend( filename )
	local lower = string.lower( filename )
	for _, ext in ipairs( SEND_EXTS ) do
		if string.EndsWith( lower, ext ) then return true end
	end
	return false
end

local function AddVirtual( virtualPath )
	if R._registered[virtualPath] then return end
	if not file.Exists( virtualPath, "GAME" ) then return end

	resource.AddFile( virtualPath )
	R._registered[virtualPath] = true
end

local function ScanTree( gameDir, virtualPrefix )
	local files, folders = file.Find( gameDir .. "/*", "GAME" )
	if not files then return 0 end

	local count = 0
	for _, f in ipairs( files ) do
		if ShouldSend( f ) then
			AddVirtual( virtualPrefix .. f )
			count = count + 1
		end
	end

	for _, sub in ipairs( folders or {} ) do
		if sub ~= "." and sub ~= ".." and sub ~= ".svn" then
			count = count + ScanTree( gameDir .. "/" .. sub, virtualPrefix .. sub .. "/" )
		end
	end

	return count
end

function R.RegisterGamemodeAssets()
	local contentRoot = gmRoot .. "/content"
	local materialsRoot = gmRoot .. "/materials"
	local total = 0

	if file.Exists( contentRoot, "GAME" ) then
		total = total + ScanTree( contentRoot, "" )
	end

	if file.Exists( materialsRoot, "GAME" ) then
		total = total + ScanTree( materialsRoot, "materials/" )
	end

	if total > 0 then
		print( string.format(
			"[SWGRP] Registered %d gamemode asset file(s) for client download (%d unique).",
			total,
			table.Count( R._registered )
		) )
	else
		print( "[SWGRP] No gamemode assets found under content/ or materials/." )
	end

	if file.Exists( materialsRoot, "GAME" ) and not file.Exists( contentRoot .. "/materials", "GAME" ) then
		print( "[SWGRP] Tip: run deploy/sync_materials.ps1 to mirror materials/ into content/materials/ for local previews." )
	end

	local logoPath = gmRoot .. "/logo.png"
	local iconPath = gmRoot .. "/icon24.png"
	if not file.Exists( logoPath, "GAME" ) or not file.Exists( iconPath, "GAME" ) then
		print( "[SWGRP] Tip: run deploy/sync_materials.ps1 to generate logo.png and icon24.png from materials/server.png." )
	end

	if not file.Exists( "html/swgrp/loadscreen.html", "GAME" ) then
		print( "[SWGRP] Tip: run deploy/install_loadscreen.ps1 so joining clients can download the loading screen HTML." )
	end
end

R.RegisterGamemodeAssets()

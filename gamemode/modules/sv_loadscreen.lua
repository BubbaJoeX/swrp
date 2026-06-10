--[[---------------------------------------------------------------------------
    Loading Screen — dedicated server bootstrap
---------------------------------------------------------------------------]]

if not SERVER then return end

local ASSET_FILE = "html/swgrp/loadscreen.html"
local ASSET_URL  = "asset://garrysmod/html/swgrp/loadscreen.html"

-- Register for FastDL / client cache when using a local asset URL.
if file.Exists( ASSET_FILE, "GAME" ) then
	resource.AddFile( ASSET_FILE )
end

hook.Add( "Initialize", "SWGRP_LoadingScreen", function()
	-- Respect an explicit URL set in server.cfg; only apply the default asset
	-- path when the admin has not configured one yet.
	local current = GetConVar( "sv_loadingurl" ):GetString() or ""
	if current ~= "" and current ~= "about:blank" then return end

	if file.Exists( ASSET_FILE, "GAME" ) then
		RunConsoleCommand( "sv_loadingurl", ASSET_URL )
		print( "[SWGRP] Loading screen: " .. ASSET_URL )
	else
		print( "[SWGRP] Loading screen HTML not found at " .. ASSET_FILE )
		print( "[SWGRP] Run deploy/install_loadscreen.ps1 or set sv_loadingurl in server.cfg" )
	end
end )

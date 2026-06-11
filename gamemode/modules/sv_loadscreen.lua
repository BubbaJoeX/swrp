--[[---------------------------------------------------------------------------
    Loading Screen — server bootstrap + FastDL registration
---------------------------------------------------------------------------]]

if not SERVER then return end

SWGRP = SWGRP or {}
SWGRP.Loadscreen = SWGRP.Loadscreen or {}

local L = SWGRP.Loadscreen

L.GAMEMODE_FILE = "gamemodes/swgrp/loadscreen/index.html"
L.HTML_FILE     = "html/swgrp/loadscreen.html"
L.URL_GAMEMODE  = "asset://garrysmod/gamemodes/swgrp/loadscreen/index.html"
L.URL_HTML      = "asset://garrysmod/html/swgrp/loadscreen.html"

function L.ResolveURL()
	if file.Exists( L.HTML_FILE, "GAME" ) then
		return L.URL_HTML
	end

	if file.Exists( L.GAMEMODE_FILE, "GAME" ) then
		return L.URL_GAMEMODE
	end

	return L.URL_HTML
end

local function registerFiles()
	if file.Exists( L.HTML_FILE, "GAME" ) then
		resource.AddFile( L.HTML_FILE )
	end

	if file.Exists( L.GAMEMODE_FILE, "GAME" ) then
		resource.AddFile( L.GAMEMODE_FILE )
	end

	local logos = {
		"materials/server.png",
		"materials/swgrp/server.png",
	}

	for _, path in ipairs( logos ) do
		if file.Exists( path, "GAME" ) then
			resource.AddFile( path )
		end
	end
end

local function applyLoadingURL()
	local current = GetConVar( "sv_loadingurl" ):GetString() or ""
	if current ~= "" and current ~= "about:blank" then return false end

	if file.Exists( L.HTML_FILE, "GAME" ) or file.Exists( L.GAMEMODE_FILE, "GAME" ) then
		local url = L.ResolveURL()
		RunConsoleCommand( "sv_loadingurl", url )
		print( "[SWGRP] Loading screen: " .. url )
		return true
	end

	print( "[SWGRP] Loading screen HTML not found." )
	print( "[SWGRP] Run deploy/install_loadscreen.ps1 or set sv_loadingurl in server.cfg" )
	return false
end

registerFiles()
applyLoadingURL()

hook.Add( "Initialize", "SWGRP_LoadingScreen", applyLoadingURL )

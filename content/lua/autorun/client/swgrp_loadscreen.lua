--[[---------------------------------------------------------------------------
    Menu loading screen hook — singleplayer + local fallback

    GMod only loads sv_loadingurl when maxplayers > 1. This patches the menu
    loading panel so Galaxies RP always shows our asset page when hosting SP
    or when the server URL already points at swgrp assets.
---------------------------------------------------------------------------]]

if not CLIENT then return end

local GM_NAME = "swgrp"

local FILE_CANDIDATES = {
	"html/swgrp/loadscreen.html",
	"gamemodes/swgrp/loadscreen/index.html",
}

local URL_CANDIDATES = {
	"asset://garrysmod/html/swgrp/loadscreen.html",
	"asset://garrysmod/gamemodes/swgrp/loadscreen/index.html",
}

local function resolveLoadscreenURL()
	for i, path in ipairs( FILE_CANDIDATES ) do
		if file.Exists( path, "GAME" ) then
			return URL_CANDIDATES[i]
		end
	end

	return URL_CANDIDATES[2]
end

local function isSwgrpSession( gamemode, serverurl )
	if gamemode == GM_NAME then return true end

	if IsHostingGame() and GetConVarString( "gamemode" ) == GM_NAME then
		return true
	end

	if serverurl and serverurl:find( "swgrp", 1, true ) then
		return true
	end

	return false
end

local function loadingURLAllowed( url )
	if not GetConVar( "cl_enable_loadingurl" ):GetBool() then return false end
	if not url or url == "" then return false end

	return url:StartsWith( "http" ) or url:StartsWith( "asset://" )
end

local function showCustomLoadscreen( force )
	local url = resolveLoadscreenURL()
	if not loadingURLAllowed( url ) then return end

	if not GetLoadPanel then return end
	local pnl = GetLoadPanel()
	if not IsValid( pnl ) then return end

	pnl:ShowURL( url, force )
end

local function patchGameDetails()
	if not GameDetails or GameDetails._SWGRP_Loadscreen then return true end

	local OldGameDetails = GameDetails

	function GameDetails( servername, serverurl, mapname, maxplayers, maxplayers_visible, steamid, gamemode )
		if engine.IsPlayingDemo() then return end

		if isSwgrpSession( gamemode, serverurl ) then
			local loadUrl = resolveLoadscreenURL()
			showCustomLoadscreen( true )
			serverurl = loadUrl
		end

		OldGameDetails( servername, serverurl, mapname, maxplayers, maxplayers_visible, steamid, gamemode )
	end

	GameDetails._SWGRP_Loadscreen = true
	return true
end

local function patchLoadingPanel()
	if not GetLoadPanel then return false end

	local pnl = GetLoadPanel()
	if not IsValid( pnl ) or pnl._SWGRP_Loadscreen then return true end

	local oldOnActivate = pnl.OnActivate
	pnl.OnActivate = function( self )
		if oldOnActivate then
			oldOnActivate( self )
		end

		if isSwgrpSession( GetConVarString( "gamemode" ), nil ) then
			showCustomLoadscreen( true )
		end
	end

	pnl._SWGRP_Loadscreen = true
	return true
end

hook.Add( "Think", "SWGRP_LoadscreenMenu", function()
	if patchGameDetails() and patchLoadingPanel() then
		hook.Remove( "Think", "SWGRP_LoadscreenMenu" )
	end
end )

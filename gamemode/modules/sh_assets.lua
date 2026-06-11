--[[---------------------------------------------------------------------------
    Gamemode UI assets (materials under gamemodes/swgrp/materials or content/)

    Place files in either:
      gamemodes/swgrp/materials/...        → mounted as materials/...
      gamemodes/swgrp/content/materials/... → same virtual path

    Scoreboard colony logo: materials/swgrp/server.png (+ optional .vmt)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Assets = SWGRP.Assets or {}

local A = SWGRP.Assets

A.LogoCandidates = {
	"server",
	"swgrp/server",
	"swgrp/logo",
}

-- GMod main-menu assets (filesystem, not Material paths)
A.GamemodeMenuLogo = "gamemodes/swgrp/logo.png"
A.GamemodeMenuIcon = "gamemodes/swgrp/icon24.png"

A.FAdminBack = "fadmin/back"

function A.IsGuiPath( path )
	return path and string.sub( path, 1, 4 ) == "gui/"
end

function A.GetScoreboardLogoPath()
	if A._scoreboardLogo then return A._scoreboardLogo end

	if CLIENT then
		for _, path in ipairs( A.LogoCandidates ) do
			local mat = Material( path, "smooth mips" )
			if mat and not mat:IsError() then
				A._scoreboardLogo = path
				return path
			end
		end
	end

	A._scoreboardLogo = "gui/gmod_logo"
	return A._scoreboardLogo
end

function A.Material( path, flags )
	flags = flags or "smooth mips"
	local mat = Material( path, flags )
	if mat:IsError() then
		return Material( "icon16/error", flags )
	end
	return mat
end

function A.FAdminIcon( name )
	return "fadmin/icons/" .. name
end

A.IconFallbacks = {
	["fadmin/icons/voicemute"] = "icon16/sound_mute",
	["fadmin/icons/chatmute"] = "icon16/comment_delete",
	["fadmin/icons/noclip"] = "icon16/arrow_out",
	["fadmin/icons/disable"] = "icon16/cross",
	["fadmin/icons/god"] = "icon16/shield",
	["fadmin/icons/freeze"] = "icon16/lock",
	["fadmin/icons/jail"] = "icon16/lock",
	["fadmin/icons/weapon"] = "icon16/gun",
	["fadmin/icons/teleport"] = "icon16/arrow_out",
	["fadmin/icons/kick"] = "icon16/door_out",
	["fadmin/icons/ban"] = "icon16/delete",
	["fadmin/icons/slay"] = "icon16/bomb",
	["fadmin/icons/slap"] = "icon16/arrow_refresh",
	["fadmin/icons/message"] = "icon16/email",
	["fadmin/icons/ignite"] = "icon16/fire",
	["fadmin/icons/cloak"] = "icon16/eye",
	["fadmin/icons/ragdoll"] = "icon16/user",
	["fadmin/icons/changeteam"] = "icon16/group",
	["fadmin/icons/access"] = "icon16/key",
	["fadmin/icons/cleanup"] = "icon16/brush",
	["fadmin/icons/rcon"] = "icon16/computer",
	["fadmin/icons/motd"] = "icon16/page_white",
	["fadmin/icons/serversetting"] = "icon16/cog",
	["fadmin/icons/pickup"] = "icon16/hand",
	["fadmin/back"] = "icon16/arrow_left",
}

function A.ResolveIconPath( path )
	if not path or path == "" then return "icon16/error" end
	if string.sub( path, 1, 7 ) == "icon16/" or string.sub( path, 1, 4 ) == "vgui/" then
		return path
	end

	if CLIENT then
		local mat = Material( path, "smooth mips" )
		if mat and not mat:IsError() then return path end
	end

	return A.IconFallbacks[path] or "icon16/error"
end

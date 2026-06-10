--[[---------------------------------------------------------------------------
    Star Wars Galaxies Roleplay - Shared
    A DarkRP-inspired gamemode set in the Star Wars universe.
---------------------------------------------------------------------------]]

DeriveGamemode( "sandbox" )
DEFINE_BASECLASS( "gamemode_sandbox" )
GM.Sandbox = BaseClass

GM.Name     = "Star Wars Galaxies RP"
GM.Author   = "SWGRP Development"
GM.Email    = "N/A"
GM.Website  = "N/A"
GM.IsSWGRPDerived = true

-- Core libraries
include( "config/sh_config.lua" )
include( "libraries/sh_cami.lua" )
-- DarkRP/FAdmin support libraries (fn must load before tablecheck, both before FAdmin)
include( "libraries/falib/fn.lua" )
include( "libraries/falib/tablecheck.lua" )
include( "libraries/sh_swgrp.lua" )
include( "libraries/sh_modelmap.lua" )
include( "modules/sh_doors.lua" )
include( "libraries/sh_util.lua" )
include( "libraries/sh_player.lua" )
include( "libraries/sh_fadmin_compat.lua" )
include( "modules/fadmin/sh_fadmin_darkrp.lua" )
include( "libraries/sh_network.lua" )
include( "libraries/sh_hooks.lua" )
include( "libraries/sh_fadmin.lua" )
include( "libraries/sh_admin.lua" )
include( "language/sh_english.lua" )
include( "player_class/player_swgrp.lua" )

-- Content registration (shared)
include( "modules/sh_categories.lua" )
include( "modules/sh_allegiances.lua" )
include( "libraries/sh_content_loader.lua" )
SWGRP.Content.LoadAll()
include( "modules/sh_doorgroups.lua" )
include( "modules/sh_recipes.lua" )
include( "modules/sh_missions.lua" )
include( "modules/sh_contraband.lua" )
include( "modules/sh_spawnallowlist.lua" )

-- Custom extensions (add professions, entities, etc. without editing core)
local customFiles = file.Find( "custom/*.lua", "LUA" )
for _, f in ipairs( customFiles ) do
	if not string.find( f, "example" ) then
		include( "custom/" .. f )
	end
end

function GM:Initialize()
	if SERVER then
		SWGRP.DB.Initialize()
		if SWGRP.Persistence and SWGRP.Persistence.LoadWorld then
			SWGRP.Persistence.LoadWorld()
		end
		print( "[SWGRP] Star Wars Galaxies Roleplay initialized." )
	end
end

function GM:CanPlayerSuicide( ply )
	if ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then return false end
	return true
end

function GM:PlayerShouldTakeDamage( victim, attacker )
	if victim:SWGRP_IsArrested() then return false end
	return true
end

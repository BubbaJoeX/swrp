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

-- Dedicated clients only receive Lua via AddCSLuaFile under swgrp/gamemode/...
-- (same path style as bundled FAdmin). Short gamemode-relative includes fail on join.
local GM_ROOT = GM.FolderName .. "/gamemode/"
local function Inc( path )
	include( GM_ROOT .. path )
end

-- Core libraries
Inc( "config/sh_config.lua" )
Inc( "libraries/sh_cami.lua" )
-- DarkRP/FAdmin support libraries (fn must load before tablecheck, both before FAdmin)
Inc( "libraries/falib/fn.lua" )
Inc( "libraries/falib/tablecheck.lua" )
Inc( "libraries/sh_swgrp.lua" )
Inc( "libraries/sh_modelmap.lua" )
Inc( "modules/sh_doors.lua" )
Inc( "libraries/sh_util.lua" )
Inc( "modules/sh_materials.lua" )
Inc( "libraries/sh_player.lua" )
Inc( "libraries/sh_fadmin_compat.lua" )
Inc( "modules/fadmin/sh_fadmin_darkrp.lua" )
Inc( "libraries/sh_network.lua" )
Inc( "libraries/sh_hooks.lua" )
Inc( "libraries/sh_fadmin.lua" )
Inc( "libraries/sh_admin.lua" )
Inc( "language/sh_english.lua" )
Inc( "player_class/player_swgrp.lua" )

-- Content registration (shared)
Inc( "modules/sh_categories.lua" )
Inc( "modules/sh_allegiances.lua" )
Inc( "modules/sh_vehicles.lua" )
Inc( "libraries/sh_entity_loader.lua" )
SWGRP.EntityLoader.LoadAll()

Inc( "libraries/sh_content_loader.lua" )
SWGRP.Content.LoadAll()
Inc( "modules/sh_ammo.lua" )
SWGRP.Ammo.PatchWeaponTables()
Inc( "modules/sh_doorgroups.lua" )
Inc( "modules/sh_recipes.lua" )
Inc( "modules/sh_missions.lua" )
Inc( "modules/sh_contraband.lua" )
Inc( "modules/sh_spawnallowlist.lua" )
Inc( "modules/sh_mountoffset.lua" )

-- Custom extensions (add professions, entities, etc. without editing core)
local customRoot = GM.FolderName .. "/gamemode/custom/"
local customFiles = file.Find( customRoot .. "*.lua", "LUA" )
for _, f in ipairs( customFiles ) do
	if not string.find( f, "example" ) then
		include( customRoot .. f )
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

--[[---------------------------------------------------------------------------
    SWGRP Server Initialization
---------------------------------------------------------------------------]]

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

local function AddCSLuaFiles( path )
	local files, dirs = file.Find( path .. "/*", "LUA" )
	for _, f in ipairs( files ) do
		if string.EndsWith( f, ".lua" ) then
			AddCSLuaFile( path .. "/" .. f )
		end
	end
	for _, d in ipairs( dirs ) do
		AddCSLuaFiles( path .. "/" .. d )
	end
end

AddCSLuaFile( "libraries/sh_cami.lua" )
AddCSLuaFile( "libraries/sh_fadmin_compat.lua" )
AddCSLuaFile( "modules/fadmin/sh_fadmin_darkrp.lua" )

AddCSLuaFiles( "config" )
AddCSLuaFiles( "libraries" )
AddCSLuaFiles( "modules" )
AddCSLuaFiles( "language" )
AddCSLuaFiles( "vgui" )

include( "shared.lua" )

include( "libraries/mysqlite/mysqlite.lua" )
include( "libraries/sv_fadmin_compat.lua" )
include( "modules/fadmin/sv_fadmin.lua" )
include( "modules/fadmin/sv_fadmin_sql.lua" )
include( "modules/fadmin/sv_fadmin_swgrp.lua" )

-- Server modules
include( "modules/sv_logging.lua" )
include( "libraries/sv_database.lua" )
include( "modules/sv_persistence.lua" )
include( "modules/sv_economy.lua" )
include( "modules/sv_doors.lua" )
include( "modules/sv_government.lua" )
include( "modules/sv_police.lua" )
include( "modules/sv_hitman.lua" )
include( "modules/sv_chat.lua" )
include( "modules/sh_chatcommands.lua" )
include( "modules/sv_jobs.lua" )
include( "modules/sv_demote.lua" )
include( "modules/sv_afk.lua" )
include( "modules/sv_spawn.lua" )
include( "modules/sv_props.lua" )
include( "modules/sv_spawnmenu.lua" )
include( "modules/sv_medic.lua" )
include( "modules/sv_banking.lua" )
include( "modules/sv_hunger.lua" )
include( "modules/sv_factions.lua" )
include( "modules/sv_profession.lua" )
include( "modules/sv_materials.lua" )
include( "modules/sv_crafting.lua" )
include( "modules/sv_missions.lua" )
include( "modules/sv_contraband.lua" )
include( "modules/sv_vehicles.lua" )
include( "modules/sv_lockpick.lua" )
include( "modules/sv_restraint.lua" )
include( "modules/sv_pocket.lua" )
include( "modules/sv_voteban.lua" )
include( "modules/sv_advert.lua" )
include( "modules/sv_nlr.lua" )
include( "modules/sv_whitelist.lua" )
include( "modules/sv_net.lua" )

-- SWGRP stores everything in SQLite; disable MySQL so FAdmin's bundled MySQLite
-- falls back to the local SQLite database instead of erroring on a missing config.
MySQLite.initialize( { EnableMySQL = false } )

print( "[SWGRP] Server modules loaded." )

--[[---------------------------------------------------------------------------
    SWGRP Server Initialization
---------------------------------------------------------------------------]]

local gmFolder = GM.FolderName or "swgrp"
local gmDiskRoot = "gamemodes/" .. gmFolder .. "/gamemode"
local gmLuaRoot = gmFolder .. "/gamemode"

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( gmLuaRoot .. "/cl_init.lua" )
AddCSLuaFile( gmLuaRoot .. "/shared.lua" )

-- Register client/shared scripts for connecting players.
-- Paths must match include() in shared.lua / cl_init.lua: swgrp/gamemode/...
-- file.Find(..., "LUA") with relative paths is unreliable on Linux srcds; scan GAME.
local csLuaCount = 0

local function ShouldSendToClient( relPath )
	local name = string.GetFileFromFilename( relPath )
	return string.sub( name, 1, 3 ) ~= "sv_"
end

local function AddCSLuaFilesDir( subdir )
	local diskPath = gmDiskRoot .. "/" .. subdir
	local files, dirs = file.Find( diskPath .. "/*", "GAME" )
	if not files then
		ErrorNoHalt( "[SWGRP] AddCSLuaFiles: cannot read " .. diskPath .. " (check path and permissions)\n" )
		return
	end

	for _, f in ipairs( files ) do
		if string.EndsWith( f, ".lua" ) then
			local rel = subdir .. "/" .. f
			if ShouldSendToClient( rel ) then
				AddCSLuaFile( gmLuaRoot .. "/" .. rel )
				csLuaCount = csLuaCount + 1
			end
		end
	end

	for _, d in ipairs( dirs or {} ) do
		if d ~= "." and d ~= ".." then
			AddCSLuaFilesDir( subdir .. "/" .. d )
		end
	end
end

AddCSLuaFile( gmLuaRoot .. "/libraries/sh_cami.lua" )
AddCSLuaFile( gmLuaRoot .. "/libraries/sh_fadmin_compat.lua" )
AddCSLuaFile( gmLuaRoot .. "/modules/fadmin/sh_fadmin_darkrp.lua" )
AddCSLuaFile( "libraries/sh_cami.lua" )
AddCSLuaFile( "libraries/sh_fadmin_compat.lua" )
AddCSLuaFile( "modules/fadmin/sh_fadmin_darkrp.lua" )

for _, dir in ipairs( { "config", "libraries", "modules", "language", "vgui", "player_class", "custom" } ) do
	AddCSLuaFilesDir( dir )
end

local configOnDisk = file.Find( gmDiskRoot .. "/config/*.lua", "GAME" )
print( string.format(
	"[SWGRP] AddCSLuaFile: %d scripts queued for clients (%d config files on disk)\n",
	csLuaCount,
	configOnDisk and #configOnDisk or 0
) )

if csLuaCount < 10 then
	ErrorNoHalt( "[SWGRP] WARNING: very few client scripts registered — clients will fail to load. Check gamemode path/permissions.\n" )
end

include( "shared.lua" )
include( "libraries/sv_entity_loader.lua" )

include( "libraries/mysqlite/mysqlite.lua" )
include( "libraries/sv_fadmin_compat.lua" )
include( "modules/fadmin/sv_fadmin.lua" )
include( "modules/fadmin/sv_fadmin_sql.lua" )
include( "modules/fadmin/sv_fadmin_swgrp.lua" )

-- Server modules
include( "modules/sv_logging.lua" )
include( "libraries/sv_database.lua" )
include( "modules/sv_persistence.lua" )
include( "modules/sv_props.lua" )
include( "modules/sv_loadscreen.lua" )
include( "modules/sv_economy.lua" )
include( "modules/sv_doors.lua" )
include( "modules/sv_admindoors.lua" )
include( "modules/sv_government.lua" )
include( "modules/sv_police.lua" )
include( "modules/sv_hitman.lua" )
include( "modules/sv_chat.lua" )
include( "modules/sh_chatcommands.lua" )
include( "modules/sv_jobs.lua" )
include( "modules/sv_demote.lua" )
include( "modules/sv_afk.lua" )
include( "modules/sv_spawn.lua" )
include( "modules/sv_jobspawns.lua" )
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
include( "modules/sv_admin.lua" )
include( "modules/sv_net.lua" )

-- SWGRP stores everything in SQLite; disable MySQL so FAdmin's bundled MySQLite
-- falls back to the local SQLite database instead of erroring on a missing config.
MySQLite.initialize( { EnableMySQL = false } )

print( "[SWGRP] Server modules loaded." )

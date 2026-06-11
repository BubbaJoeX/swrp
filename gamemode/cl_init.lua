--[[---------------------------------------------------------------------------
    SWGRP Client Initialization
---------------------------------------------------------------------------]]

local GM_ROOT = GM.FolderName .. "/gamemode/"
local function Inc( path )
	include( GM_ROOT .. path )
end

Inc( "shared.lua" )

Inc( "modules/fadmin/cl_fadmin.lua" )
Inc( "modules/fadmin/cl_fadmin_swgrp.lua" )

Inc( "vgui/swgrp_terminal.lua" )
Inc( "modules/cl_assets.lua" )
Inc( "modules/cl_ui_skin.lua" )
Inc( "modules/cl_spawnmenu.lua" )
Inc( "modules/cl_hud.lua" )
Inc( "modules/cl_ammo.lua" )
Inc( "modules/cl_weapons.lua" )
Inc( "modules/cl_vehicles.lua" )
Inc( "modules/cl_shipments.lua" )
Inc( "modules/cl_f4menu.lua" )
Inc( "modules/cl_motd.lua" )
Inc( "modules/cl_scoreboard.lua" )
Inc( "modules/cl_doors.lua" )
Inc( "modules/cl_admindoors.lua" )
Inc( "modules/cl_jobspawns.lua" )
Inc( "modules/cl_jailspawns.lua" )
Inc( "modules/cl_mapadjuster.lua" )
Inc( "modules/cl_mountoffset.lua" )
Inc( "modules/cl_security.lua" )
Inc( "modules/cl_entityspawner.lua" )
Inc( "modules/cl_ownershiptool.lua" )
Inc( "modules/cl_votes.lua" )
Inc( "modules/cl_lockpick.lua" )
Inc( "modules/cl_advert.lua" )
Inc( "modules/cl_pocket.lua" )
Inc( "modules/cl_admin.lua" )
Inc( "modules/cl_chatcommands.lua" )

print( "[SWGRP] Client modules loaded." )

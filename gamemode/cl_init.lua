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
Inc( "modules/cl_hud.lua" )
Inc( "modules/cl_f4menu.lua" )
Inc( "modules/cl_motd.lua" )
Inc( "modules/cl_scoreboard.lua" )
Inc( "modules/cl_doors.lua" )
Inc( "modules/cl_admindoors.lua" )
Inc( "modules/cl_jobspawns.lua" )
Inc( "modules/cl_votes.lua" )
Inc( "modules/cl_lockpick.lua" )
Inc( "modules/cl_advert.lua" )
Inc( "modules/cl_pocket.lua" )
Inc( "modules/cl_admin.lua" )

print( "[SWGRP] Client modules loaded." )

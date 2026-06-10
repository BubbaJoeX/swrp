--[[---------------------------------------------------------------------------
    SWGRP Player Class - no sandbox weapon loadout
---------------------------------------------------------------------------]]

if SERVER then
	AddCSLuaFile()
end

DEFINE_BASECLASS( "player_default" )

local PLAYER = {}

PLAYER.WalkSpeed  = 150
PLAYER.RunSpeed   = 350
PLAYER.DuckSpeed  = 0.25
PLAYER.UnDuckSpeed = 0.25

function PLAYER:Loadout()
	-- Weapons are assigned in GM:PlayerLoadout via SWGRP.GiveJobLoadout
end

player_manager.RegisterClass( "player_swgrp", PLAYER, "player_default" )

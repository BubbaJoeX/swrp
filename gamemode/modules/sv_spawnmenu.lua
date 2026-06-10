--[[---------------------------------------------------------------------------
    Q Menu spawn restrictions for non-admins
---------------------------------------------------------------------------]]

local Allow = SWGRP.SpawnAllowlist

local function BlockSpawn( ply, category, id )
	if category == "weapons" and Allow.CanBypassWeapons( ply ) then return end
	if category ~= "weapons" and Allow.CanBypass( ply ) then return end
	if Allow.IsAllowed( ply, category, id ) then return end
	SWGRP.Notify( ply, SWGRP.Lang.spawn_not_allowed or "You cannot spawn that from the Q menu." )
	return false
end

function GM:PlayerSpawnObject( ply )
	if IsValid( ply ) and ply:SWGRP_IsArrested() then
		return false
	end

	return true
end

hook.Add( "PlayerSpawnProp", "SWGRP_SpawnAllowlist", function( ply, model )
	return BlockSpawn( ply, "props", model )
end )

hook.Add( "PlayerSpawnEffect", "SWGRP_SpawnAllowlist", function( ply, model )
	return BlockSpawn( ply, "effects", model )
end )

hook.Add( "PlayerSpawnRagdoll", "SWGRP_SpawnAllowlist", function( ply, model )
	return BlockSpawn( ply, "ragdolls", model )
end )

hook.Add( "PlayerSpawnVehicle", "SWGRP_SpawnAllowlist", function( ply, model, vname )
	if Allow.IsAllowed( ply, "vehicles", vname ) then return end
	if Allow.IsAllowed( ply, "vehicles", model ) then return end
	return BlockSpawn( ply, "vehicles", vname or model )
end )

hook.Add( "PlayerSpawnSWEP", "SWGRP_SpawnAllowlist", function( ply, wname )
	return BlockSpawn( ply, "weapons", wname )
end )

hook.Add( "PlayerGiveSWEP", "SWGRP_SpawnAllowlist", function( ply, wname )
	if ply.SWGRP_SkipSpawnAllowlistGive == wname then return true end
	if string.StartWith( wname or "", "swgrp_" ) then return true end
	return BlockSpawn( ply, "weapons", wname )
end )

hook.Add( "PlayerSpawnSENT", "SWGRP_SpawnAllowlist", function( ply, class )
	return BlockSpawn( ply, "entities", class )
end )

hook.Add( "PlayerSpawnNPC", "SWGRP_SpawnAllowlist", function( ply, npcType )
	return BlockSpawn( ply, "npcs", npcType )
end )

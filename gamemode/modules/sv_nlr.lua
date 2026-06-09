--[[---------------------------------------------------------------------------
    New Life Rule - block returning to your death location after respawn
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.NLR = SWGRP.NLR or {}

function SWGRP.NLR.Enabled()
	return SWGRP.Config and SWGRP.Config.NLREnabled and SWGRP.Config.NLREnabled:GetBool()
end

function SWGRP.NLR.Time()
	return SWGRP.Config and SWGRP.Config.NLRTime and SWGRP.Config.NLRTime:GetInt() or 120
end

function SWGRP.NLR.Distance()
	return SWGRP.Config and SWGRP.Config.NLRDistance or 600
end

-- Find a non-solid spot near a target position so NLR pushes don't bury players
-- inside walls/geometry. Falls back to the requested position.
function SWGRP.NLR_FindSafe( target )
	local hullMin, hullMax = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
	for _, offset in ipairs( {
		Vector( 0, 0, 0 ), Vector( 48, 0, 0 ), Vector( -48, 0, 0 ),
		Vector( 0, 48, 0 ), Vector( 0, -48, 0 ), Vector( 0, 0, 32 ),
	} ) do
		local pos = target + offset
		local tr = util.TraceHull( {
			start = pos + Vector( 0, 0, 16 ),
			endpos = pos - Vector( 0, 0, 256 ),
			mins = hullMin,
			maxs = hullMax,
			mask = MASK_PLAYERSOLID,
		} )
		if tr.Hit and not tr.StartSolid and util.IsInWorld( tr.HitPos ) then
			return tr.HitPos + Vector( 0, 0, 2 )
		end
	end
	return target
end

hook.Add( "PlayerDeath", "SWGRP_NLR_Record", function( ply )
	if not IsValid( ply ) then return end
	ply.SWGRP_DeathPos = ply:GetPos()
	ply.SWGRP_NLRUntil = CurTime() + SWGRP.NLR.Time()
end )

hook.Add( "PlayerSpawn", "SWGRP_NLR_Notify", function( ply )
	if not IsValid( ply ) or not SWGRP.NLR.Enabled() then return end
	if ply.SWGRP_NLRUntil and ply.SWGRP_NLRUntil > CurTime() then
		SWGRP.Notify( ply, "New Life Rule active: stay away from your death location for " ..
			math.ceil( ply.SWGRP_NLRUntil - CurTime() ) .. "s." )
	end
end )

-- Periodically push violators away from their death spot.
timer.Create( "SWGRP_NLR_Enforce", 1, 0, function()
	if not SWGRP.NLR.Enabled() then return end

	local dist = SWGRP.NLR.Distance()
	local distSqr = dist * dist

	for _, ply in ipairs( player.GetAll() ) do
		if not IsValid( ply ) or not ply:Alive() then continue end
		if not ply.SWGRP_NLRUntil or ply.SWGRP_NLRUntil <= CurTime() then continue end
		if not ply.SWGRP_DeathPos then continue end
		if ply:SWGRP_IsArrested() then continue end

		if ply:GetPos():DistToSqr( ply.SWGRP_DeathPos ) < distSqr then
			local away = ( ply:GetPos() - ply.SWGRP_DeathPos )
			away.z = 0
			if away:LengthSqr() < 1 then
				away = ply:GetForward() * -1
				away.z = 0
			end
			away:Normalize()

			local target = ply.SWGRP_DeathPos + away * ( dist + 64 )
			local empty = SWGRP.NLR_FindSafe and SWGRP.NLR_FindSafe( target )
			ply:SetPos( empty or target )
			SWGRP.Notify( ply, "New Life Rule: you cannot return to your death location yet." )
		end
	end
end )

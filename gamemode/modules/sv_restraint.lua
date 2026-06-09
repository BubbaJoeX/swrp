--[[---------------------------------------------------------------------------
    Restraint / Zip Tie System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Restraint = SWGRP.Restraint or {}

function SWGRP.Restraint.CanRestrain( ply )
	local job = SWGRP.GetJob( ply:Team() )
	if not job then return false end
	return job.bountyhunter or job.canRestrain or job.name == "Smuggler"
end

function SWGRP.Restraint.Restrain( restrainer, target )
	if not IsValid( restrainer ) or not IsValid( target ) or not target:IsPlayer() then return false end
	if target:SWGRP_IsRestrained() or target:SWGRP_IsArrested() then return false end
	if target:SWGRP_IsGovernment() then return false end
	if not SWGRP.Restraint.CanRestrain( restrainer ) then return false end

	target.SWGRP_WeaponStash = {}
	for _, wep in ipairs( target:GetWeapons() ) do
		table.insert( target.SWGRP_WeaponStash, wep:GetClass() )
	end

	target:StripWeapons()
	target:Freeze( true )
	target:SetNWBool( "SWGRP_Restrained", true )
	target.SWGRP_RestrainedBy = restrainer

	SWGRP.Notify( restrainer, "Target restrained." )
	SWGRP.Notify( target, "You have been restrained." )
	return true
end

function SWGRP.Restraint.Release( target, releaser )
	if not IsValid( target ) or not target:SWGRP_IsRestrained() then return false end

	target:Freeze( false )
	target:SetNWBool( "SWGRP_Restrained", false )
	target.SWGRP_RestrainedBy = nil

	SWGRP.GiveJobLoadout( target )

	SWGRP.Notify( target, "You are no longer restrained." )
	if IsValid( releaser ) and releaser ~= target then
		SWGRP.Notify( releaser, "Restraints removed." )
	end
	return true
end

hook.Add( "PlayerSwitchWeapon", "SWGRP_Restrained", function( ply )
	if ply:SWGRP_IsRestrained() then return true end
end )

hook.Add( "CanPlayerSuicide", "SWGRP_Restrained", function( ply )
	if ply:SWGRP_IsRestrained() then return false end
end )

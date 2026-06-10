--[[---------------------------------------------------------------------------
    New Life Rule - damage players who return to their death location after respawn
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.NLR = SWGRP.NLR or {}

SWGRP.NLR.DOTInterval = 0.5
SWGRP.NLR.DOTDamage   = 2
SWGRP.NLR.WarnInterval = 4

function SWGRP.NLR.Enabled()
	return SWGRP.Config and SWGRP.Config.NLREnabled and SWGRP.Config.NLREnabled:GetBool()
end

function SWGRP.NLR.Time()
	return SWGRP.Config and SWGRP.Config.NLRTime and SWGRP.Config.NLRTime:GetInt() or 120
end

function SWGRP.NLR.Distance()
	return SWGRP.Config and SWGRP.Config.NLRDistance or 600
end

function SWGRP.NLR.ShouldEnforce( ply )
	if not IsValid( ply ) then return false end
	if SWGRP.Admin and SWGRP.Admin.CanUse( ply ) then return false end
	return true
end

hook.Add( "PlayerDeath", "SWGRP_NLR_Record", function( ply )
	if not IsValid( ply ) then return end
	ply.SWGRP_DeathPos = ply:GetPos()
	ply.SWGRP_NLRUntil = CurTime() + SWGRP.NLR.Time()
	ply.SWGRP_NLRWarn = nil
end )

hook.Add( "PlayerSpawn", "SWGRP_NLR_Notify", function( ply )
	if not IsValid( ply ) or not SWGRP.NLR.Enabled() then return end
	if not SWGRP.NLR.ShouldEnforce( ply ) then return end
	if ply.SWGRP_NLRUntil and ply.SWGRP_NLRUntil > CurTime() then
		SWGRP.Notify( ply, "New Life Rule active: stay away from your death location for " ..
			math.ceil( ply.SWGRP_NLRUntil - CurTime() ) .. "s." )
	end
end )

timer.Create( "SWGRP_NLR_Enforce", SWGRP.NLR.DOTInterval, 0, function()
	if not SWGRP.NLR.Enabled() then return end

	local dist = SWGRP.NLR.Distance()
	local distSqr = dist * dist
	local dot = SWGRP.NLR.DOTDamage
	local warnGap = SWGRP.NLR.WarnInterval

	for _, ply in ipairs( player.GetAll() ) do
		if not IsValid( ply ) or not ply:Alive() then continue end
		if not SWGRP.NLR.ShouldEnforce( ply ) then continue end
		if not ply.SWGRP_NLRUntil or ply.SWGRP_NLRUntil <= CurTime() then continue end
		if not ply.SWGRP_DeathPos then continue end
		if ply:SWGRP_IsArrested() then continue end

		if ply:GetPos():DistToSqr( ply.SWGRP_DeathPos ) >= distSqr then
			ply.SWGRP_NLRWarn = nil
			continue
		end

		local dmg = DamageInfo()
		dmg:SetDamage( dot )
		dmg:SetDamageType( DMG_SLOWBURN )
		dmg:SetAttacker( ply )
		dmg:SetInflictor( ply )
		ply:TakeDamageInfo( dmg )

		local now = CurTime()
		if not ply.SWGRP_NLRWarn or ply.SWGRP_NLRWarn <= now then
			ply.SWGRP_NLRWarn = now + warnGap
			SWGRP.Notify( ply, "New Life Rule: leave your death area before you burn out." )
		end
	end
end )

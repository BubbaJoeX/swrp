--[[---------------------------------------------------------------------------
    Lockpick Minigame Server
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Lockpick = SWGRP.Lockpick or {}
SWGRP.Lockpick.Active = SWGRP.Lockpick.Active or {}

function SWGRP.Lockpick.Start( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return end
	if SWGRP.Lockpick.Active[ply] then return end

	local canPick = hook.Call( "canLockpick", GAMEMODE, ply, ent, ply:GetEyeTrace() )
	if canPick == false then return end

	SWGRP.Lockpick.Active[ply] = {
		ent = ent,
		start = CurTime(),
	}

	ply:Freeze( true )

	net.Start( "SWGRP_Lockpick" )
		net.WriteUInt( ent:EntIndex(), 16 )
		net.WriteFloat( CurTime() + 10 )
	net.Send( ply )

	local timerName = "SWGRP_LockpickTimeout_" .. ply:SteamID64()
	timer.Create( timerName, 12, 1, function()
		SWGRP.Lockpick.Finish( ply, false )
	end )
end

function SWGRP.Lockpick.Finish( ply, success )
	local data = SWGRP.Lockpick.Active[ply]
	if not data then return end

	timer.Remove( "SWGRP_LockpickTimeout_" .. ply:SteamID64() )
	SWGRP.Lockpick.Active[ply] = nil

	if IsValid( ply ) then
		ply:Freeze( false )
	end

	if not IsValid( data.ent ) or not IsValid( ply ) then return end

	local dist = ply:GetPos():DistToSqr( data.ent:GetPos() )
	if dist > 10000 then
		SWGRP.Notify( ply, "Too far from target." )
		return
	end

	-- Reject implausibly fast "success" reports (spoofed result before the minigame
	-- could realistically be completed).
	if success and data.start and ( CurTime() - data.start ) < 1.5 then
		success = false
	end

	hook.Call( "onLockpickCompleted", GAMEMODE, ply, success, data.ent )

	if success then
		SWGRP.Notify( ply, "Lock bypassed." )
	else
		SWGRP.Notify( ply, "Bypass failed." )
	end
end

net.Receive( "SWGRP_LockpickResult", function( len, ply )
	if not SWGRP.Lockpick.Active[ply] then return end
	local success = net.ReadBool()
	SWGRP.Lockpick.Finish( ply, success )
end )

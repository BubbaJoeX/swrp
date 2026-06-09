--[[---------------------------------------------------------------------------
    Mission System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MissionsMgr = SWGRP.MissionsMgr or {}

function SWGRP.MissionsMgr.CanAccept( ply, missionId )
	local mission = SWGRP.Missions[missionId]
	if not mission then return false, "Invalid mission." end
	if ply.SWGRP_ActiveMission then return false, "Already on a mission." end
	if ply.SWGRP_MissionCooldown and os.time() < ply.SWGRP_MissionCooldown then
		return false, "Mission cooldown active."
	end

	if mission.allowed then
		local ok = false
		for _, t in ipairs( mission.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then return false, "Profession not eligible." end
	end

	if mission.faction == "imperial" and SWGRP.Factions.Get( ply, "imperial" ) < -20 then
		return false, "Imperial standing too low."
	end
	if mission.faction == "rebel" and SWGRP.Factions.Get( ply, "rebel" ) < -20 then
		return false, "Rebel standing too low."
	end

	return true
end

function SWGRP.MissionsMgr.Accept( ply, missionId )
	local can, reason = SWGRP.MissionsMgr.CanAccept( ply, missionId )
	if not can then
		SWGRP.Notify( ply, reason )
		return
	end

	local mission = SWGRP.Missions[missionId]
	ply.SWGRP_ActiveMission = {
		id = missionId,
		data = mission,
		start = os.time(),
		progress = 0,
	}
	ply.SWGRP_MissionDeadline = os.time() + mission.duration

	ply:SetNWString( "SWGRP_Mission", mission.name )
	ply:SetNWInt( "SWGRP_MissionProgress", 0 )
	ply:SetNWInt( "SWGRP_MissionGoal", mission.kills or mission.collects or 1 )

	SWGRP.Notify( ply, "Mission accepted: " .. mission.name )
	SWGRP.Hooks.Call( "SWGRPMissionAccepted", ply, mission )
	SWGRP.Persistence.ScheduleSave( ply )

	local timerName = "SWGRP_Mission_" .. ply:SteamID64()
	timer.Create( timerName, mission.duration, 1, function()
		if IsValid( ply ) and ply.SWGRP_ActiveMission then
			SWGRP.MissionsMgr.Fail( ply, "Mission timed out." )
		end
	end )

	if mission.type == "courier" or mission.type == "patrol" or mission.type == "sabotage" or mission.type == "smuggle" then
		SWGRP.MissionsMgr.StartProgressTimer( ply, mission )
	end
end

function SWGRP.MissionsMgr.StartProgressTimer( ply, mission )
	local timerName = "SWGRP_MissionProg_" .. ply:SteamID64()
	timer.Create( timerName, 5, 0, function()
		if not IsValid( ply ) or not ply.SWGRP_ActiveMission then
			timer.Remove( timerName )
			return
		end
		if ply:GetVelocity():Length() > 50 then
			ply.SWGRP_ActiveMission.progress = ply.SWGRP_ActiveMission.progress + 1
			ply:SetNWInt( "SWGRP_MissionProgress", ply.SWGRP_ActiveMission.progress )
			if ply.SWGRP_ActiveMission.progress >= 20 then
				SWGRP.MissionsMgr.Complete( ply )
				timer.Remove( timerName )
			end
		end
	end )
end

function SWGRP.MissionsMgr.Complete( ply )
	local active = ply.SWGRP_ActiveMission
	if not active then return end
	local mission = active.data

	ply:SWGRP_AddCredits( mission.reward )
	SWGRP.Profession.AddXP( ply, mission.xp or 20 )
	SWGRP.Factions.ApplyGains( ply, mission.factionGain )

	ply.SWGRP_ActiveMission = nil
	ply.SWGRP_MissionDeadline = nil
	ply.SWGRP_MissionCooldown = os.time() + SWGRP.Config.MissionCooldown:GetInt()
	ply:SetNWString( "SWGRP_Mission", "" )
	ply:SetNWInt( "SWGRP_MissionProgress", 0 )

	timer.Remove( "SWGRP_Mission_" .. ply:SteamID64() )
	timer.Remove( "SWGRP_MissionProg_" .. ply:SteamID64() )

	SWGRP.Notify( ply, "Mission complete! Reward: " .. SWGRP.FormatCredits( mission.reward ) )
	SWGRP.Hooks.Call( "SWGRPMissionCompleted", ply, mission, mission.reward )
	SWGRP.Persistence.ScheduleSave( ply )
end

function SWGRP.MissionsMgr.Fail( ply, reason )
	ply.SWGRP_ActiveMission = nil
	ply.SWGRP_MissionDeadline = nil
	ply:SetNWString( "SWGRP_Mission", "" )
	ply:SetNWInt( "SWGRP_MissionProgress", 0 )
	timer.Remove( "SWGRP_Mission_" .. ply:SteamID64() )
	timer.Remove( "SWGRP_MissionProg_" .. ply:SteamID64() )
	SWGRP.Notify( ply, reason or "Mission failed." )
	SWGRP.Persistence.ScheduleSave( ply )
end

function SWGRP.MissionsMgr.AddProgress( ply, amount )
	if not ply.SWGRP_ActiveMission then return end
	local mission = ply.SWGRP_ActiveMission.data
	local goal = mission.kills or mission.collects or 1

	ply.SWGRP_ActiveMission.progress = ply.SWGRP_ActiveMission.progress + amount
	ply:SetNWInt( "SWGRP_MissionProgress", ply.SWGRP_ActiveMission.progress )
	ply:SetNWInt( "SWGRP_MissionGoal", goal )

	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply, 8 ) end

	if ply.SWGRP_ActiveMission.progress >= goal then
		SWGRP.MissionsMgr.Complete( ply )
	end
end

hook.Add( "OnNPCKilled", "SWGRP_MissionKill", function( npc, attacker )
	if IsValid( attacker ) and attacker:IsPlayer() and attacker.SWGRP_ActiveMission then
		local m = attacker.SWGRP_ActiveMission.data
		if m.type == "elimination" then
			SWGRP.MissionsMgr.AddProgress( attacker, 1 )
		end
	end
end )

hook.Add( "PlayerDeath", "SWGRP_MissionFail", function( victim )
	if victim.SWGRP_ActiveMission then
		local m = victim.SWGRP_ActiveMission.data
		if m.type == "smuggle" or m.type == "sabotage" then
			SWGRP.MissionsMgr.Fail( victim, "Mission failed — you were killed." )
		end
	end
end )

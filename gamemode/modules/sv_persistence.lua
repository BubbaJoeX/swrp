--[[---------------------------------------------------------------------------
    SWGRP Persistence Layer
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Persistence = SWGRP.Persistence or {}

local P = SWGRP.Persistence

function P.ScheduleSave( ply, delay )
	if not IsValid( ply ) then return end
	delay = delay or 3

	local timerName = "SWGRP_Save_" .. ply:SteamID64()
	timer.Create( timerName, delay, 1, function()
		if IsValid( ply ) then
			SWGRP.DB.SavePlayer( ply )
		end
	end )
end

function P.SaveNow( ply )
	if IsValid( ply ) then
		SWGRP.DB.SavePlayer( ply )
	end
end

function P.SaveWorld()
	SWGRP.DB.SetWorld( "laws", util.TableToJSON( SWGRP.Laws or {} ) )
	SWGRP.DB.SetWorld( "treasury", tostring( SWGRP.Economy and SWGRP.Economy.Treasury or 0 ) )
	SWGRP.DB.SetWorld( "lottery_pool", tostring( SWGRP.Government and SWGRP.Government.LotteryPool or 0 ) )
	SWGRP.DB.SetWorld( "agenda", GetGlobalString( "SWGRP_Agenda", "" ) )
end

function P.LoadWorld()
	local lawsJson = SWGRP.DB.GetWorld( "laws" )
	local laws = SWGRP.DB.ParseJSON( lawsJson )
	if laws and #laws > 0 then
		SWGRP.Laws = laws
	elseif #SWGRP.Laws == 0 then
		SWGRP.Laws = table.Copy( SWGRP.Config.DefaultLaws )
	end

	SWGRP.Economy.Treasury = tonumber( SWGRP.DB.GetWorld( "treasury", "0" ) ) or 0
	SWGRP.Government.LotteryPool = tonumber( SWGRP.DB.GetWorld( "lottery_pool", "0" ) ) or 0

	local agenda = SWGRP.DB.GetWorld( "agenda", "" )
	if agenda and agenda ~= "" then
		SetGlobalString( "SWGRP_Agenda", agenda )
	end

	P.LoadBounties()
	P.LoadWarrants()

	if SWGRP.Government and SWGRP.Government.SyncLaws then
		SWGRP.Government.SyncLaws()
	end
end

function P.LoadBounties()
	SWGRP.HitContracts = SWGRP.HitContracts or {}

	for _, row in ipairs( SWGRP.DB.LoadBounties() ) do
		local target = player.GetBySteamID( row.target_steamid )
		SWGRP.HitContracts[row.target_steamid] = {
			customer = row.customer_steamid,
			target = target,
			targetSid = row.target_steamid,
			price = tonumber( row.price ) or 0,
			time = tonumber( row.placed_at ) or os.time(),
		}
	end
end

function P.LoadWarrants()
	SWGRP.Police.Warrants = SWGRP.Police.Warrants or {}
	local now = os.time()

	for _, row in ipairs( SWGRP.DB.LoadWarrants() ) do
		local expire = tonumber( row.expire_at ) or 0
		if expire > now then
			SWGRP.Police.Warrants[row.target_steamid] = {
				reason = row.reason or "",
				expire = expire,
				officer = row.officer_steamid or "",
			}
		else
			SWGRP.DB.DeleteWarrant( row.target_steamid )
		end
	end
end

function P.SaveBounty( targetSid, customerSid, price )
	SWGRP.DB.SaveBounty( targetSid, customerSid, price )
end

function P.DeleteBounty( targetSid )
	SWGRP.DB.DeleteBounty( targetSid )
end

function P.SaveWarrant( targetSid, reason, expireAt, officerSid )
	SWGRP.DB.SaveWarrant( targetSid, reason, expireAt, officerSid )
end

function P.DeleteWarrant( targetSid )
	SWGRP.DB.DeleteWarrant( targetSid )
end

function P.RestorePlayer( ply, row )
	if not IsValid( ply ) then return end

	local now = os.time()

	if row then
		local wantedExpire = tonumber( row.wanted_expire ) or 0
		if tonumber( row.wanted ) == 1 and wantedExpire > now then
			ply:SetNWBool( "SWGRP_Wanted", true )
			ply:SetNWString( "SWGRP_WantedReason", row.wanted_reason or "Unspecified offense" )
			ply.SWGRP_WantedExpire = wantedExpire
		else
			ply:SWGRP_UnWanted()
		end

		local arrestExpire = tonumber( row.arrest_expire ) or 0
		if tonumber( row.arrested ) == 1 and arrestExpire > now then
			ply:SWGRP_SetArrested( true )
			ply.SWGRP_ArrestExpire = arrestExpire
			local remaining = arrestExpire - now
			timer.Create( "SWGRP_Arrest_" .. ply:SteamID64(), remaining, 1, function()
				if IsValid( ply ) then
					SWGRP.Police.UnArrest( ply )
				end
			end )
		else
			ply:SWGRP_SetArrested( false )
		end

		local cooldown = tonumber( row.mission_cooldown ) or 0
		if cooldown > now then
			ply.SWGRP_MissionCooldown = cooldown
		end

		local missionId = tonumber( row.mission_id ) or 0
		local missionDeadline = tonumber( row.mission_deadline ) or 0
		if missionId > 0 and missionDeadline > now and SWGRP.Missions[missionId] then
			P.RestoreMission( ply, missionId, tonumber( row.mission_progress ) or 0, missionDeadline )
		end
	end

	timer.Simple( 0.5, function()
		if not IsValid( ply ) then return end
		SWGRP.Doors.RecalcDoorCount( ply )
		SWGRP.Doors.ResolveOwners( ply )
	end )
end

function P.RestoreMission( ply, missionId, progress, deadline )
	local mission = SWGRP.Missions[missionId]
	if not mission then return end

	ply.SWGRP_ActiveMission = {
		id = missionId,
		data = mission,
		start = os.time(),
		progress = progress,
	}
	ply.SWGRP_MissionDeadline = deadline

	ply:SetNWString( "SWGRP_Mission", mission.name )
	ply:SetNWInt( "SWGRP_MissionProgress", progress )
	ply:SetNWInt( "SWGRP_MissionGoal", mission.kills or mission.collects or 1 )

	local remaining = math.max( 1, deadline - os.time() )
	timer.Create( "SWGRP_Mission_" .. ply:SteamID64(), remaining, 1, function()
		if IsValid( ply ) and ply.SWGRP_ActiveMission then
			SWGRP.MissionsMgr.Fail( ply, "Mission timed out." )
		end
	end )

	if mission.type == "courier" or mission.type == "patrol" or mission.type == "sabotage" or mission.type == "smuggle" then
		SWGRP.MissionsMgr.StartProgressTimer( ply, mission )
	end
end

function P.ClearMission( ply )
	if not IsValid( ply ) then return end
	ply.SWGRP_ActiveMission = nil
	ply.SWGRP_MissionDeadline = nil
	ply:SetNWString( "SWGRP_Mission", "" )
	ply:SetNWInt( "SWGRP_MissionProgress", 0 )
	P.ScheduleSave( ply )
end

function P.SyncOnlineBounties()
	for sid, contract in pairs( SWGRP.HitContracts or {} ) do
		local target = player.GetBySteamID( sid )
		if IsValid( target ) then
			contract.target = target
		end
		if isstring( contract.customer ) then
			contract.customer = player.GetBySteamID( contract.customer ) or contract.customer
		end
	end
end

hook.Add( "PlayerInitialSpawn", "SWGRP_PersistenceSync", function( ply )
	timer.Simple( 2.5, function()
		if not IsValid( ply ) then return end
		P.SyncOnlineBounties()
		if SWGRP.Hitman and SWGRP.Hitman.Sync then
			SWGRP.Hitman.Sync( ply )
		end
	end )
end )

--[[---------------------------------------------------------------------------
    SWGRP Core API - Registration and shared state
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}

SWGRP.Jobs        = SWGRP.Jobs or {}
SWGRP.Categories  = SWGRP.Categories or {}
SWGRP.Entities    = SWGRP.Entities or {}
SWGRP.Shipments   = SWGRP.Shipments or {}
SWGRP.Foods       = SWGRP.Foods or {}
SWGRP.Spices      = SWGRP.Spices or {}
SWGRP.AmmoTypes   = SWGRP.AmmoTypes or {}
SWGRP.ChatCmds    = SWGRP.ChatCmds or {}
SWGRP.DoorGroups  = SWGRP.DoorGroups or {}
SWGRP.Laws        = SWGRP.Laws or {}
SWGRP.JailPositions = SWGRP.JailPositions or {}
SWGRP.JobSpawns  = SWGRP.JobSpawns or {}
SWGRP.HitContracts = SWGRP.HitContracts or {}
SWGRP.Recipes      = SWGRP.Recipes or {}
SWGRP.Missions      = SWGRP.Missions or {}
SWGRP.Vehicles      = SWGRP.Vehicles or {}
SWGRP.ContrabandTypes = SWGRP.ContrabandTypes or {}

local nextTeamId = 1

function SWGRP.RegisterJob( name, data )
	data.name = name

	-- Reuse an existing team id when the same command is re-registered. This lets
	-- content hot-reloads and custom CSV overrides update a job in place instead
	-- of creating a duplicate team.
	if not data.team then
		local cmdKey = string.lower( data.command or name )
		for id, job in pairs( SWGRP.Jobs ) do
			if string.lower( job.command or job.name or "" ) == cmdKey then
				data.team = id
				break
			end
		end
	end

	data.team = data.team or nextTeamId
	nextTeamId = math.max( nextTeamId, data.team + 1 )

	team.SetUp( data.team, name, data.color or Color( 255, 255, 255 ) )
	team.SetSpawnPoint( data.team, data.spawns or "info_player_start" )

	SWGRP.Jobs[data.team] = data
	_G["TEAM_" .. string.upper( data.command or name )] = data.team

	return data.team
end

function SWGRP.RegisterCategory( data )
	SWGRP.Categories[data.name] = data
end

function SWGRP.RegisterEntity( class, data )
	data.ent = class
	SWGRP.Entities[class] = data
end

function SWGRP.RegisterShipment( name, data )
	data.name = name
	table.insert( SWGRP.Shipments, data )
end

function SWGRP.RegisterFood( name, data )
	data.name = name
	table.insert( SWGRP.Foods, data )
end

function SWGRP.RegisterSpice( name, data )
	data.name = name
	table.insert( SWGRP.Spices, data )
end

function SWGRP.RegisterAmmoType( name, data )
	data.name = name
	SWGRP.AmmoTypes[name] = data
end

function SWGRP.RegisterVehicle( data )
	table.insert( SWGRP.Vehicles, data )
end

function SWGRP.RegisterChatCommand( cmd, data )
	cmd = string.lower( cmd )
	data.command = cmd
	SWGRP.ChatCmds[cmd] = data
end

function SWGRP.RegisterDoorGroup( name, teams )
	SWGRP.DoorGroups[name] = teams
end

function SWGRP.RegisterJailPos( pos, ang )
	table.insert( SWGRP.JailPositions, { pos = pos, ang = ang or Angle( 0, 0, 0 ) } )
end

function SWGRP.GetJob( teamId )
	return SWGRP.Jobs[teamId]
end

function SWGRP.GetJobModels( job )
	if not job or not job.model then return {} end
	if istable( job.model ) then return job.model end
	return { job.model }
end

function SWGRP.GetJobByCommand( cmd )
	cmd = string.lower( cmd )
	for id, job in pairs( SWGRP.Jobs ) do
		if string.lower( job.command or "" ) == cmd then
			return job, id
		end
	end
end

-- True if the player's *current* profession command is in the allow list (a
-- lowercased command array, or nil/empty for unrestricted). Matching by command
-- text rather than a pre-resolved team id keeps access checks correct even if
-- numeric team ids shift across content reloads or Lua refreshes.
function SWGRP.PlayerJobAllowed( ply, allowedCmds )
	if not allowedCmds or #allowedCmds == 0 then return true end
	if not IsValid( ply ) then return false end

	local job = SWGRP.GetJob( ply:Team() )
	local myCmd = job and string.lower( job.command or "" ) or ""
	if myCmd == "" then return false end

	for _, c in ipairs( allowedCmds ) do
		if string.lower( c ) == myCmd then return true end
	end
	return false
end

-- Purchase gate: superadmins bypass profession command restrictions and are told
-- when a check would otherwise have blocked them.
function SWGRP.PlayerJobAllowedPurchase( ply, allowedCmds )
	if IsValid( ply ) and ply:IsSuperAdmin() then
		if allowedCmds and #allowedCmds > 0 and not SWGRP.PlayerJobAllowed( ply, allowedCmds ) then
			if SERVER and SWGRP.Notify then
				SWGRP.Notify( ply, "Superadmin override: ignoring profession restriction." )
			end
		end
		return true
	end

	return SWGRP.PlayerJobAllowed( ply, allowedCmds )
end

-- Same bypass for catalog rows that still store resolved team ids (ammo, vehicles).
function SWGRP.PlayerTeamAllowedPurchase( ply, allowedTeams )
	if not allowedTeams or #allowedTeams == 0 then return true end
	if not IsValid( ply ) then return false end

	for _, t in ipairs( allowedTeams ) do
		if ply:Team() == t then return true end
	end

	if ply:IsSuperAdmin() then
		if SERVER and SWGRP.Notify then
			SWGRP.Notify( ply, "Superadmin override: ignoring profession restriction." )
		end
		return true
	end

	return false
end

function SWGRP.JobCount( teamId )
	local count = 0
	for _, ply in ipairs( player.GetAll() ) do
		if ply:Team() == teamId then count = count + 1 end
	end
	return count
end

function SWGRP.IsGovernmentJob( teamId )
	local job = SWGRP.GetJob( teamId )
	return job and ( job.governor or job.commander or job.officer or job.stormtrooper )
end

function SWGRP.IsMedicJob( teamId )
	local job = SWGRP.GetJob( teamId )
	return job and ( job.medic or job.doctor )
end

function SWGRP.IsBountyHunter( teamId )
	local job = SWGRP.GetJob( teamId )
	return job and job.bountyhunter
end

function SWGRP.IsGovernor( teamId )
	local job = SWGRP.GetJob( teamId )
	return job and job.governor
end

function SWGRP.FormatCredits( amount )
	return string.Comma( math.floor( amount ) ) .. " " .. ( SWGRP.Config.CurrencySymbol or "CR" )
end

function SWGRP.Notify( ply, msg, msgType )
	msgType = msgType or 0

	if SERVER then
		if IsValid( ply ) then
			net.Start( "SWGRP_Notify" )
				SWGRP.NetWriteNotify( msg, msgType )
			net.Send( ply )
		else
			net.Start( "SWGRP_Notify" )
				SWGRP.NetWriteNotify( msg, msgType )
			net.Broadcast()
		end
	else
		local col = SWGRP.Config.HUDColorAccent
		if msgType == 1 then
			col = SWGRP.Config.HUDColorDanger
		end

		if SWGRP.UI and SWGRP.UI.HUD and SWGRP.UI.HUD.Toast then
			SWGRP.UI.HUD.Toast( msg, 3.5, col )
		else
			chat.AddText( SWGRP.Config.HUDColorPrimary, "[SWGRP] ", color_white, msg )
		end
	end
end

function SWGRP.FindPlayer( name )
	if not name or name == "" then return end
	name = string.lower( name )

	for _, ply in ipairs( player.GetAll() ) do
		if string.find( string.lower( ply:Nick() ), name, 1, true ) then
			return ply
		end
	end
end

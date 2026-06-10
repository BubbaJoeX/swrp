--[[---------------------------------------------------------------------------
    Job Spawn Points

    Per-map spawn positions keyed by job command. Persisted in swgrp_world and
    applied via team.SetSpawnPoint. Custom angles are enforced on PlayerSpawn.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JobSpawns = SWGRP.JobSpawns or {}

local JS = SWGRP.JobSpawns
JS.Data = JS.Data or {}

local REMOVE_RADIUS_SQR = 96 * 96

local function AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

local function StorageKey()
	return "swgrp_jobspawns_" .. game.GetMap()
end

function JS.SerializeSpawn( pos, ang )
	ang = ang or Angle( 0, 0, 0 )
	return {
		x = math.Round( pos.x, 2 ),
		y = math.Round( pos.y, 2 ),
		z = math.Round( pos.z, 2 ),
		pitch = math.Round( ang.p, 2 ),
		yaw = math.Round( ang.y, 2 ),
		roll = math.Round( ang.r, 2 ),
	}
end

function JS.DeserializeSpawn( row )
	if not row then return nil end
	local pitch = row.pitch or row.p or 0
	local yaw = row.yaw or 0
	local roll = row.roll or row.r or 0
	return Vector( row.x or 0, row.y or 0, row.z or 0 ), Angle( pitch, yaw, roll )
end

function JS.GetSelectedCommand( ply )
	if not IsValid( ply ) then return "colonist" end
	local cmd = ply:GetNWString( "SWGRP_JobSpawnCmd", "" )
	if cmd == "" then
		local job = SWGRP.GetJob( ply:Team() )
		cmd = job and job.command or "colonist"
	end
	return string.lower( cmd )
end

function JS.SetSelectedCommand( ply, cmd )
	if not IsValid( ply ) then return end
	ply:SetNWString( "SWGRP_JobSpawnCmd", string.lower( cmd or "" ) )
end

function JS.GetSpawns( cmd )
	cmd = string.lower( cmd or "" )
	return JS.Data[cmd] or {}
end

function JS.GetSpawnCount( cmd )
	return #( JS.GetSpawns( cmd ) )
end

function JS.Save()
	if not SWGRP.DB or not SWGRP.DB.SetWorld then return end
	SWGRP.DB.SetWorld( StorageKey(), util.TableToJSON( JS.Data ) )
end

function JS.Load()
	JS.Data = {}

	if not SWGRP.DB or not SWGRP.DB.GetWorld then return end

	local raw = SWGRP.DB.GetWorld( StorageKey(), "{}" )
	local parsed = SWGRP.DB.ParseJSON( raw )
	if istable( parsed ) then
		for cmd, list in pairs( parsed ) do
			if istable( list ) then
				JS.Data[string.lower( cmd )] = list
			end
		end
	end
end

function JS.ApplyTeam( teamId )
	local job = SWGRP.GetJob( teamId )
	if not job then return end

	local cmd = string.lower( job.command or "" )
	local points = JS.Data[cmd]

	if points and #points > 0 then
		local vecs = {}
		for _, row in ipairs( points ) do
			local pos = select( 1, JS.DeserializeSpawn( row ) )
			if pos then
				table.insert( vecs, pos )
			end
		end

		if #vecs > 0 then
			team.SetSpawnPoint( teamId, vecs )
			job.spawns = vecs
			return
		end
	end

	team.SetSpawnPoint( teamId, job.spawns or "info_player_start" )
end

function JS.ApplyAll()
	for teamId in pairs( SWGRP.Jobs or {} ) do
		JS.ApplyTeam( teamId )
	end
end

function JS.PickSpawn( teamId )
	local job = SWGRP.GetJob( teamId )
	if not job then return nil end

	local points = JS.Data[string.lower( job.command or "" )]
	if not points or #points == 0 then return nil end

	local row = points[math.random( #points )]
	return JS.DeserializeSpawn( row )
end

function JS.AddSpawn( ply, cmd, pos, ang )
	cmd = string.lower( cmd or "" )
	if cmd == "" then return false, "Invalid profession." end

	local job = SWGRP.GetJobByCommand( cmd )
	if not job then return false, "Unknown profession: " .. cmd end

	JS.Data[cmd] = JS.Data[cmd] or {}
	table.insert( JS.Data[cmd], JS.SerializeSpawn( pos, ang ) )

	JS.ApplyTeam( job.team )
	JS.Save()

	return true, string.format(
		"Added spawn for %s (%d total on this map).",
		job.name or cmd,
		#JS.Data[cmd]
	)
end

function JS.RemoveNearest( ply, cmd, pos )
	cmd = string.lower( cmd or "" )
	local list = JS.Data[cmd]
	if not list or #list == 0 then
		return false, "No spawn points for that profession."
	end

	local bestIdx, bestDist
	for i, row in ipairs( list ) do
		local spPos = select( 1, JS.DeserializeSpawn( row ) )
		if spPos then
			local dist = spPos:DistToSqr( pos )
			if dist <= REMOVE_RADIUS_SQR and ( not bestDist or dist < bestDist ) then
				bestDist = dist
				bestIdx = i
			end
		end
	end

	if not bestIdx then
		return false, "No spawn point within range."
	end

	table.remove( list, bestIdx )
	if #list == 0 then
		JS.Data[cmd] = nil
	end

	local job = SWGRP.GetJobByCommand( cmd )
	if job then
		JS.ApplyTeam( job.team )
	end

	JS.Save()

	local label = job and job.name or cmd
	return true, string.format( "Removed nearest spawn for %s.", label )
end

function JS.ClearJob( cmd )
	cmd = string.lower( cmd or "" )
	if not JS.Data[cmd] or #JS.Data[cmd] == 0 then
		return false, "No spawn points to clear."
	end

	JS.Data[cmd] = nil

	local job = SWGRP.GetJobByCommand( cmd )
	if job then
		JS.ApplyTeam( job.team )
	end

	JS.Save()

	local label = job and job.name or cmd
	return true, string.format( "Cleared all spawn points for %s.", label )
end

function JS.SyncTo( ply, cmd )
	if not IsValid( ply ) then return end

	cmd = string.lower( cmd or JS.GetSelectedCommand( ply ) )
	local list = JS.GetSpawns( cmd )

	net.Start( "SWGRP_JobSpawnSync" )
		net.WriteString( cmd )
		net.WriteUInt( #list, 16 )
		for _, row in ipairs( list ) do
			net.WriteFloat( row.x or 0 )
			net.WriteFloat( row.y or 0 )
			net.WriteFloat( row.z or 0 )
			net.WriteFloat( row.pitch or row.p or 0 )
			net.WriteFloat( row.yaw or 0 )
			net.WriteFloat( row.roll or row.r or 0 )
		end
	net.Send( ply )
end

function JS.OpenMenu( ply )
	if not AdminAllowed( ply ) then return end

	local jobs = {}
	for teamId, job in pairs( SWGRP.Jobs or {} ) do
		table.insert( jobs, {
			team = teamId,
			command = string.lower( job.command or "" ),
			name = job.name or job.command or ( "Team " .. teamId ),
			count = JS.GetSpawnCount( job.command ),
		} )
	end

	table.sort( jobs, function( a, b )
		return string.lower( a.name ) < string.lower( b.name )
	end )

	net.Start( "SWGRP_JobSpawnMenu" )
		net.WriteString( JS.GetSelectedCommand( ply ) )
		net.WriteUInt( #jobs, 16 )
		for _, row in ipairs( jobs ) do
			net.WriteString( row.command )
			net.WriteString( row.name )
			net.WriteUInt( row.count, 16 )
		end
	net.Send( ply )

	JS.SyncTo( ply, JS.GetSelectedCommand( ply ) )
end

function JS.AddAtAim( ply )
	if not AdminAllowed( ply ) then return end

	local tr = ply:GetEyeTrace()
	if not tr.Hit then
		SWGRP.Notify( ply, "Aim at a valid surface." )
		return
	end

	local cmd = JS.GetSelectedCommand( ply )
	local pos = tr.HitPos + tr.HitNormal * 4
	local ang = Angle( 0, ply:EyeAngles().y, 0 )

	local ok, msg = JS.AddSpawn( ply, cmd, pos, ang )
	SWGRP.Notify( ply, msg, ok and 0 or 1 )
	JS.SyncTo( ply, cmd )
end

function JS.RemoveAtAim( ply )
	if not AdminAllowed( ply ) then return end

	local tr = ply:GetEyeTrace()
	local cmd = JS.GetSelectedCommand( ply )
	local ok, msg = JS.RemoveNearest( ply, cmd, tr.HitPos )
	SWGRP.Notify( ply, msg, ok and 0 or 1 )
	if ok then
		JS.SyncTo( ply, cmd )
	end
end

function JS.AdminToolPrimary( ply )
	JS.AddAtAim( ply )
end

function JS.AdminToolSecondary( ply )
	JS.OpenMenu( ply )
end

function JS.AdminToolReload( ply )
	JS.RemoveAtAim( ply )
end

hook.Add( "PlayerSpawn", "SWGRP_JobSpawnPlacement", function( ply )
	if not IsValid( ply ) then return end
	if ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then return end

	local pos, ang = JS.PickSpawn( ply:Team() )
	if not pos then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not ply:Alive() then return end
		ply:SetPos( pos )
		if ang then
			ply:SetEyeAngles( ang )
		end
	end )
end )

hook.Add( "InitPostEntity", "SWGRP_LoadJobSpawns", function()
	timer.Simple( 0, function()
		JS.Load()
		JS.ApplyAll()
	end )
end )

net.Receive( "SWGRP_JobSpawnAction", function( _, ply )
	if not AdminAllowed( ply ) then return end

	local action = net.ReadString()
	local cmd = string.lower( net.ReadString() )

	if action == "select" then
		if cmd == "" or not SWGRP.GetJobByCommand( cmd ) then
			SWGRP.Notify( ply, "Unknown profession." )
			return
		end
		JS.SetSelectedCommand( ply, cmd )
		SWGRP.Notify( ply, "Selected profession: " .. ( SWGRP.GetJobByCommand( cmd ).name or cmd ) )
		JS.SyncTo( ply, cmd )
		return
	end

	if action == "add_here" then
		JS.SetSelectedCommand( ply, cmd )
		JS.AddAtAim( ply )
		return
	end

	if action == "remove_nearest" then
		JS.SetSelectedCommand( ply, cmd )
		JS.RemoveAtAim( ply )
		return
	end

	if action == "clear" then
		local ok, msg = JS.ClearJob( cmd )
		SWGRP.Notify( ply, msg, ok and 0 or 1 )
		if ok then
			JS.SyncTo( ply, cmd )
		end
		return
	end

	if action == "refresh" then
		JS.SyncTo( ply, cmd )
	end
end )

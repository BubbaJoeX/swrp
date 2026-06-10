--[[---------------------------------------------------------------------------
    Job Management - Changing professions, votes, spawning
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JobsMgr = SWGRP.JobsMgr or {}

SWGRP.JobsMgr.ActiveVotes = SWGRP.JobsMgr.ActiveVotes or {}

function SWGRP.JobsMgr.GetJobModel( ply, teamId, modelIndex )
	local job = SWGRP.GetJob( teamId )
	if not job or not job.model then return nil end

	if isstring( job.model ) then
		return job.model
	end

	local models = SWGRP.GetJobModels( job )
	if #models == 0 then return nil end

	ply.SWGRP_JobModels = ply.SWGRP_JobModels or {}

	if modelIndex and modelIndex > 0 and modelIndex <= #models then
		ply.SWGRP_JobModels[teamId] = modelIndex
		return models[modelIndex]
	end

	local saved = ply.SWGRP_JobModels[teamId]
	if saved and models[saved] then
		return models[saved]
	end

	return models[math.random( #models )]
end

function SWGRP.JobsMgr.ApplyModel( ply, teamId, modelIndex )
	local mdl = SWGRP.JobsMgr.GetJobModel( ply, teamId, modelIndex )
	if mdl then
		ply:SetModel( mdl )
	end
end

function SWGRP.JobsMgr.CanBecomeJob( ply, teamId )
	local job = SWGRP.GetJob( teamId )
	if not job then return false, "Invalid profession." end

	if job.admin and job.admin > 0 then
		if not ply:IsAdmin() then return false, "Admin only profession." end
	end

	if job.max and job.max > 0 and SWGRP.JobCount( teamId ) >= job.max then
		return false, SWGRP.Lang.job_full
	end

	if job.needToChangeFrom then
		if ply:Team() ~= job.needToChangeFrom then
			return false, "You must be the required profession first."
		end
	end

	if job.customCheck and not job.customCheck( ply ) then
		return false, "You cannot take this profession."
	end

	return true
end

function SWGRP.JobsMgr.SetJob( ply, teamId, force, modelIndex )
	local can, reason = SWGRP.JobsMgr.CanBecomeJob( ply, teamId )
	if not can and not force then
		SWGRP.Notify( ply, reason )
		return false
	end

	local hookOk, hookReason = SWGRP.Hooks.CallCan( "SWGRPCanChangeJob", true, ply, teamId )
	if not hookOk and not force then
		SWGRP.Notify( ply, hookReason or "Cannot change profession." )
		return false
	end

	local job = SWGRP.GetJob( teamId )
	if not job then return false end

	ply:SetTeam( teamId )
	ply.SWGRP_LastTeam = teamId

	if job.hasLicense then
		ply:SWGRP_SetLicense( true )
	end

	ply:Spawn()

	if SWGRP.GrantJobWeapons then
		timer.Simple( 0, function()
			if IsValid( ply ) then
				SWGRP.GrantJobWeapons( ply )
			end
		end )
	end

	SWGRP.JobsMgr.ApplyModel( ply, teamId, modelIndex )
	SWGRP.Profession.Sync( ply )
	SWGRP.Persistence.SaveNow( ply )
	SWGRP.Notify( ply, string.format( SWGRP.Lang.job_changed, job.name ) )
	SWGRP.Hooks.Call( "SWGRPJobChanged", ply, teamId, job )
	return true
end

function SWGRP.JobsMgr.StartVote( ply, teamId, modelIndex )
	local job = SWGRP.GetJob( teamId )
	if not job or not job.vote then
		return SWGRP.JobsMgr.SetJob( ply, teamId, false, modelIndex )
	end

	local can, reason = SWGRP.JobsMgr.CanBecomeJob( ply, teamId )
	if not can then
		SWGRP.Notify( ply, reason )
		return
	end

	-- Enforce whitelist/custom job restrictions before a vote can even start,
	-- otherwise a passing vote (force=true) would bypass them.
	local hookOk, hookReason = SWGRP.Hooks.CallCan( "SWGRPCanChangeJob", true, ply, teamId )
	if not hookOk then
		SWGRP.Notify( ply, hookReason or "Cannot change profession." )
		return
	end

	SWGRP.JobsMgr.ActiveVotes[ply] = {
		team = teamId,
		modelIndex = modelIndex or 0,
		yes = 0,
		no = 0,
		voters = {},
		endTime = CurTime() + 30,
	}

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.job_vote_started, job.name ) )
	end

	net.Start( "SWGRP_OpenVote" )
		net.WriteString( "job" )
		net.WriteEntity( ply )
		net.WriteString( job.name )
		net.WriteFloat( CurTime() + 30 )
	net.Broadcast()

	timer.Create( "SWGRP_JobVote_" .. ply:SteamID64(), 30, 1, function()
		local vote = SWGRP.JobsMgr.ActiveVotes[ply]
		if not vote then return end
		if IsValid( ply ) and vote.yes > vote.no then
			SWGRP.JobsMgr.SetJob( ply, vote.team, true, vote.modelIndex )
		end
		SWGRP.JobsMgr.ActiveVotes[ply] = nil
	end )
end

concommand.Add( "swgrp_setjob", function( ply, cmd, args )
	if not IsValid( ply ) then return end
	local teamId = tonumber( args[1] )
	if teamId then SWGRP.JobsMgr.StartVote( ply, teamId ) end
end )

net.Receive( "SWGRP_OpenF4", function( len, ply )
	-- Client opens F4 locally; server handles purchases via other nets
end )

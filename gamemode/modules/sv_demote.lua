--[[---------------------------------------------------------------------------
    Demote Vote System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Demote = SWGRP.Demote or {}

SWGRP.Demote.Active = SWGRP.Demote.Active or {}

function SWGRP.Demote.StartVote( initiator, target )
	if not IsValid( initiator ) or not IsValid( target ) then return end
	if target == initiator then return end
	if SWGRP.Demote.Active[target] then return end

	SWGRP.Demote.Active[target] = {
		initiator = initiator,
		yes = 0,
		no = 0,
		voters = {},
		endTime = CurTime() + SWGRP.Config.DemoteTime,
	}

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.demote_started, target:Nick() ) )
	end

	net.Start( "SWGRP_OpenVote" )
		net.WriteString( "demote" )
		net.WriteEntity( target )
		net.WriteString( "Demote " .. target:Nick() )
		net.WriteFloat( CurTime() + SWGRP.Config.DemoteTime )
	net.Broadcast()

	timer.Create( "SWGRP_Demote_" .. target:SteamID64(), SWGRP.Config.DemoteTime, 1, function()
		local vote = SWGRP.Demote.Active[target]
		if not vote or not IsValid( target ) then return end

		local needed = math.ceil( player.GetCount() * SWGRP.Config.DemoteVotesNeeded )
		if vote.yes >= needed then
			SWGRP.JobsMgr.SetJob( target, TEAM_COLONIST, true )
		end
		SWGRP.Demote.Active[target] = nil
	end )
end


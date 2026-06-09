--[[---------------------------------------------------------------------------
    Vote Ban System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.VoteBan = SWGRP.VoteBan or {}
SWGRP.VoteBan.Active = SWGRP.VoteBan.Active or {}

function SWGRP.VoteBan.Start( initiator, target )
	if not IsValid( initiator ) or not IsValid( target ) then return end
	if target == initiator then return end
	if target:IsAdmin() then
		SWGRP.Notify( initiator, "Cannot voteban an admin." )
		return
	end
	if SWGRP.VoteBan.Active[target] then return end

	local duration = SWGRP.Config.VoteBanTime or 60

	SWGRP.VoteBan.Active[target] = {
		initiator = initiator,
		yes = 0,
		no = 0,
		voters = {},
		endTime = CurTime() + duration,
	}

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( "[Voteban] %s initiated voteban against %s.", initiator:Nick(), target:Nick() ) )
	end

	net.Start( "SWGRP_OpenVote" )
		net.WriteString( "voteban" )
		net.WriteEntity( target )
		net.WriteString( "Ban " .. target:Nick() )
		net.WriteFloat( CurTime() + duration )
	net.Broadcast()

	timer.Create( "SWGRP_VoteBan_" .. target:SteamID64(), duration, 1, function()
		local vote = SWGRP.VoteBan.Active[target]
		if not vote or not IsValid( target ) then return end

		local needed = math.ceil( player.GetCount() * ( SWGRP.Config.VoteBanVotesNeeded or 0.66 ) )
		if vote.yes >= needed then
			for _, p in ipairs( player.GetAll() ) do
				p:ChatPrint( target:Nick() .. " was votebanned from the colony." )
			end
			target:Kick( "Votebanned by colony vote." )
		end

		SWGRP.VoteBan.Active[target] = nil
	end )
end

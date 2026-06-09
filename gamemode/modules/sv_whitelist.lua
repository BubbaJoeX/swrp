--[[---------------------------------------------------------------------------
    Job Whitelist - admin-managed access to flagged professions
    Jobs with the `whitelist` flag require the player to be whitelisted.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Whitelist = SWGRP.Whitelist or {}

sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_whitelist (
	steamid TEXT NOT NULL,
	job TEXT NOT NULL,
	PRIMARY KEY ( steamid, job )
)]] )

function SWGRP.Whitelist.Has( steamid, jobCommand )
	jobCommand = string.lower( jobCommand or "" )
	local row = sql.QueryRow( string.format(
		"SELECT 1 FROM swgrp_whitelist WHERE steamid = %s AND job = %s",
		sql.SQLStr( steamid ),
		sql.SQLStr( jobCommand )
	) )
	return row ~= nil and row ~= false
end

function SWGRP.Whitelist.Add( steamid, jobCommand )
	jobCommand = string.lower( jobCommand or "" )
	sql.Query( string.format(
		"REPLACE INTO swgrp_whitelist ( steamid, job ) VALUES ( %s, %s )",
		sql.SQLStr( steamid ),
		sql.SQLStr( jobCommand )
	) )
end

function SWGRP.Whitelist.Remove( steamid, jobCommand )
	jobCommand = string.lower( jobCommand or "" )
	sql.Query( string.format(
		"DELETE FROM swgrp_whitelist WHERE steamid = %s AND job = %s",
		sql.SQLStr( steamid ),
		sql.SQLStr( jobCommand )
	) )
end

-- Deny whitelisted jobs to players who are not on the list (admins bypass).
hook.Add( "SWGRPCanChangeJob", "SWGRP_WhitelistGate", function( ply, teamId )
	local job = SWGRP.GetJob( teamId )
	if not job or not job.whitelist then return end
	if ply:IsAdmin() then return end

	if not SWGRP.Whitelist.Has( ply:SteamID(), job.command ) then
		return { false, "This profession is whitelist-only. Ask an administrator for access." }
	end
end )

local function resolveJobCommand( arg )
	arg = string.lower( arg or "" )
	local job = SWGRP.GetJobByCommand( arg )
	if job then return arg end
	return nil
end

SWGRP.RegisterChatCommand( "whitelist", {
	description = "Whitelist a player for a profession (admin)",
	execute = function( ply, args )
		if IsValid( ply ) and not ply:IsAdmin() then
			SWGRP.Notify( ply, "Administrators only." )
			return
		end

		local target = SWGRP.FindPlayer( args[1] )
		local jobCmd = resolveJobCommand( args[2] )
		if not IsValid( target ) or not jobCmd then
			SWGRP.Notify( ply, "Usage: /whitelist <player> <job command>" )
			return
		end

		SWGRP.Whitelist.Add( target:SteamID(), jobCmd )
		SWGRP.Notify( ply, "Whitelisted " .. target:Nick() .. " for '" .. jobCmd .. "'." )
		SWGRP.Notify( target, "You have been whitelisted for the '" .. jobCmd .. "' profession." )
		SWGRP.Log( "admin", ( IsValid( ply ) and ply:Nick() or "Console" ) .. " whitelisted " .. target:Nick() .. " for " .. jobCmd )
	end,
})

SWGRP.RegisterChatCommand( "unwhitelist", {
	description = "Remove a player's profession whitelist (admin)",
	execute = function( ply, args )
		if IsValid( ply ) and not ply:IsAdmin() then
			SWGRP.Notify( ply, "Administrators only." )
			return
		end

		local target = SWGRP.FindPlayer( args[1] )
		local jobCmd = resolveJobCommand( args[2] )
		if not IsValid( target ) or not jobCmd then
			SWGRP.Notify( ply, "Usage: /unwhitelist <player> <job command>" )
			return
		end

		SWGRP.Whitelist.Remove( target:SteamID(), jobCmd )
		SWGRP.Notify( ply, "Removed " .. target:Nick() .. "'s whitelist for '" .. jobCmd .. "'." )
		SWGRP.Log( "admin", ( IsValid( ply ) and ply:Nick() or "Console" ) .. " unwhitelisted " .. target:Nick() .. " from " .. jobCmd )
	end,
})

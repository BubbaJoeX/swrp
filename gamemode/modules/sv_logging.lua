--[[---------------------------------------------------------------------------
    RP Action Logging (DarkRP-style logging to file)
    Writes daily logs to data/swgrp_logs/YYYY-MM-DD.txt
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Logging = SWGRP.Logging or {}

local LOG_DIR = "swgrp_logs"

local CATEGORY_COLOR = {
	job      = Color( 80, 200, 255 ),
	economy  = Color( 255, 200, 50 ),
	law      = Color( 255, 120, 60 ),
	death    = Color( 255, 80, 80 ),
	admin    = Color( 200, 120, 255 ),
	chat     = Color( 180, 180, 180 ),
	system   = Color( 120, 200, 120 ),
}

function SWGRP.Logging.Enabled()
	return not SWGRP.Config or not SWGRP.Config.LoggingEnabled or SWGRP.Config.LoggingEnabled:GetBool()
end

function SWGRP.Log( category, text )
	if not SWGRP.Logging.Enabled() then return end

	category = string.lower( category or "system" )
	local stamp = os.date( "%H:%M:%S" )
	local line = string.format( "[%s] [%s] %s", stamp, string.upper( category ), text )

	if not file.IsDir( LOG_DIR, "DATA" ) then
		file.CreateDir( LOG_DIR )
	end

	local path = LOG_DIR .. "/" .. os.date( "%Y-%m-%d" ) .. ".txt"
	file.Append( path, line .. "\n" )

	MsgC( CATEGORY_COLOR[category] or color_white, "[SWGRP-LOG] " .. line .. "\n" )
end

-- Convenience for an actor/target style entry.
local function nameId( ply )
	if not IsValid( ply ) then return "World" end
	return ply:Nick() .. " (" .. ply:SteamID() .. ")"
end

hook.Add( "SWGRPJobChanged", "SWGRP_LogJob", function( ply, teamId, job )
	SWGRP.Log( "job", nameId( ply ) .. " became " .. ( job and job.name or tostring( teamId ) ) )
end )

hook.Add( "SWGRPPlayerArrested", "SWGRP_LogArrest", function( target, actor )
	SWGRP.Log( "law", nameId( actor ) .. " arrested " .. nameId( target ) )
end )

hook.Add( "SWGRPPlayerUnarrested", "SWGRP_LogUnarrest", function( target, actor )
	SWGRP.Log( "law", nameId( actor ) .. " released " .. nameId( target ) )
end )

hook.Add( "SWGRPPlayerWanted", "SWGRP_LogWanted", function( target, reason, actor )
	SWGRP.Log( "law", nameId( actor ) .. " marked " .. nameId( target ) .. " wanted: " .. ( reason or "" ) )
end )

hook.Add( "PlayerDeath", "SWGRP_LogDeath", function( victim, inflictor, attacker )
	local attackerName = IsValid( attacker ) and attacker:IsPlayer() and nameId( attacker ) or tostring( IsValid( attacker ) and attacker:GetClass() or "world" )
	SWGRP.Log( "death", nameId( victim ) .. " was killed by " .. attackerName )
end )

hook.Add( "SWGRPEntityPurchased", "SWGRP_LogPurchase", function( ply, what, price )
	SWGRP.Log( "economy", nameId( ply ) .. " purchased " .. tostring( what ) .. " for " .. SWGRP.FormatCredits( price or 0 ) )
end )

hook.Add( "PlayerInitialSpawn", "SWGRP_LogConnect", function( ply )
	SWGRP.Log( "system", nameId( ply ) .. " connected" )
end )

hook.Add( "PlayerDisconnected", "SWGRP_LogDisconnect", function( ply )
	SWGRP.Log( "system", nameId( ply ) .. " disconnected" )
end )

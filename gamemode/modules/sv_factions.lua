--[[---------------------------------------------------------------------------
    Faction Standing - Imperial / Rebel / Underworld
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Factions = SWGRP.Factions or {}

function SWGRP.Factions.Get( ply, faction )
	return ply.SWGRP_Factions and ply.SWGRP_Factions[faction] or 0
end

function SWGRP.Factions.Set( ply, faction, value )
	ply.SWGRP_Factions = ply.SWGRP_Factions or { imperial = 0, rebel = 0, underworld = 0 }
	ply.SWGRP_Factions[faction] = math.Clamp( math.floor( value ), SWGRP.Config.FactionMin, SWGRP.Config.FactionMax )
	ply:SetNWInt( "SWGRP_Faction_" .. faction, ply.SWGRP_Factions[faction] )
	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
end

function SWGRP.Factions.Add( ply, faction, amount )
	SWGRP.Factions.Set( ply, faction, SWGRP.Factions.Get( ply, faction ) + amount )
end

function SWGRP.Factions.ApplyGains( ply, gains )
	if not gains then return end
	for faction, amount in pairs( gains ) do
		SWGRP.Factions.Add( ply, faction, amount )
	end
end

function SWGRP.Factions.SyncAll( ply )
	for _, f in ipairs( { "imperial", "rebel", "underworld" } ) do
		ply:SetNWInt( "SWGRP_Faction_" .. f, SWGRP.Factions.Get( ply, f ) )
	end
end

function SWGRP.Factions.GetStandingLabel( value )
	if value >= 50 then return "Allied"
	elseif value >= 20 then return "Friendly"
	elseif value >= -20 then return "Neutral"
	elseif value >= -50 then return "Unfriendly"
	else return "Hostile" end
end

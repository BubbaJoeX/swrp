--[[---------------------------------------------------------------------------
    Profession XP & Leveling
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Profession = SWGRP.Profession or {}

function SWGRP.Profession.GetXP( ply, teamId )
	teamId = teamId or ply:Team()
	ply.SWGRP_ProfessionXP = ply.SWGRP_ProfessionXP or {}
	return ply.SWGRP_ProfessionXP[teamId] or 0
end

function SWGRP.Profession.GetLevel( ply, teamId )
	local xp = SWGRP.Profession.GetXP( ply, teamId )
	return math.min( SWGRP.Config.MaxProfessionLevel, math.floor( xp / SWGRP.Config.XPPerLevel ) + 1 )
end

function SWGRP.Profession.AddXP( ply, amount, teamId )
	teamId = teamId or ply:Team()
	ply.SWGRP_ProfessionXP = ply.SWGRP_ProfessionXP or {}
	local oldLevel = SWGRP.Profession.GetLevel( ply, teamId )
	ply.SWGRP_ProfessionXP[teamId] = ( ply.SWGRP_ProfessionXP[teamId] or 0 ) + amount
	local newLevel = SWGRP.Profession.GetLevel( ply, teamId )

	ply:SetNWInt( "SWGRP_ProfLevel", newLevel )
	ply:SetNWInt( "SWGRP_ProfXP", ply.SWGRP_ProfessionXP[ply:Team()] or 0 )

	if newLevel > oldLevel then
		SWGRP.Notify( ply, "Profession level up! Now level " .. newLevel )
	end

	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
end

function SWGRP.Profession.Sync( ply )
	ply:SetNWInt( "SWGRP_ProfLevel", SWGRP.Profession.GetLevel( ply ) )
	ply:SetNWInt( "SWGRP_ProfXP", SWGRP.Profession.GetXP( ply ) )
end

--[[---------------------------------------------------------------------------
    Player Spawn & Connect Hooks
---------------------------------------------------------------------------]]

local function SWGRP_GiveAmmoForWeapons( ply )
	local ammoGiven = {}
	for _, wep in ipairs( ply:GetWeapons() ) do
		local primary = wep:GetPrimaryAmmoType()
		local secondary = wep:GetSecondaryAmmoType()

		if primary >= 0 and not ammoGiven[primary] then
			ply:GiveAmmo( 120, primary, true )
			ammoGiven[primary] = true
		end

		if secondary >= 0 and not ammoGiven[secondary] then
			ply:GiveAmmo( 120, secondary, true )
			ammoGiven[secondary] = true
		end
	end
end

function SWGRP.GiveJobLoadout( ply )
	if not IsValid( ply ) then return end

	if ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then
		ply:StripWeapons()
		ply:RemoveAllAmmo()
		return
	end

	-- Everyone always carries their keys.
	if not ply:HasWeapon( "swgrp_keys" ) then
		ply:Give( "swgrp_keys" )
	end

	local job = SWGRP.GetJob( ply:Team() )
	if job and job.weapons then
		for _, wep in ipairs( job.weapons ) do
			if not ply:HasWeapon( wep ) then
				ply:Give( wep )
			end
		end
	end

	if job and job.ammo then
		for ammoType, amount in pairs( job.ammo ) do
			ply:SetAmmo( amount, ammoType )
		end
	end

	for _, wep in pairs( GAMEMODE.Config.DefaultWeapons or {} ) do
		if not ply:HasWeapon( wep ) then
			ply:Give( wep )
		end
	end

	CAMI.PlayerHasAccess( ply, "SWGRP_GetAdminWeapons", function( access )
		if not access or not IsValid( ply ) then return end

		for _, wep in pairs( GAMEMODE.Config.AdminWeapons or {} ) do
			if not ply:HasWeapon( wep ) then
				ply:Give( wep )
			end
		end
	end )

	SWGRP_GiveAmmoForWeapons( ply )

	if SWGRP.Pocket and SWGRP.Pocket.Restore then
		SWGRP.Pocket.Restore( ply )
	end

	if SWGRP.GiveSandboxTools then
		SWGRP.GiveSandboxTools( ply )
	end

	if ply:HasWeapon( "swgrp_keys" ) then
		ply:SelectWeapon( "swgrp_keys" )
	elseif #ply:GetWeapons() > 0 then
		ply:SwitchToDefaultWeapon()
	end
end

function GM:PlayerLoadout( ply )
	player_manager.RunClass( ply, "Loadout" )
	SWGRP.GiveJobLoadout( ply )
end

function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "player_swgrp" )

	local job = SWGRP.GetJob( ply:Team() )
	if job and job.PlayerSpawn then
		job.PlayerSpawn( ply )
	end

	ply:SetHealth( 100 )
	ply:SetArmor( 0 )
end

hook.Add( "PlayerInitialSpawn", "SWGRP_LoadPlayer", function( ply )
	SWGRP.DB.LoadPlayer( ply )
	ply.SWGRP_PropCount = 0
	ply.SWGRP_DoorCount = 0

	timer.Simple( 0, function()
		if not IsValid( ply ) then return end
		local teamId = ply.SWGRP_LastTeam or TEAM_COLONIST
		if SWGRP.Jobs[teamId] then
			ply:SetTeam( teamId )
		else
			ply:SetTeam( TEAM_COLONIST )
		end
	end )
end )

hook.Add( "PlayerDisconnected", "SWGRP_SavePlayer", function( ply )
	SWGRP.Persistence.SaveNow( ply )
end )

-- Safety net: keep keys on every living, non-detained player at all times.
timer.Create( "SWGRP_EnsureKeys", 5, 0, function()
	for _, ply in ipairs( player.GetAll() ) do
		if IsValid( ply ) and ply:Alive()
			and not ply:SWGRP_IsArrested() and not ply:SWGRP_IsRestrained()
			and not ply:HasWeapon( "swgrp_keys" ) then
			ply:Give( "swgrp_keys" )
		end
	end
end )

hook.Add( "PlayerSpawnProp", "SWGRP_PropLimit", function( ply )
	local limit = SWGRP.Config.PropLimit:GetInt()
	ply.SWGRP_PropCount = ply.SWGRP_PropCount or 0
	if ply.SWGRP_PropCount >= limit then
		SWGRP.Notify( ply, "Prop limit reached (" .. limit .. ")." )
		return false
	end
	ply.SWGRP_PropCount = ply.SWGRP_PropCount + 1
end )

function GM:PlayerSetModel( ply )
	if SWGRP.JobsMgr and SWGRP.JobsMgr.ApplyModel then
		SWGRP.JobsMgr.ApplyModel( ply, ply:Team() )
	else
		local job = SWGRP.GetJob( ply:Team() )
		if job and job.model then
			local mdl = istable( job.model ) and job.model[math.random( #job.model )] or job.model
			ply:SetModel( mdl )
		end
	end
end

function GM:ShowSpare2( ply )
	if not IsValid( ply ) then return end
	ply:SendLua( "GAMEMODE:ShowSpare2()" )
end

function GM:ShowSpare1( ply )
	if not IsValid( ply ) then return end
	ply:SendLua( "GAMEMODE:ShowSpare1()" )
end

function GM:ShowHelp( ply )
	if not IsValid( ply ) then return end
	ply:SendLua( "GAMEMODE:ShowHelp()" )
end

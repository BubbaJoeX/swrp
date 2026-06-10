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

function SWGRP.GrantWeapon( ply, class )
	if not IsValid( ply ) or not class or class == "" or not weapons.Get( class ) then return false end

	ply.SWGRP_GrantedWeapons = ply.SWGRP_GrantedWeapons or {}
	ply.SWGRP_GrantedWeapons[class] = true

	ply.SWGRP_SkipSpawnAllowlistGive = class
	ply:Give( class )
	ply.SWGRP_SkipSpawnAllowlistGive = nil

	if not ply:HasWeapon( class ) then return false end

	local wep = ply:GetWeapon( class )
	if IsValid( wep ) then
		local primary = wep:GetPrimaryAmmoType()
		local secondary = wep:GetSecondaryAmmoType()
		if primary >= 0 and ply:GetAmmoCount( primary ) <= 0 then
			ply:GiveAmmo( 90, primary, true )
		end
		if secondary >= 0 and ply:GetAmmoCount( secondary ) <= 0 then
			ply:GiveAmmo( 90, secondary, true )
		end
	end

	return true
end

function SWGRP.BuildAllowedLoadout( ply )
	local allowed = {}
	local cfg = GAMEMODE.Config or SWGRP.Config or {}

	local function add( class )
		if class and class ~= "" then
			allowed[class] = true
		end
	end

	add( "swgrp_keys" )

	local job = SWGRP.GetJob( ply:Team() )
	if job and job.weapons then
		for _, wep in ipairs( job.weapons ) do
			add( wep )
		end
	end

	for _, wep in ipairs( cfg.DefaultWeapons or {} ) do
		add( wep )
	end

	if ply.SWGRP_GrantedWeapons then
		for class in pairs( ply.SWGRP_GrantedWeapons ) do
			add( class )
		end
	end

	if ply:IsAdmin() then
		for _, wep in ipairs( cfg.AdminWeapons or {} ) do
			add( wep )
		end
	end

	return allowed, job, cfg
end

function SWGRP.EnforceLoadout( ply )
	if not IsValid( ply ) then return end

	if ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then
		ply:StripWeapons()
		ply:RemoveAllAmmo()
		return
	end

	local allowed, job, cfg = SWGRP.BuildAllowedLoadout( ply )

	-- Remove anything not on the loadout whitelist (Q-menu spawns, save restores, etc.)
	for _, wep in ipairs( ply:GetWeapons() ) do
		if not allowed[wep:GetClass()] then
			ply:StripWeapon( wep:GetClass() )
		end
	end

	ply.SWGRP_SkipSpawnAllowlistGive = "swgrp_keys"
	ply:Give( "swgrp_keys" )
	ply.SWGRP_SkipSpawnAllowlistGive = nil

	if job and job.weapons then
		for _, wep in ipairs( job.weapons ) do
			if not ply:HasWeapon( wep ) then
				ply.SWGRP_SkipSpawnAllowlistGive = wep
				ply:Give( wep )
				ply.SWGRP_SkipSpawnAllowlistGive = nil
			end
		end
	end

	if ply.SWGRP_GrantedWeapons then
		for class in pairs( ply.SWGRP_GrantedWeapons ) do
			if not ply:HasWeapon( class ) then
				ply.SWGRP_SkipSpawnAllowlistGive = class
				ply:Give( class )
				ply.SWGRP_SkipSpawnAllowlistGive = nil
			end
		end
	end

	if job and job.ammo then
		for ammoType, amount in pairs( job.ammo ) do
			ply:SetAmmo( amount, ammoType )
		end
	end

	for _, wep in ipairs( cfg.DefaultWeapons or {} ) do
		if not ply:HasWeapon( wep ) then
			ply.SWGRP_SkipSpawnAllowlistGive = wep
			ply:Give( wep )
			ply.SWGRP_SkipSpawnAllowlistGive = nil
		end
	end

	local function finalizeLoadout()
		if not IsValid( ply ) then return end

		SWGRP_GiveAmmoForWeapons( ply )

		if SWGRP.Pocket and SWGRP.Pocket.Restore then
			SWGRP.Pocket.Restore( ply )
		end

		if SWGRP.GiveSandboxTools then
			SWGRP.GiveSandboxTools( ply )
		end

		for _, wep in ipairs( ply:GetWeapons() ) do
			if not allowed[wep:GetClass()] then
				ply:StripWeapon( wep:GetClass() )
			end
		end

		if ply:HasWeapon( "swgrp_keys" ) then
			ply:SelectWeapon( "swgrp_keys" )
		elseif #ply:GetWeapons() > 0 then
			ply:SwitchToDefaultWeapon()
		end
	end

	if CAMI and CAMI.PlayerHasAccess then
		CAMI.PlayerHasAccess( ply, "SWGRP_GetAdminWeapons", function( access )
			if not IsValid( ply ) then return end
			if access then
				for _, wep in ipairs( cfg.AdminWeapons or {} ) do
					allowed[wep] = true
					if not ply:HasWeapon( wep ) then
						ply.SWGRP_SkipSpawnAllowlistGive = wep
						ply:Give( wep )
						ply.SWGRP_SkipSpawnAllowlistGive = nil
					end
				end
			end
			finalizeLoadout()
		end )
	else
		if ply:IsAdmin() then
			for _, wep in ipairs( cfg.AdminWeapons or {} ) do
				allowed[wep] = true
				if not ply:HasWeapon( wep ) then
					ply.SWGRP_SkipSpawnAllowlistGive = wep
					ply:Give( wep )
					ply.SWGRP_SkipSpawnAllowlistGive = nil
				end
			end
		end
		finalizeLoadout()
	end
end

function SWGRP.GiveJobLoadout( ply )
	SWGRP.EnforceLoadout( ply )
end

local function SWGRP_ScheduleLoadoutEnforce( ply )
	if not IsValid( ply ) then return end
	for _, delay in ipairs( { 0, 0.25, 1, 3 } ) do
		timer.Simple( delay, function()
			if IsValid( ply ) and ply:Alive() then
				SWGRP.EnforceLoadout( ply )
			end
		end )
	end
end

function GM:PlayerLoadout( ply )
	player_manager.RunClass( ply, "Loadout" )
	SWGRP.GiveJobLoadout( ply )
end

-- Run gamemode_base PlayerSpawn (unspectate, loadout, model). Must not call
-- gamemode_sandbox.PlayerSpawn — that resets the player class to player_sandbox.
local function SWGRP_RunBasePlayerSpawn( ply, transition )
	local gm = GAMEMODE or GM
	local baseSpawn = gm.Sandbox and gm.Sandbox.BaseClass and gm.Sandbox.BaseClass.PlayerSpawn

	if baseSpawn then
		baseSpawn( gm, ply, transition )
		-- Base spawn skips loadout on map transitions; SWGRP always reapplies weapons.
		if transition then
			hook.Call( "PlayerLoadout", gm, ply )
		end
		return
	end

	ply:UnSpectate()
	player_manager.OnPlayerSpawn( ply, transition )
	player_manager.RunClass( ply, "Spawn" )
	hook.Call( "PlayerLoadout", gm, ply )
	hook.Call( "PlayerSetModel", gm, ply )
	ply:SetupHands()
end

function GM:PlayerSpawn( ply, transition )
	player_manager.SetPlayerClass( ply, "player_swgrp" )
	SWGRP_RunBasePlayerSpawn( ply, transition )

	local job = SWGRP.GetJob( ply:Team() )
	if job and job.PlayerSpawn then
		job.PlayerSpawn( ply )
	end

	ply:SetHealth( 100 )
	ply:SetArmor( 0 )
end

local function SWGRP_AssignTeam( ply )
	local teamId = ply.SWGRP_LastTeam or TEAM_COLONIST
	if SWGRP.Jobs[teamId] then
		ply:SetTeam( teamId )
	else
		ply:SetTeam( TEAM_COLONIST )
	end
end

hook.Add( "PlayerInitialSpawn", "SWGRP_LoadPlayer", function( ply )
	SWGRP.DB.LoadPlayer( ply )
	ply.SWGRP_PropCount = 0
	ply.SWGRP_DoorCount = 0

	-- SQLite may still hold pocket weapons from a prior session; drop them on join.
	if SWGRP.Pocket and SWGRP.Pocket.ClearWeaponSlots then
		SWGRP.Pocket.ClearWeaponSlots( ply )
	end

	-- Assign profession before the first PlayerSpawn/PlayerLoadout so job weapons apply.
	SWGRP_AssignTeam( ply )

	-- Singleplayer saves / late entity restores can re-add weapons after spawn.
	SWGRP_ScheduleLoadoutEnforce( ply )
end )

hook.Add( "PlayerSpawn", "SWGRP_EnforceLoadoutDeferred", function( ply )
	SWGRP_ScheduleLoadoutEnforce( ply )
end )

-- gm_save / continue loads can restore weapons after PlayerLoadout runs.
hook.Add( "LoadGModSave", "SWGRP_EnforceLoadoutAfterSave", function()
	timer.Simple( 0.5, function()
		for _, ply in ipairs( player.GetAll() ) do
			if IsValid( ply ) then
				SWGRP.EnforceLoadout( ply )
			end
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
			ply.SWGRP_SkipSpawnAllowlistGive = "swgrp_keys"
			ply:Give( "swgrp_keys" )
			ply.SWGRP_SkipSpawnAllowlistGive = nil
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

--[[---------------------------------------------------------------------------
    Server energy cell ammo — weapon patching, consumption, reload hooks
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}

local HL2_AMMO_TYPES = {
	"ar2", "ar2altfire", "pistol", "smg1", "357", "xbowbolt", "buckshot",
	"rpg_round", "sniperround", "sniperpenetratedround", "grenade", "slam",
}

local function SWGRP_AmmoActiveBlasterClass( ply )
	local wep = ply:GetActiveWeapon()
	if IsValid( wep ) and SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then
		return wep:GetClass()
	end
	return nil
end

function SWGRP.Ammo.RegisterEnergyAmmoType()
	if game.GetAmmoID( SWGRP.Ammo.ENERGY_AMMO ) > 0 then return end

	game.AddAmmoType( {
		name = SWGRP.Ammo.ENERGY_AMMO,
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		plydmg = 0,
		npcdmg = 0,
		force = 2000,
		maxcarry = 9999,
	} )
end

function SWGRP.Ammo.MigrateLegacyAmmo( ply )
	if not IsValid( ply ) then return end

	local energyName = SWGRP.Ammo.ENERGY_AMMO
	local converted = 0

	for _, ammoName in ipairs( HL2_AMMO_TYPES ) do
		local count = ply:GetAmmoCount( ammoName )
		if count > 0 then
			ply:RemoveAmmo( count, ammoName )
			converted = converted + count
		end
	end

	if converted > 0 then
		ply:GiveAmmo( converted, energyName, true )
	end
end

function SWGRP.Ammo.MigrateWeaponAmmo( ply, wep )
	if not IsValid( ply ) or not IsValid( wep ) then return end
	if not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return end

	local ammoType = wep:GetPrimaryAmmoType()
	local energyId = SWGRP.Ammo.GetEnergyAmmoID()
	if ammoType < 0 or ammoType == energyId then return end

	local ammoName = game.GetAmmoName( ammoType )
	if not ammoName or ammoName == SWGRP.Ammo.ENERGY_AMMO then return end

	local reserve = ply:GetAmmoCount( ammoType )
	local clip = math.max( 0, wep:Clip1() )
	if reserve > 0 then
		ply:RemoveAmmo( reserve, ammoName )
	end
	if clip > 0 then
		wep:SetClip1( 0 )
	end

	local total = reserve + clip
	if total > 0 then
		SWGRP.Ammo.LoadWeaponFromRounds( ply, wep:GetClass(), total )
	end
end

function SWGRP.Ammo.EnsureReserveFromCells( ply, wep )
	if not IsValid( ply ) or not IsValid( wep ) then return 0 end
	if not SWGRP.Ammo.UsesEnergyCells( wep:GetClass() ) then return 0 end

	local maxClip = wep:GetMaxClip1()
	if not maxClip or maxClip <= 0 then return 0 end

	local needed = maxClip - wep:Clip1()
	if needed <= 0 then return 0 end

	local energyId = SWGRP.Ammo.GetEnergyAmmoID()
	local reserve = energyId >= 0 and ply:GetAmmoCount( energyId ) or 0
	local perCell = SWGRP.Ammo.RoundsPerCell()
	local opened = 0

	while reserve < needed and SWGRP.Materials.Get( ply, "energy_cell" ) > 0 do
		SWGRP.Materials.Take( ply, { energy_cell = 1 } )
		ply:GiveAmmo( perCell, SWGRP.Ammo.ENERGY_AMMO, true )
		reserve = reserve + perCell
		opened = opened + 1
	end

	return opened
end

function SWGRP.Ammo.ReconcilePlayer( ply )
	if not IsValid( ply ) then return end

	SWGRP.Ammo.MigrateLegacyAmmo( ply )

	for _, wep in ipairs( ply:GetWeapons() ) do
		SWGRP.Ammo.MigrateWeaponAmmo( ply, wep )
	end
end

function SWGRP.Ammo.UseWorldCell( ply )
	if not IsValid( ply ) then return false end

	local class = SWGRP_AmmoActiveBlasterClass( ply )
	if not class then
		SWGRP.Notify( ply, "Equip a blaster to load this energy cell." )
		return false
	end

	local given = SWGRP.Ammo.GiveCellsAsRounds( ply, 1, class )
	if given <= 0 then
		SWGRP.Notify( ply, "Could not load that energy cell." )
		return false
	end

	SWGRP.Notify( ply, string.format(
		"Loaded %d rounds from energy cell (%d per cell).",
		given,
		SWGRP.Ammo.RoundsPerCell()
	) )
	return true
end

function SWGRP.Ammo.UseDeployedCell( ply )
	return SWGRP.Ammo.UseWorldCell( ply )
end

function SWGRP.Ammo.UseMaterialCell( ply, classFilter )
	if not IsValid( ply ) then return false end

	if SWGRP.Materials.Get( ply, "energy_cell" ) < 1 then
		SWGRP.Notify( ply, "You have no energy cells." )
		return false
	end

	SWGRP.Materials.Take( ply, { energy_cell = 1 } )

	local given = SWGRP.Ammo.GiveCellsAsRounds( ply, 1, classFilter or SWGRP_AmmoActiveBlasterClass( ply ) )
	if given <= 0 then
		SWGRP.Materials.Add( ply, "energy_cell", 1 )
		SWGRP.Notify( ply, "Equip a blaster to load an energy cell." )
		return false
	end

	SWGRP.Notify( ply, string.format(
		"Loaded %d rounds from energy cell (%d per cell).",
		given,
		SWGRP.Ammo.RoundsPerCell()
	) )
	return true
end

hook.Add( "Initialize", "SWGRP_RegisterEnergyAmmo", function()
	SWGRP.Ammo.RegisterEnergyAmmoType()
end )

hook.Add( "InitPostEntity", "SWGRP_PatchWeaponAmmo", function()
	SWGRP.Ammo.PatchWeaponTables()
	timer.Simple( 5, function()
		SWGRP.Ammo.PatchWeaponTables()
	end )
end )

hook.Add( "PlayerSpawn", "SWGRP_ReconcileEnergyAmmo", function( ply )
	timer.Simple( 0, function()
		if IsValid( ply ) then
			SWGRP.Ammo.ReconcilePlayer( ply )
		end
	end )
end )

hook.Add( "WeaponEquip", "SWGRP_EnergyAmmoEquip", function( wep, ply )
	if not IsValid( ply ) or not IsValid( wep ) then return end
	SWGRP.Ammo.RegisterEnergyWeapon( wep )
	timer.Simple( 0, function()
		if IsValid( ply ) and IsValid( wep ) then
			SWGRP.Ammo.MigrateWeaponAmmo( ply, wep )
		end
	end )
end )

hook.Add( "KeyPress", "SWGRP_EnergyAmmoReload", function( ply, key )
	if key ~= IN_RELOAD then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) or not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return end
	SWGRP.Ammo.EnsureReserveFromCells( ply, wep )
end )

hook.Add( "StartCommand", "SWGRP_EnergyAmmoBlockFire", function( ply, cmd )
	if not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) or not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return end

	if not SWGRP.Ammo.CanFire( ply, wep ) then
		cmd:RemoveKey( IN_ATTACK )
		cmd:RemoveKey( IN_ATTACK2 )
		return
	end

	if wep:Clip1() <= 0 and SWGRP.Ammo.GetWeaponReserveRounds( ply, wep ) <= 0 then
		SWGRP.Ammo.EnsureReserveFromCells( ply, wep )
	end
end )

hook.Add( "EntityFireBullets", "SWGRP_EnergyAmmoFire", function( ent, data )
	if not ent:IsPlayer() then return end

	local wep = ent:GetActiveWeapon()
	if not IsValid( wep ) or not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return end

	if not SWGRP.Ammo.CanFire( ent, wep ) then
		return true
	end
end )

timer.Create( "SWGRP_EnergyAmmoReconcile", 3, 0, function()
	for _, ply in ipairs( player.GetAll() ) do
		if ply:Alive() then
			SWGRP.Ammo.MigrateLegacyAmmo( ply )
		end
	end
end )


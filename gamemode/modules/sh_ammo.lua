--[[---------------------------------------------------------------------------
    Energy cell ammunition — all ballistic weapons use swgrp_energy ammo.
    One inventory energy cell = SWGRP.Config.AmmoRoundsPerEnergyCell rounds (default 5).
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Ammo = SWGRP.Ammo or {}

SWGRP.Ammo.EnergyWeapons = SWGRP.Ammo.EnergyWeapons or {}
SWGRP.Ammo.ENERGY_AMMO = "swgrp_energy"

SWGRP.Ammo.ExcludeClasses = {
	weapon_physgun = true,
	gmod_tool = true,
	weapon_physcannon = true,
	weapon_fists = true,
	weapon_crowbar = true,
	weapon_stunstick = true,
}

local function SWGRP_AmmoRoundsPerCell()
	local cfg = SWGRP.Config or {}
	return math.max( 1, cfg.AmmoRoundsPerEnergyCell or 5 )
end

local function SWGRP_ShipmentGrantCells()
	local cfg = SWGRP.Config or {}
	return math.max( 1, cfg.ShipmentWeaponGrantCells or 2 )
end

function SWGRP.Ammo.RoundsPerCell()
	return SWGRP_AmmoRoundsPerCell()
end

function SWGRP.Ammo.GetEnergyAmmoName()
	return SWGRP.Ammo.ENERGY_AMMO
end

function SWGRP.Ammo.GetEnergyAmmoID()
	return game.GetAmmoID( SWGRP.Ammo.ENERGY_AMMO )
end

function SWGRP.Ammo.GetSwepTable( class )
	if not class or class == "" then return nil end
	return weapons.Get( class ) or weapons.GetStored( class )
end

function SWGRP.Ammo.ShouldPatchWeapon( class )
	if not class or class == "" then return false end
	if SWGRP.Ammo.ExcludeClasses[class] then return false end
	if string.StartWith( class, "swgrp_" ) then return false end

	local swep = SWGRP.Ammo.GetSwepTable( class )
	if not swep or not swep.Primary then return false end

	local ammo = swep.Primary.Ammo
	return ammo and ammo ~= "" and ammo ~= "none"
end

function SWGRP.Ammo.PatchWeaponTables()
	local stored = weapons.GetStored()
	if stored then
		for class, swep in pairs( stored ) do
			if not SWGRP.Ammo.ShouldPatchWeapon( class ) then continue end
			if not swep.Primary then
				swep.Primary = {}
			end
			swep.Primary.Ammo = SWGRP.Ammo.ENERGY_AMMO
			SWGRP.Ammo.EnergyWeapons[class] = true
		end
	end

	SWGRP.Ammo.RefreshEnergyWeapons()
end

function SWGRP.Ammo.UsesEnergyCells( class )
	if not class or class == "" then return false end
	if SWGRP.Ammo.EnergyWeapons[class] then return true end
	if string.StartWith( class, "weapon_752_" ) then return true end
	return SWGRP.Ammo.ShouldPatchWeapon( class )
end

function SWGRP.Ammo.WeaponUsesEnergyCells( wep )
	if not IsValid( wep ) then return false end

	local class = wep:GetClass()
	if SWGRP.Ammo.ExcludeClasses[class] or string.StartWith( class, "swgrp_" ) then return false end
	if SWGRP.Ammo.UsesEnergyCells( class ) then return true end

	local ammoType = wep:GetPrimaryAmmoType()
	if ammoType >= 0 then
		local ammoName = game.GetAmmoName( ammoType )
		if ammoName and ammoName ~= "" and ammoName ~= "none" then
			return true
		end
	end

	return wep:GetMaxClip1() > 0
end

function SWGRP.Ammo.RegisterEnergyWeapon( wep )
	if not IsValid( wep ) then return end
	local class = wep:GetClass()
	if SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then
		SWGRP.Ammo.EnergyWeapons[class] = true
	end
end

function SWGRP.Ammo.IsEnergyWeapon( class )
	return SWGRP.Ammo.UsesEnergyCells( class )
end

function SWGRP.Ammo.RefreshEnergyWeapons()
	SWGRP.Ammo.EnergyWeapons = SWGRP.Ammo.EnergyWeapons or {}

	for _, ship in pairs( SWGRP.Shipments or {} ) do
		for _, class in ipairs( ship.entities or {} ) do
			if class and class ~= "" then
				SWGRP.Ammo.EnergyWeapons[class] = true
			end
		end
	end

	SWGRP.Ammo.EnergyWeapons["weapon_752_e11"] = true
end

function SWGRP.Ammo.GetWeaponAmmoName( class )
	if SWGRP.Ammo.UsesEnergyCells( class ) then
		return SWGRP.Ammo.ENERGY_AMMO
	end

	local swep = SWGRP.Ammo.GetSwepTable( class )
	if not swep or not swep.Primary then return nil end

	local ammo = swep.Primary.Ammo
	if not ammo or ammo == "" or ammo == "none" then return nil end
	return ammo
end

function SWGRP.Ammo.GetCellCount( ply )
	if not IsValid( ply ) then return 0 end
	return ply:SWGRP_GetMaterial( "energy_cell" )
end

function SWGRP.Ammo.GetReserveRounds( ply )
	if not IsValid( ply ) then return 0 end
	local ammoId = SWGRP.Ammo.GetEnergyAmmoID()
	if ammoId < 0 then return 0 end
	return ply:GetAmmoCount( ammoId )
end

function SWGRP.Ammo.GetWeaponReserveRounds( ply, wep )
	if not IsValid( ply ) then return 0 end

	if IsValid( wep ) then
		local ammoType = wep:GetPrimaryAmmoType()
		if ammoType >= 0 then
			return ply:GetAmmoCount( ammoType )
		end
	end

	return SWGRP.Ammo.GetReserveRounds( ply )
end

function SWGRP.Ammo.GetLoadedRounds( ply, wep )
	if not IsValid( ply ) or not IsValid( wep ) then return 0 end
	if not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return 0 end
	return math.max( 0, wep:Clip1() ) + SWGRP.Ammo.GetWeaponReserveRounds( ply, wep )
end

function SWGRP.Ammo.GetTotalRounds( ply, wep )
	if not IsValid( ply ) then return 0 end
	local cells = SWGRP.Ammo.GetCellCount( ply ) * SWGRP.Ammo.RoundsPerCell()
	if IsValid( wep ) and SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then
		return SWGRP.Ammo.GetLoadedRounds( ply, wep ) + cells
	end

	local total = cells
	for _, held in ipairs( ply:GetWeapons() ) do
		if SWGRP.Ammo.WeaponUsesEnergyCells( held ) then
			total = total + math.max( 0, held:Clip1() )
		end
	end
	total = total + SWGRP.Ammo.GetWeaponReserveRounds( ply, ply:GetActiveWeapon() )
	return total
end

function SWGRP.Ammo.CanFire( ply, wep )
	if not IsValid( ply ) or not IsValid( wep ) then return false end
	if not SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then return true end
	return SWGRP.Ammo.GetTotalRounds( ply, wep ) > 0
end

function SWGRP.Ammo.GiveRounds( ply, ammoName, rounds )
	if not IsValid( ply ) or not ammoName or rounds <= 0 then return 0 end
	ply:GiveAmmo( rounds, ammoName, true )
	return rounds
end

function SWGRP.Ammo.GiveWeaponRounds( ply, class, rounds )
	local ammoName = SWGRP.Ammo.GetWeaponAmmoName( class )
	if not ammoName then return 0 end
	return SWGRP.Ammo.GiveRounds( ply, ammoName, rounds )
end

function SWGRP.Ammo.LoadWeaponFromRounds( ply, class, rounds )
	if not IsValid( ply ) or rounds <= 0 then return 0 end

	local ammoName = SWGRP.Ammo.GetWeaponAmmoName( class )
	if not ammoName then return 0 end

	local loaded = 0
	local wep = ply:GetWeapon( class )

	if IsValid( wep ) then
		local maxClip = wep:GetMaxClip1()
		if maxClip and maxClip > 0 then
			local clipFill = math.min( rounds, maxClip - wep:Clip1() )
			if clipFill > 0 then
				wep:SetClip1( wep:Clip1() + clipFill )
				loaded = loaded + clipFill
				rounds = rounds - clipFill
			end
		end
	end

	if rounds > 0 then
		loaded = loaded + SWGRP.Ammo.GiveRounds( ply, ammoName, rounds )
	end

	return loaded
end

function SWGRP.Ammo.GiveCellsAsRounds( ply, cellCount, classFilter )
	if not IsValid( ply ) or cellCount <= 0 then return 0 end

	local rounds = cellCount * SWGRP.Ammo.RoundsPerCell()

	if classFilter and classFilter ~= "" then
		return SWGRP.Ammo.LoadWeaponFromRounds( ply, classFilter, rounds )
	end

	for _, wep in ipairs( ply:GetWeapons() ) do
		if SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then
			return SWGRP.Ammo.LoadWeaponFromRounds( ply, wep:GetClass(), rounds )
		end
	end

	return 0
end

function SWGRP.Ammo.GrantPickupAmmo( ply, class )
	if not IsValid( ply ) or not class or class == "" then return 0 end

	if not SWGRP.Ammo.UsesEnergyCells( class ) then
		local wep = ply:GetWeapon( class )
		if not IsValid( wep ) then return 0 end

		local primary = wep:GetPrimaryAmmoType()
		local secondary = wep:GetSecondaryAmmoType()
		if primary >= 0 and ply:GetAmmoCount( primary ) <= 0 then
			ply:GiveAmmo( 30, primary, true )
		end
		if secondary >= 0 and ply:GetAmmoCount( secondary ) <= 0 then
			ply:GiveAmmo( 30, secondary, true )
		end
		return 30
	end

	return SWGRP.Ammo.GiveCellsAsRounds( ply, SWGRP_ShipmentGrantCells(), class )
end

function SWGRP.Ammo.GetEnergyCellCatalogEntry()
	for name, data in pairs( SWGRP.AmmoTypes or {} ) do
		if data.ammoType == "energy_cell" then
			return name, data
		end
	end
	return nil, nil
end

-- Client HUD helper
function SWGRP.Ammo.GetHUDState( ply )
	if not IsValid( ply ) then return nil end

	local cells = SWGRP.Ammo.GetCellCount( ply )
	local perCell = SWGRP.Ammo.RoundsPerCell()
	local wep = ply:GetActiveWeapon()
	local weaponState = nil

	if IsValid( wep ) and SWGRP.Ammo.WeaponUsesEnergyCells( wep ) then
		SWGRP.Ammo.RegisterEnergyWeapon( wep )

		local clip = math.max( 0, wep:Clip1() )
		local maxClip = wep:GetMaxClip1()
		local reserve = SWGRP.Ammo.GetWeaponReserveRounds( ply, wep )
		local loaded = clip + reserve
		local cellRounds = cells * perCell
		local totalAvailable = loaded + cellRounds
		local meterMax = math.max( maxClip > 0 and maxClip or 30, loaded, totalAvailable, 1 )

		weaponState = {
			clip = clip,
			maxClip = maxClip > 0 and maxClip or 0,
			reserve = reserve,
			loaded = loaded,
			totalAvailable = totalAvailable,
			meterFrac = math.Clamp( totalAvailable / meterMax, 0, 1 ),
			outOfAmmo = totalAvailable <= 0,
			label = wep:GetPrintName() or wep:GetClass(),
		}
	end

	if not weaponState and cells <= 0 then
		return nil
	end

	return {
		weapon = weaponState,
		cells = cells,
		roundsPerCell = perCell,
		canLoad = weaponState ~= nil and cells > 0,
	}
end

function SWGRP.Ammo.GetDisplayState( ply, wep )
	local state = SWGRP.Ammo.GetHUDState( ply )
	if not state or not state.weapon then return nil end
	local w = state.weapon
	return {
		clip = w.clip,
		maxClip = w.maxClip,
		reserve = w.reserve,
		cells = state.cells,
		roundsPerCell = state.roundsPerCell,
		label = w.label,
	}
end

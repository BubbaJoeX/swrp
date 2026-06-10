--[[---------------------------------------------------------------------------
    SWGRP Preview Model Mapping
    Resolves display models for jobs, weapons, entities, and shipments.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.ModelMap = SWGRP.ModelMap or {}

SWGRP.ModelMap.Defaults = {
	player  = "models/player/group01/male_01.mdl",
	weapon  = "models/weapons/w_pistol.mdl",
	entity  = "models/props_c17/consolebox01a.mdl",
	vehicle = "models/buggy.mdl",
	crate   = "models/Items/item_item_crate.mdl",
	ammo    = "models/Items/BoxSRounds.mdl",
}

SWGRP.ModelMap.Weapons = {
	weapon_pistol     = "models/weapons/w_pistol.mdl",
	weapon_357        = "models/weapons/w_357.mdl",
	weapon_smg1       = "models/weapons/w_smg1.mdl",
	weapon_ar2        = "models/weapons/w_irifle.mdl",
	weapon_shotgun    = "models/weapons/w_shotgun.mdl",
	weapon_crossbow   = "models/weapons/w_crossbow.mdl",
	weapon_frag       = "models/weapons/w_grenade.mdl",
	weapon_rpg        = "models/weapons/w_rocket_launcher.mdl",
	weapon_crowbar    = "models/weapons/w_crowbar.mdl",
	weapon_stunstick  = "models/weapons/w_stunbaton.mdl",
	weapon_752_e11    = "models/weapons/w_e11.mdl",
}

SWGRP.ModelMap.Entities = {
	swgrp_credit_harvester  = "models/props_c17/consolebox01a.mdl",
	swgrp_ration_dispenser  = "models/props_junk/garbage_metalcan001a.mdl",
	swgrp_med_station       = "models/props_combine/suit_charger001.mdl",
	swgrp_ammo_crate        = "models/starwars/items/energy_cell.mdl",
	swgrp_armor_station     = "models/props_combine/suit_charger001.mdl",
	swgrp_galactic_atm      = "models/props_c17/consolebox05a.mdl",
	swgrp_mission_terminal  = "models/props_c17/consolebox03a.mdl",
	swgrp_tipjar            = "models/starwars/syphadias/props/sw_tor/bioware_ea/items/harvesting/scavenge/scavenge_barrel.mdl",
	swgrp_holo_sign         = "models/squiddy/hologram_01.mdl",
	swgrp_shipment          = "models/cw_furnitures11/cw_furnitures11.mdl",
	swgrp_hovercrate        = "models/kingpommes/emperors_tower/imp_crates/imp_crate_single_base_static.mdl",
	swgrp_junk_pile         = "models/props_junk/garbage_bag_01a.mdl",
}

SWGRP.ModelMap.Weapons["weapon_752_se14c"] = "models/weapons/w_se14c.mdl"

function SWGRP.ModelMap.Resolve( modelPath, fallback )
	if not modelPath or modelPath == "" then
		return fallback
	end

	if istable( modelPath ) then
		for _, mdl in ipairs( modelPath ) do
			local resolved = SWGRP.ModelMap.Resolve( mdl, nil )
			if resolved then return resolved end
		end
		return fallback
	end

	if SERVER then
		return modelPath
	end

	-- util.IsValidModel() returns false for custom/addon models that have not been
	-- precached yet, which would wrongly fall back to the default. file.Exists is the
	-- reliable check for a mounted model file, so accept the path if either passes.
	if util.IsValidModel( modelPath ) or file.Exists( modelPath, "GAME" ) then
		return modelPath
	end

	return fallback
end

function SWGRP.GetWeaponWorldModel( class )
	if not class or class == "" then
		return SWGRP.ModelMap.Defaults.weapon
	end

	if CLIENT then
		local wep = weapons.Get( class )
		if wep then
			local mdl = wep.WorldModel or wep.WM
			mdl = SWGRP.ModelMap.Resolve( mdl, nil )
			if mdl then return mdl end
		end
	end

	return SWGRP.ModelMap.Resolve(
		SWGRP.ModelMap.Weapons[class],
		SWGRP.ModelMap.Defaults.weapon
	)
end

function SWGRP.GetJobPreviewModel( job )
	if not job then return SWGRP.ModelMap.Defaults.player end

	local mdl = job.previewModel or job.model
	mdl = SWGRP.ModelMap.Resolve( mdl, SWGRP.ModelMap.Defaults.player )
	return mdl
end

function SWGRP.GetEntityPreviewModel( class, data )
	data = data or SWGRP.Entities[class]
	local mdl = data and ( data.previewModel or data.model )
	mdl = SWGRP.ModelMap.Resolve( mdl, nil )

	if not mdl and class then
		mdl = SWGRP.ModelMap.Resolve( SWGRP.ModelMap.Entities[class], nil )
	end

	return mdl or SWGRP.ModelMap.Defaults.entity
end

function SWGRP.GetShipmentPreviewModel( shipment )
	if not shipment then return SWGRP.ModelMap.Defaults.crate end

	local mdl = shipment.previewModel or shipment.model
	mdl = SWGRP.ModelMap.Resolve( mdl, nil )
	if mdl then return mdl end

	if shipment.entities and shipment.entities[1] then
		return SWGRP.GetWeaponWorldModel( shipment.entities[1] )
	end

	return SWGRP.ModelMap.Defaults.crate
end

function SWGRP.GetVehiclePreviewModel( vehicle )
	if not vehicle then return SWGRP.ModelMap.Defaults.vehicle end

	return SWGRP.ModelMap.Resolve( vehicle.previewModel or vehicle.model, SWGRP.ModelMap.Defaults.vehicle )
end

function SWGRP.GetAmmoPreviewModel( ammoData )
	if not ammoData then return SWGRP.ModelMap.Defaults.ammo end

	return SWGRP.ModelMap.Resolve( ammoData.previewModel or ammoData.model, SWGRP.ModelMap.Defaults.ammo )
end

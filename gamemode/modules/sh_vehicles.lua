--[[---------------------------------------------------------------------------
    Vehicles are defined in gamemodes/swgrp/data/vehicles.csv
    Loaded by libraries/sh_content_loader.lua
---------------------------------------------------------------------------]]

SWGRP.Vehicles = SWGRP.Vehicles or {}
SWGRP.PocketableVehicleClasses = SWGRP.PocketableVehicleClasses or {}

function SWGRP.IsPocketableVehicleClass( class )
	return SWGRP.PocketableVehicleClasses[class] == true
end

function SWGRP.IsBuiltinVehicleClass( class )
	return class == "prop_vehicle_jeep" or class == "prop_vehicle_airboat"
end

function SWGRP.GetVehicleByClass( class )
	for _, veh in ipairs( SWGRP.Vehicles or {} ) do
		if veh.class == class then return veh end
	end
end

-- Purchased / spawned SWGRP vehicles (CSV classes, jeep, airboat).
function SWGRP.IsManagedVehicle( ent )
	if not IsValid( ent ) then return false end

	if ent.SWGRP_PocketableVehicle then return true end
	if SWGRP.IsPocketableVehicleClass( ent:GetClass() ) then return true end

	if SWGRP.IsBuiltinVehicleClass( ent:GetClass() ) then
		if SERVER then
			local owner = SWGRP.Ownership and SWGRP.Ownership.GetOwner( ent )
			return IsValid( owner )
		end

		return ent:GetNWString( "SWGRP_VehicleOwnerName", "" ) ~= ""
			or IsValid( ent:GetNWEntity( "SWGRP_VehicleOwner" ) )
	end

	return false
end

function SWGRP.VehicleHasDriver( ent )
	if not IsValid( ent ) then return false end

	if ent.IsVehicle and ent:IsVehicle() and IsValid( ent:GetDriver() ) then
		return true
	end

	for _, ply in ipairs( player.GetAll() ) do
		if ply:InVehicle() then
			local veh = ply:GetVehicle()
			if veh == ent then return true end
			if IsValid( veh ) and veh:GetParent() == ent then return true end
		end
	end

	return false
end

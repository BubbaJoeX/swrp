--[[---------------------------------------------------------------------------
    Vehicle Purchasing
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.VehiclesMgr = SWGRP.VehiclesMgr or {}

function SWGRP.VehiclesMgr.Buy( ply, vehicleId )
	local veh = SWGRP.Vehicles[vehicleId]
	if not veh then return end

	if veh.allowed then
		local ok = false
		for _, t in ipairs( veh.allowed ) do
			if ply:Team() == t then ok = true break end
		end
		if not ok then
			SWGRP.Notify( ply, "Your profession cannot purchase this vehicle." )
			return
		end
	end

	if not ply:SWGRP_TakeCredits( veh.price ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local ent = ents.Create( veh.class )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( veh.price )
		return
	end

	ent:SetModel( veh.model )
	if veh.script then ent:SetKeyValue( "vehiclescript", veh.script ) end

	local pos = ply:GetPos() + ply:GetForward() * 120 + Vector( 0, 0, 20 )
	ent:SetPos( pos )
	ent:SetAngles( ply:GetAngles() )
	ent:Spawn()
	ent:Activate()
	ent.SWGRP_Owner = ply
	if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
	if ent.IsVehicle() then
		ent:CPPISetOwner( ply )
	end

	SWGRP.Notify( ply, "Vehicle purchased: " .. veh.name )
end

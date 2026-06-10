--[[---------------------------------------------------------------------------
    Vehicle Purchasing
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.VehiclesMgr = SWGRP.VehiclesMgr or {}

function SWGRP.VehiclesMgr.Buy( ply, vehicleId )
	local veh = SWGRP.Vehicles[vehicleId]
	if not veh then return end

	if not SWGRP.PlayerTeamAllowedPurchase( ply, veh.allowed ) then
		SWGRP.Notify( ply, "Your profession cannot purchase this vehicle." )
		return
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
	if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	SWGRP.Notify( ply, "Vehicle purchased: " .. veh.name )
end

hook.Add( "CanPlayerEnterVehicle", "SWGRP_VehicleLicense", function( ply, veh )
	if not IsValid( ply ) or not IsValid( veh ) then return end
	if ply:IsAdmin() then return end
	if ply:SWGRP_HasVehicleLicense() then return end

	local job = SWGRP.GetJob( ply:Team() )
	if job and ( job.officer or job.stormtrooper or job.governor ) then return end

	if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, veh ) then return end

	SWGRP.Notify( ply, "You need a vehicle license to operate this vehicle." )
	return false
end )

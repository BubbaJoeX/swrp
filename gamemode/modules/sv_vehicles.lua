--[[---------------------------------------------------------------------------
    Vehicle Purchasing
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.VehiclesMgr = SWGRP.VehiclesMgr or {}

local VM = SWGRP.VehiclesMgr

VM.GHOST_DURATION = 2

local BUILTIN_VEHICLE_CLASSES = {
	prop_vehicle_jeep = true,
	prop_vehicle_airboat = true,
}

local function freezeEntityPhysics( ent, duration )
	if not IsValid( ent ) then return end

	local frozen = false
	if ent.GetPhysicsObjectCount then
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObjectNum( i )
			if IsValid( phys ) then
				phys:EnableMotion( false )
				frozen = true
			end
		end
	end

	if not frozen then
		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then
			phys:EnableMotion( false )
			frozen = true
		end
	end

	if not frozen then return end

	local timerName = "SWGRP_VehicleUnfreeze_" .. ent:EntIndex()
	timer.Create( timerName, duration, 1, function()
		if not IsValid( ent ) then return end

		if ent.GetPhysicsObjectCount then
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local phys = ent:GetPhysicsObjectNum( i )
				if IsValid( phys ) then phys:EnableMotion( true ) end
			end
		end

		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then phys:EnableMotion( true ) end
	end )
end

function VM.GhostPlayer( ply, duration )
	if not IsValid( ply ) then return end

	duration = duration or VM.GHOST_DURATION
	local timerName = "SWGRP_VehicleGhost_" .. ply:SteamID64()

	if timer.Exists( timerName ) then
		timer.Remove( timerName )
		ply:GodDisable()
		ply:SetRenderMode( RENDERMODE_NORMAL )
		ply:SetColor( Color( 255, 255, 255, 255 ) )
	end

	local col = ply:GetColor()
	ply:GodEnable()
	ply:SetRenderMode( RENDERMODE_TRANSALPHA )
	ply:SetColor( Color( col.r, col.g, col.b, 90 ) )
	ply.SWGRP_VehicleGhostUntil = CurTime() + duration

	timer.Create( timerName, duration, 1, function()
		if not IsValid( ply ) then return end
		ply:GodDisable()
		ply:SetRenderMode( RENDERMODE_NORMAL )
		ply:SetColor( Color( col.r, col.g, col.b, 255 ) )
		ply.SWGRP_VehicleGhostUntil = nil
	end )
end

function VM.ApplySpawnGhost( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return end

	ent.SWGRP_SpawnGhostUntil = CurTime() + VM.GHOST_DURATION
	VM.GhostPlayer( ply, VM.GHOST_DURATION )
	freezeEntityPhysics( ent, VM.GHOST_DURATION )
end

function VM.IsBuiltinClass( class )
	return BUILTIN_VEHICLE_CLASSES[class] == true
end

function VM.FindByClass( class )
	for _, veh in ipairs( SWGRP.Vehicles or {} ) do
		if veh.class == class then return veh end
	end
end

function VM.Resolve( ent )
	if not IsValid( ent ) then return ent end
	if SWGRP.IsManagedVehicle( ent ) then return ent end

	local parent = ent:GetParent()
	if IsValid( parent ) and SWGRP.IsManagedVehicle( parent ) then
		return parent
	end

	return ent
end

function VM.SyncOwnerNet( ent, ply )
	if not IsValid( ent ) or not IsValid( ply ) then return end

	ent:SetNWEntity( "SWGRP_VehicleOwner", ply )
	ent:SetNWString( "SWGRP_VehicleOwnerName", ply:Nick() )
	ent:SetNWString( "SWGRP_VehicleOwnerJob", ply:SWGRP_GetJobName() )
end

function VM.InitializeOwnedVehicle( ent, ply, vehDef )
	if not IsValid( ent ) then return end

	vehDef = vehDef or VM.FindByClass( ent:GetClass() )

	if IsValid( ply ) then
		if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
			SWGRP.Ownership.SetOwner( ent, ply )
		end
		VM.SyncOwnerNet( ent, ply )
	end

	if vehDef and vehDef.pocketable then
		ent.SWGRP_PocketableVehicle = true
	elseif SWGRP.IsPocketableVehicleClass( ent:GetClass() ) then
		ent.SWGRP_PocketableVehicle = true
	end

	ent:SetNWBool( "SWGRP_VehicleLocked", ent:GetNWBool( "SWGRP_VehicleLocked", false ) )
end

function VM.IsLocked( ent )
	return IsValid( ent ) and ent:GetNWBool( "SWGRP_VehicleLocked", false )
end

function VM.SetLocked( ent, locked, ply )
	if not IsValid( ent ) then return end

	ent:SetNWBool( "SWGRP_VehicleLocked", locked )

	if locked then
		if ent.IsVehicle and ent:IsVehicle() then
			local driver = ent:GetDriver()
			if IsValid( driver ) and not driver:IsAdmin() and not SWGRP.Ownership.IsOwner( driver, ent ) then
				driver:ExitVehicle()
			end
		end

		for _, occupant in ipairs( player.GetAll() ) do
			if occupant:InVehicle() then
				local veh = occupant:GetVehicle()
				if veh == ent or ( IsValid( veh ) and veh:GetParent() == ent ) then
					if not occupant:IsAdmin() and not SWGRP.Ownership.IsOwner( occupant, ent ) then
						occupant:ExitVehicle()
					end
				end
			end
		end
	end

	ent:EmitSound( locked and "doors/door_latch3.wav" or "doors/door_latch1.wav" )

	if IsValid( ply ) then
		SWGRP.Notify( ply, locked and SWGRP.Lang.vehicle_locked or SWGRP.Lang.vehicle_unlocked )
	end
end

function VM.ToggleLock( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return end
	ent = VM.Resolve( ent )
	if not SWGRP.IsManagedVehicle( ent ) then return end

	if not ply:IsAdmin() and not SWGRP.Ownership.IsOwner( ply, ent ) then
		SWGRP.Notify( ply, "You don't own this vehicle." )
		return
	end

	VM.SetLocked( ent, not VM.IsLocked( ent ), ply )
end

function VM.Spawn( ply, vehDef, pos, ang )
	if not IsValid( ply ) or not vehDef or not vehDef.class then return nil end

	local class = vehDef.class
	local ent = ents.Create( class )
	if not IsValid( ent ) then return nil end

	if VM.IsBuiltinClass( class ) then
		if vehDef.model and vehDef.model ~= "" then
			ent:SetModel( vehDef.model )
		end
		if vehDef.script and vehDef.script ~= "" then
			ent:SetKeyValue( "vehiclescript", vehDef.script )
		end
	end

	if not pos then
		pos = ply:GetPos() + ply:GetForward() * 120 + Vector( 0, 0, 20 )
	end
	ang = ang or ply:GetAngles()

	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	VM.InitializeOwnedVehicle( ent, ply, vehDef )
	VM.ApplySpawnGhost( ply, ent )

	return ent
end

function VM.SpawnFromPocketItem( ply, item )
	if not IsValid( ply ) or not item or not item.class then return nil end

	local def = VM.FindByClass( item.class ) or {
		class = item.class,
		pocketable = SWGRP.IsPocketableVehicleClass( item.class ),
	}

	local pos, ang = SWGRP.Economy.GroundSpawn( ply, 120 )
	local ent = VM.Spawn( ply, def, pos, ang )
	if not IsValid( ent ) then return nil end

	SWGRP.Pocket.RestoreEntity( ent, item, ply )
	ent:SetPos( pos )
	ent:SetAngles( ang )

	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then phys:Wake() end

	return ent
end

function VM.EjectOccupants( ent, ply )
	if not IsValid( ent ) then return end

	if IsValid( ply ) and ply:InVehicle() then
		local veh = ply:GetVehicle()
		if veh == ent or ( IsValid( veh ) and veh:GetParent() == ent ) then
			ply:ExitVehicle()
		end
	end

	if ent.IsVehicle and ent:IsVehicle() then
		local driver = ent:GetDriver()
		if IsValid( driver ) then driver:ExitVehicle() end
	end
end

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

	local ent = VM.Spawn( ply, veh )
	if not IsValid( ent ) then
		ply:SWGRP_AddCredits( veh.price )
		SWGRP.Notify( ply, "Could not spawn vehicle. Is the entity installed?" )
		return
	end

	SWGRP.Notify( ply, "Vehicle purchased: " .. veh.name )
end

hook.Add( "ShouldCollide", "SWGRP_VehicleSpawnGhost", function( entA, entB )
	if not IsValid( entA ) or not IsValid( entB ) then return end

	local function ghostBlocksPlayer( ent, ply )
		if not ply:IsPlayer() then return false end
		return ent.SWGRP_SpawnGhostUntil and CurTime() < ent.SWGRP_SpawnGhostUntil
	end

	if ghostBlocksPlayer( entA, entB ) then return false end
	if ghostBlocksPlayer( entB, entA ) then return false end
end )

hook.Add( "EntityTakeDamage", "SWGRP_VehicleSpawnGhost", function( target, dmginfo )
	if not IsValid( target ) or not target:IsPlayer() then return end

	local inflictor = dmginfo:GetInflictor()
	local attacker = dmginfo:GetAttacker()
	local now = CurTime()

	if IsValid( inflictor ) and inflictor.SWGRP_SpawnGhostUntil and now < inflictor.SWGRP_SpawnGhostUntil then
		return true
	end

	if IsValid( attacker ) and attacker.SWGRP_SpawnGhostUntil and now < attacker.SWGRP_SpawnGhostUntil then
		return true
	end
end )

hook.Add( "CanPlayerEnterVehicle", "SWGRP_VehicleLicense", function( ply, veh )
	if not IsValid( ply ) or not IsValid( veh ) then return end

	veh = VM.Resolve( veh )

	if SWGRP.IsManagedVehicle( veh ) and VM.IsLocked( veh ) then
		if not ply:IsAdmin() and not SWGRP.Ownership.IsOwner( ply, veh ) then
			SWGRP.Notify( ply, "This vehicle is locked." )
			return false
		end
	end

	if ply:IsAdmin() then return end
	if ply:SWGRP_HasVehicleLicense() then return end

	local job = SWGRP.GetJob( ply:Team() )
	if job and ( job.officer or job.stormtrooper or job.governor ) then return end

	if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, veh ) then return end

	SWGRP.Notify( ply, "You need a vehicle license to operate this vehicle." )
	return false
end )

hook.Add( "OnPlayerChangedTeam", "SWGRP_VehicleOwnerJob", function( ply )
	if not IsValid( ply ) then return end

	for _, ent in ipairs( ents.GetAll() ) do
		if IsValid( ent ) and ent:GetNWEntity( "SWGRP_VehicleOwner" ) == ply then
			ent:SetNWString( "SWGRP_VehicleOwnerJob", ply:SWGRP_GetJobName() )
		end
	end
end )

hook.Add( "PlayerDisconnected", "SWGRP_VehicleOwnerDisconnect", function( ply )
	for _, ent in ipairs( ents.GetAll() ) do
		if IsValid( ent ) and ent:GetNWEntity( "SWGRP_VehicleOwner" ) == ply then
			ent:SetNWEntity( "SWGRP_VehicleOwner", NULL )
		end
	end
end )

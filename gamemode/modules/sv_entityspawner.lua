--[[---------------------------------------------------------------------------
    Admin Entity Spawner - spawn content from CSV catalogs
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.EntitySpawner = SWGRP.EntitySpawner or {}

local ES = SWGRP.EntitySpawner

function ES.AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

function ES.BuildCatalog()
	local catalog = {}

	for class, data in pairs( SWGRP.Entities or {} ) do
		table.insert( catalog, {
			kind = "entity",
			id = class,
			name = data.name or class,
			model = data.model,
		} )
	end

	for id, food in ipairs( SWGRP.Foods or {} ) do
		table.insert( catalog, {
			kind = "food",
			id = id,
			name = food.name or ( "Food " .. id ),
			model = food.model,
		} )
	end

	for id, spice in ipairs( SWGRP.Spices or {} ) do
		table.insert( catalog, {
			kind = "spice",
			id = id,
			name = spice.name or ( "Spice " .. id ),
			model = spice.model,
		} )
	end

	for id, ship in ipairs( SWGRP.Shipments or {} ) do
		table.insert( catalog, {
			kind = "shipment",
			id = id,
			name = ship.name or ( "Shipment " .. id ),
			model = ship.model,
		} )
	end

	for id, veh in ipairs( SWGRP.Vehicles or {} ) do
		table.insert( catalog, {
			kind = "vehicle",
			id = id,
			name = veh.name or ( "Vehicle " .. id ),
			model = veh.model,
		} )
	end

	table.sort( catalog, function( a, b )
		return string.lower( a.name ) < string.lower( b.name )
	end )

	return catalog
end

function ES.OpenMenu( ply )
	if not ES.AdminAllowed( ply ) then return end

	local catalog = ES.BuildCatalog()

	net.Start( "SWGRP_EntitySpawnMenu" )
		net.WriteUInt( #catalog, 16 )
		for _, row in ipairs( catalog ) do
			net.WriteString( row.kind )
			net.WriteString( tostring( row.id ) )
			net.WriteString( row.name )
			net.WriteString( row.model or "" )
		end
	net.Send( ply )
end

function ES.SpawnAt( ply, kind, id )
	if not ES.AdminAllowed( ply ) then return end

	local pos, ang = SWGRP.Economy.GroundSpawn( ply, 64 )
	local ent

	if kind == "entity" then
		local class = tostring( id )
		ent = ents.Create( class )
		if not IsValid( ent ) then
			SWGRP.Notify( ply, "Failed to spawn entity: " .. class )
			return
		end
		local data = SWGRP.Entities[class]
		if data and data.model then ent:SetModel( data.model ) end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		ent:Activate()
	elseif kind == "food" then
		local food = SWGRP.Foods[tonumber( id )]
		if not food then return end
		ent = ents.Create( "prop_physics" )
		if not IsValid( ent ) then return end
		ent:SetModel( food.model or "models/props_junk/garbage_bag_01a.mdl" )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		ent.SWGRP_FoodId = tonumber( id )
		ent.SWGRP_FoodName = food.name
	elseif kind == "spice" then
		ent = ents.Create( "swgrp_spice" )
		if not IsValid( ent ) then return end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		ent:SetSpice( tonumber( id ) )
	elseif kind == "shipment" then
		local ship = SWGRP.Shipments[tonumber( id )]
		if not ship then return end
		ent = ents.Create( "swgrp_shipment" )
		if not IsValid( ent ) then return end
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		ent:SetShipment( tonumber( id ) )
	elseif kind == "vehicle" then
		local veh = SWGRP.Vehicles[tonumber( id )]
		if not veh then return end
		ent = ents.Create( veh.class )
		if not IsValid( ent ) then return end
		ent:SetModel( veh.model )
		if veh.script then ent:SetKeyValue( "vehiclescript", veh.script ) end
		ent:SetPos( pos + Vector( 0, 0, 20 ) )
		ent:SetAngles( ang )
		ent:Spawn()
		ent:Activate()
	else
		SWGRP.Notify( ply, "Unknown spawn type." )
		return
	end

	if IsValid( ent ) and SWGRP.Ownership then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	SWGRP.Notify( ply, "Spawned " .. kind .. " at crosshair." )
end

function ES.AdminToolPrimary( ply )
	ES.OpenMenu( ply )
end

net.Receive( "SWGRP_EntitySpawnAction", function( _, ply )
	if not ES.AdminAllowed( ply ) then return end

	local kind = net.ReadString()
	local id = net.ReadString()
	ES.SpawnAt( ply, kind, id )
end )

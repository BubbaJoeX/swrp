--[[---------------------------------------------------------------------------
    Pocket - 8 fixed slots; full item state preserved on store and restored
    on drop. Supports weapons (clip/ammo), shipments, spice, keypads, etc.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Pocket = SWGRP.Pocket or {}

local BLOCKED = {
	swgrp_keys = true,
	weapon_physgun = true,
	weapon_physcannon = true,
	gmod_tool = true,
	gmod_camera = true,
}

local POCKET_REACH = 150
local POCKET_REACH_VEHICLE = 320
local POCKET_TRACE_DIST = 400

function SWGRP.Pocket.Max()
	return SWGRP.Config and SWGRP.Config.MaxPocket or 8
end

local function vecTable( v )
	if not v then return nil end
	return { x = v.x, y = v.y, z = v.z }
end

local function vecFromTable( t )
	if not istable( t ) then return nil end
	return Vector( t.x or 0, t.y or 0, t.z or 0 )
end

-- Legacy shipment rows and bare class strings are upgraded to the current
-- { kind, class, state } layout used for persistence and net sync.
function SWGRP.Pocket.NormalizeItem( entry )
	if entry == nil or entry == false then return false end

	if isstring( entry ) then
		entry = string.Trim( entry )
		if entry == "" then return false end
		if weapons.GetStored( entry ) then
			return { kind = "weapon", class = entry, state = {} }
		end
		return { kind = "entity", class = entry, state = {} }
	end

	if not istable( entry ) or not entry.kind or not entry.class or entry.class == "" then
		return false
	end

	entry.state = entry.state or {}

	if entry.kind == "shipment" then
		return {
			kind  = "entity",
			class = entry.class or "swgrp_shipment",
			state = {
				remaining = entry.remaining,
				weapon    = entry.weapon,
				name      = entry.name,
				model     = entry.state.model,
			},
		}
	end

	if entry.kind == "weapon" or entry.kind == "entity" then
		entry.state = entry.state or {}
		return entry
	end

	return false
end

local function isSlotArray( raw )
	if not istable( raw ) or #raw == 0 then return false end
	if #raw == SWGRP.Pocket.Max() then return true end
	for _, entry in ipairs( raw ) do
		if entry == false or entry == nil then return true end
		if istable( entry ) and entry.kind then return true end
	end
	return false
end

function SWGRP.Pocket.MigrateLegacy( ply )
	local max = SWGRP.Pocket.Max()
	local slots = {}
	for i = 1, max do slots[i] = false end

	local raw = {}
	if istable( ply.SWGRP_PocketItems ) then
		raw = ply.SWGRP_PocketItems
	elseif isstring( ply.SWGRP_Pocket ) and ply.SWGRP_Pocket ~= "" then
		if string.sub( ply.SWGRP_Pocket, 1, 1 ) == "[" then
			raw = util.JSONToTable( ply.SWGRP_Pocket ) or {}
		else
			raw = { ply.SWGRP_Pocket }
		end
	end

	if isSlotArray( raw ) then
		for i = 1, max do
			local item = SWGRP.Pocket.NormalizeItem( raw[i] )
			slots[i] = item or false
		end
		return slots
	end

	local idx = 1
	for _, entry in ipairs( raw ) do
		if idx > max then break end
		local item = SWGRP.Pocket.NormalizeItem( entry )
		if item then
			slots[idx] = item
			idx = idx + 1
		end
	end

	return slots
end

function SWGRP.Pocket.GetSlots( ply )
	if not IsValid( ply ) then return {} end

	if not istable( ply.SWGRP_PocketSlots ) then
		ply.SWGRP_PocketSlots = SWGRP.Pocket.MigrateLegacy( ply )
	end

	local max = SWGRP.Pocket.Max()
	for i = 1, max do
		local item = SWGRP.Pocket.NormalizeItem( ply.SWGRP_PocketSlots[i] )
		ply.SWGRP_PocketSlots[i] = item or false
	end

	while #ply.SWGRP_PocketSlots < max do
		table.insert( ply.SWGRP_PocketSlots, false )
	end

	return ply.SWGRP_PocketSlots
end

function SWGRP.Pocket.CountFilled( slots )
	local n = 0
	for i = 1, SWGRP.Pocket.Max() do
		if SWGRP.Pocket.NormalizeItem( slots[i] ) then n = n + 1 end
	end
	return n
end

function SWGRP.Pocket.FindEmptySlot( slots )
	for i = 1, SWGRP.Pocket.Max() do
		if not SWGRP.Pocket.NormalizeItem( slots[i] ) then return i end
	end
end

function SWGRP.Pocket.SlotOccupied( slots, slot )
	return SWGRP.Pocket.NormalizeItem( slots[slot] ) ~= false
end

function SWGRP.Pocket.IsVehicleEntity( ent )
	if not IsValid( ent ) then return false end
	return ent.SWGRP_PocketableVehicle or SWGRP.IsPocketableVehicleClass( ent:GetClass() )
end

function SWGRP.Pocket.IsPocketableClass( ent )
	if not IsValid( ent ) then return false end
	local class = ent:GetClass()
	if SWGRP.Pocket.IsVehicleEntity( ent ) then return true end
	if string.sub( class, 1, 6 ) ~= "swgrp_" then return false end
	return class ~= "swgrp_dropped_credits" and class ~= "swgrp_hovercrate"
end

function SWGRP.Pocket.ResolveTarget( ent )
	if not IsValid( ent ) then return nil end

	local cur = ent
	for _ = 1, 10 do
		if not IsValid( cur ) then return nil end
		if SWGRP.Pocket.IsPocketableClass( cur ) then return cur end
		cur = cur:GetParent()
	end

	return nil
end

function SWGRP.Pocket.GetReach( ent )
	if SWGRP.Pocket.IsVehicleEntity( ent ) then return POCKET_REACH_VEHICLE end
	return POCKET_REACH
end

function SWGRP.Pocket.PlayerOwnsEntity( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return false end

	if SWGRP.Ownership and SWGRP.Ownership.IsOwner then
		return SWGRP.Ownership.IsOwner( ply, ent )
	end

	if ent.SWGRP_Owner == ply then return true end
	if isfunction( ent.CPPIGetOwner ) and ent:CPPIGetOwner() == ply then return true end

	return false
end

function SWGRP.Pocket.FindOwnedVehicleNear( ply, pos, radius )
	if not IsValid( ply ) or not pos then return nil end

	radius = radius or POCKET_REACH_VEHICLE
	local best, bestDist = nil, radius * radius

	for _, ent in ipairs( ents.FindInSphere( pos, radius ) ) do
		if not SWGRP.Pocket.IsVehicleEntity( ent ) then continue end
		if not SWGRP.Pocket.PlayerOwnsEntity( ply, ent ) then continue end

		local dist = pos:DistToSqr( ent:GetPos() )
		if dist <= bestDist then
			bestDist = dist
			best = ent
		end
	end

	return best
end

function SWGRP.Pocket.PocketTrace( ply )
	return util.TraceLine( {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * POCKET_TRACE_DIST,
		filter = ply,
		mask = MASK_SOLID,
	} )
end

function SWGRP.Pocket.CanPocketEntity( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return false end
	if ent:IsPlayer() or ent:IsWeapon() then return false end

	if SWGRP.Pocket.IsVehicleEntity( ent ) then
		if SWGRP.Pocket.PlayerOwnsEntity( ply, ent ) then
			ent.SWGRP_PocketableVehicle = true
			return true
		end
		return false
	end

	local class = ent:GetClass()
	if string.sub( class, 1, 6 ) ~= "swgrp_" then return false end
	if class == "swgrp_dropped_credits" or class == "swgrp_hovercrate" then return false end

	if SWGRP.Ownership and SWGRP.Ownership.CanTouch then
		return SWGRP.Ownership.CanTouch( ply, ent )
	end

	if ent.SWGRP_Owner == ply then return true end
	if isfunction( ent.CPPIGetOwner ) and ent:CPPIGetOwner() == ply then return true end

	return false
end

-- Per-entity serializers. ENT:SWGRP_PocketSave / SWGRP_PocketRestore override these
-- when present on the entity class.
SWGRP.Pocket.EntityCapture = {
	swgrp_shipment = function( ent )
		return {
			remaining    = ent:GetRemaining(),
			weapon       = ent:GetWeaponClass(),
			name         = ent:GetShipmentName(),
			previewModel = ent.GetPreviewModel and ent:GetPreviewModel() or "",
		}
	end,

	swgrp_letter = function( ent )
		return {
			model      = ent:GetModel(),
			letterText = ent:GetLetterText(),
			authorName = ent:GetAuthorName(),
		}
	end,

	swgrp_holo_sign = function( ent )
		return {
			model    = ent:GetModel(),
			signText = ent:GetSignText(),
		}
	end,

	swgrp_keypad = function( ent )
		local state = { model = ent:GetModel() }
		local door = ent.GetLinkedDoor and ent:GetLinkedDoor()
		if IsValid( door ) then
			state.linkedDoorPos = vecTable( door:GetPos() )
		end
		return state
	end,

	swgrp_tipjar = function( ent )
		return {
			model = ent:GetModel(),
			tips  = ent:GetTips(),
		}
	end,

	swgrp_credit_harvester = function( ent )
		return {
			model          = ent:GetModel(),
			storedCredits  = ent:GetStoredCredits(),
			heat           = ent:GetHeat(),
			overheated     = ent:GetOverheated(),
		}
	end,

	swgrp_spice = function( ent )
		return {
			model   = ent:GetModel(),
			spiceID = ent:GetSpiceID(),
		}
	end,

	swgrp_food = function( ent )
		return {
			model  = ent:GetModel(),
			foodID = ent:GetFoodID(),
		}
	end,
}

SWGRP.Pocket.EntityRestore = {
	swgrp_shipment = function( ent, state )
		ent:SetRemaining( state.remaining or 1 )
		ent:SetWeaponClass( state.weapon or "" )
		ent:SetShipmentName( state.name or "" )
	end,

	swgrp_letter = function( ent, state )
		if state.letterText then ent:SetLetterText( state.letterText ) end
		if state.authorName then ent:SetAuthorName( state.authorName ) end
	end,

	swgrp_holo_sign = function( ent, state )
		if state.signText then ent:SetSignText( state.signText ) end
	end,

	swgrp_keypad = function( ent, state )
		ent:SetCracking( false )
		local pos = vecFromTable( state.linkedDoorPos )
		if pos then
			for _, door in ipairs( ents.FindInSphere( pos, 24 ) ) do
				if IsValid( door ) and door.isDoor and door:isDoor() then
					ent:SetLinkedDoor( door )
					return
				end
			end
		end
		if ent.LinkNearestDoor then ent:LinkNearestDoor() end
	end,

	swgrp_tipjar = function( ent, state )
		ent:SetTips( state.tips or 0 )
	end,

	swgrp_credit_harvester = function( ent, state )
		ent:SetStoredCredits( state.storedCredits or 0 )
		ent:SetHeat( state.heat or 0 )
		ent:SetOverheated( state.overheated or false )
	end,

	swgrp_spice = function( ent, state )
		if state.spiceID and ent.SetSpice then
			ent:SetSpice( state.spiceID )
		end
	end,

	swgrp_food = function( ent, state )
		if state.foodID and ent.SetFood then
			ent:SetFood( state.foodID )
		end
	end,
}

function SWGRP.Pocket.CaptureWeapon( ply, wep )
	if not IsValid( wep ) then return {} end

	local state = {}
	if wep.Clip1 then state.clip1 = wep:Clip1() end
	if wep.Clip2 then state.clip2 = wep:Clip2() end

	local ammoType = wep:GetPrimaryAmmoType()
	if ammoType and ammoType >= 0 then
		state.ammoType = ammoType
		state.ammoCount = ply:GetAmmoCount( ammoType )
	end

	local altType = wep:GetSecondaryAmmoType()
	if altType and altType >= 0 then
		state.altAmmoType = altType
		state.altAmmoCount = ply:GetAmmoCount( altType )
	end

	return state
end

function SWGRP.Pocket.CaptureEntity( ent )
	if not IsValid( ent ) then return {} end

	if ent.SWGRP_PocketSave then
		local state = ent:SWGRP_PocketSave()
		if istable( state ) then return state end
	end

	local class = ent:GetClass()
	local cap = SWGRP.Pocket.EntityCapture[class]
	local state = cap and cap( ent ) or {}

	state.model = state.model or ent:GetModel()
	state.skin  = state.skin or ent:GetSkin()

	local col = ent:GetColor()
	state.color = { r = col.r, g = col.g, b = col.b, a = col.a }

	local hookState = SWGRP.Hooks.Call( "SWGRPPocketCapture", ent )
	if istable( hookState ) then
		table.Merge( state, hookState )
	end

	return state
end

local function applyModel( ent, model, pos, ang )
	if not model or model == "" then return end

	ent:SetModel( model )
	ent:PhysicsInit( SOLID_VPHYSICS )
	if not IsValid( ent:GetPhysicsObject() ) then return end

	ent:SetSolid( SOLID_VPHYSICS )
	ent:SetMoveType( MOVETYPE_VPHYSICS )
	if pos then ent:SetPos( pos ) end
	if ang then ent:SetAngles( ang ) end
	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then phys:Wake() end
end

function SWGRP.Pocket.RestoreEntity( ent, item, ply )
	if not IsValid( ent ) then return end

	local state = item.state or {}

	if ent.SWGRP_PocketRestore then
		ent:SWGRP_PocketRestore( state, ply )
	else
		local restore = SWGRP.Pocket.EntityRestore[ item.class ]
		if restore then restore( ent, state, ply ) end
	end

	if state.skin then ent:SetSkin( state.skin ) end
	if state.color then
		ent:SetColor( Color( state.color.r or 255, state.color.g or 255, state.color.b or 255, state.color.a or 255 ) )
	end

	SWGRP.Hooks.Call( "SWGRPPocketRestore", ent, item, ply )
end

local function spawnEntity( ply, item )
	local class = item.class

	if SWGRP.IsPocketableVehicleClass( class ) and SWGRP.VehiclesMgr and SWGRP.VehiclesMgr.SpawnFromPocketItem then
		return SWGRP.VehiclesMgr.SpawnFromPocketItem( ply, item )
	end

	if class == "swgrp_shipment" and SWGRP.Economy and SWGRP.Economy.SpawnShipmentCrate then
		return SWGRP.Economy.SpawnShipmentCrate( ply, nil, false, item.state or {} )
	end

	local state = item.state or {}
	local pos, ang = SWGRP.Economy.GroundSpawn( ply )

	local ent = ents.Create( class )
	if not IsValid( ent ) then return nil end

	if state.model and state.model ~= "" then
		ent:SetModel( state.model )
	end

	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	if state.model and state.model ~= "" and not IsValid( ent:GetPhysicsObject() ) then
		local data = SWGRP.Entities and SWGRP.Entities[class]
		local fallback = data and data.model
		if fallback and fallback ~= "" then
			applyModel( ent, fallback, pos, ang )
		end
	end

	SWGRP.Pocket.RestoreEntity( ent, item, ply )

	if SWGRP.Ownership and SWGRP.Ownership.SetOwner then
		SWGRP.Ownership.SetOwner( ent, ply )
	else
		ent.SWGRP_Owner = ply
		if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
	end

	if SWGRP.IsPocketableVehicleClass( class ) then
		ent.SWGRP_PocketableVehicle = true
	end

	if SWGRP.Economy and SWGRP.Economy.AlignBottomToGround then
		SWGRP.Economy.AlignBottomToGround( ent, pos, ang )
	end

	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then phys:Wake() end

	return ent
end

local function itemFromEntity( ent )
	return {
		kind  = "entity",
		class = ent:GetClass(),
		state = SWGRP.Pocket.CaptureEntity( ent ),
	}
end

local function writeItem( item )
	item = SWGRP.Pocket.NormalizeItem( item )
	if not item then
		net.WriteBool( false )
		return
	end

	net.WriteBool( true )
	net.WriteString( item.kind )
	net.WriteString( item.class )
	net.WriteString( util.TableToJSON( item.state or {} ) )
end

local function pocketAllowed( ply )
	if not IsValid( ply ) then return false end
	if ply:SWGRP_IsRestrained() or ply:SWGRP_IsArrested() then
		SWGRP.Notify( ply, "You can't use your pocket right now." )
		return false
	end
	return true
end

local function syncPocket( ply )
	local slots = SWGRP.Pocket.GetSlots( ply )
	ply.SWGRP_Pocket = util.TableToJSON( slots )

	local first = false
	for i = 1, SWGRP.Pocket.Max() do
		local item = SWGRP.Pocket.NormalizeItem( slots[i] )
		if item then
			first = item.class
			break
		end
	end

	ply:SetNWString( "SWGRP_Pocket", first or "" )
	ply:SetNWInt( "SWGRP_PocketCount", SWGRP.Pocket.CountFilled( slots ) )

	net.Start( "SWGRP_PocketSync" )
		for i = 1, SWGRP.Pocket.Max() do
			writeItem( slots[i] )
		end
	net.Send( ply )

	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
end

SWGRP.Pocket.Sync = syncPocket

local function giveWeapon( ply, item )
	local class = item.class
	local state = item.state or {}

	if not SWGRP.GrantWeapon( ply, class ) then return false end
	local wep = ply:GetWeapon( class )
	if not IsValid( wep ) then return false end

	if state.clip1 and wep.SetClip1 then wep:SetClip1( state.clip1 ) end
	if state.clip2 and wep.SetClip2 then wep:SetClip2( state.clip2 ) end
	if state.ammoType and state.ammoCount then
		ply:SetAmmo( state.ammoCount, state.ammoType )
	end
	if state.altAmmoType and state.altAmmoCount then
		ply:SetAmmo( state.altAmmoCount, state.altAmmoType )
	end

	ply:SelectWeapon( class )
	return true
end

local function deployItem( ply, item )
	item = SWGRP.Pocket.NormalizeItem( item )
	if not item then return false end

	if item.kind == "weapon" then
		return giveWeapon( ply, item )
	end

	if item.kind == "entity" then
		return IsValid( spawnEntity( ply, item ) )
	end

	return false
end

local function itemLabel( item )
	item = SWGRP.Pocket.NormalizeItem( item )
	if not item then return "item" end

	local state = item.state or {}
	if item.class == "swgrp_shipment" and state.name and state.name ~= "" then
		return state.name
	end
	if item.class == "swgrp_spice" and state.spiceID and SWGRP.Spices and SWGRP.Spices[state.spiceID] then
		return SWGRP.Spices[state.spiceID].name
	end
	if item.class == "swgrp_food" and state.foodID and SWGRP.Foods and SWGRP.Foods[state.foodID] then
		return SWGRP.Foods[state.foodID].name
	end
	if item.kind == "weapon" then
		local swep = weapons.Get( item.class )
		if swep and swep.PrintName and swep.PrintName ~= "" then return swep.PrintName end
	end
	if SWGRP.Entities and SWGRP.Entities[item.class] and SWGRP.Entities[item.class].name then
		return SWGRP.Entities[item.class].name
	end
	return item.class or "item"
end

function SWGRP.Pocket.Drop( ply, slot )
	if not pocketAllowed( ply ) then return end

	slot = tonumber( slot )
	if not slot or slot < 1 or slot > SWGRP.Pocket.Max() then return end

	local slots = SWGRP.Pocket.GetSlots( ply )
	local item = SWGRP.Pocket.NormalizeItem( slots[slot] )
	if not item then
		SWGRP.Notify( ply, "That pocket slot is empty." )
		return
	end

	slots[slot] = false

	if not deployItem( ply, item ) then
		slots[slot] = item
		SWGRP.Notify( ply, "Couldn't drop that item right now." )
		return
	end

	syncPocket( ply )
	SWGRP.Notify( ply, "Dropped " .. itemLabel( item ) .. " from pocket." )
end

function SWGRP.Pocket.Swap( ply, a, b )
	if not pocketAllowed( ply ) then return end
	a, b = tonumber( a ), tonumber( b )
	if not a or not b or a < 1 or a > SWGRP.Pocket.Max() or b < 1 or b > SWGRP.Pocket.Max() then return end
	if a == b then return end

	local slots = SWGRP.Pocket.GetSlots( ply )
	slots[a], slots[b] = slots[b], slots[a]
	syncPocket( ply )
end

function SWGRP.Pocket.StoreWeapon( ply, slot, class )
	if not pocketAllowed( ply ) then return false end
	if not class or class == "" or BLOCKED[class] then
		SWGRP.Notify( ply, "You cannot pocket that item." )
		return false
	end

	local wep = ply:GetWeapon( class )
	if not IsValid( wep ) then
		SWGRP.Notify( ply, "You don't have that weapon." )
		return false
	end

	local slots = SWGRP.Pocket.GetSlots( ply )
	slot = tonumber( slot )
	if slot and ( slot < 1 or slot > SWGRP.Pocket.Max() ) then slot = nil end
	if not slot then slot = SWGRP.Pocket.FindEmptySlot( slots ) end
	if not slot then
		SWGRP.Notify( ply, "Your pocket is full." )
		return false
	end
	if SWGRP.Pocket.SlotOccupied( slots, slot ) then
		SWGRP.Notify( ply, "That pocket slot is occupied." )
		return false
	end

	local state = SWGRP.Pocket.CaptureWeapon( ply, wep )
	ply:StripWeapon( class )
	slots[slot] = { kind = "weapon", class = class, state = state }
	syncPocket( ply )
	SWGRP.Notify( ply, "Stored " .. itemLabel( slots[slot] ) .. " in pocket slot " .. slot .. "." )
	return true
end

function SWGRP.Pocket.StoreEntity( ply, ent, slot )
	if not pocketAllowed( ply ) then return false end
	if not IsValid( ent ) then return false end
	if not SWGRP.Pocket.CanPocketEntity( ply, ent ) then return false end

	local slots = SWGRP.Pocket.GetSlots( ply )
	slot = slot or SWGRP.Pocket.FindEmptySlot( slots )
	if not slot then
		SWGRP.Notify( ply, "Your pocket is full." )
		return false
	end
	if SWGRP.Pocket.SlotOccupied( slots, slot ) then
		SWGRP.Notify( ply, "That pocket slot is occupied." )
		return false
	end

	if IsValid( ply ) and ply:InVehicle() then
		local veh = ply:GetVehicle()
		if veh == ent or ( IsValid( veh ) and veh:GetParent() == ent ) then
			ply:ExitVehicle()
		end
	end

	if SWGRP.VehiclesMgr and SWGRP.VehiclesMgr.EjectOccupants then
		SWGRP.VehiclesMgr.EjectOccupants( ent, ply )
	end

	slots[slot] = itemFromEntity( ent )
	ent:Remove()
	syncPocket( ply )
	SWGRP.Notify( ply, "Stored " .. itemLabel( slots[slot] ) .. " in pocket slot " .. slot .. "." )
	return true
end

function SWGRP.Pocket.Store( ply, silent )
	if not pocketAllowed( ply ) then return false end

	local tr = SWGRP.Pocket.PocketTrace( ply )
	local ent = SWGRP.Pocket.ResolveTarget( tr.Entity )

	if not IsValid( ent ) and tr.Hit then
		ent = SWGRP.Pocket.FindOwnedVehicleNear( ply, tr.HitPos, POCKET_REACH_VEHICLE )
	end

	if IsValid( ent ) then
		local reach = SWGRP.Pocket.GetReach( ent )
		local distSqr = ply:EyePos():DistToSqr( tr.HitPos )

		if distSqr <= reach * reach then
			if SWGRP.Pocket.CanPocketEntity( ply, ent ) then
				return SWGRP.Pocket.StoreEntity( ply, ent )
			elseif not silent then
				if SWGRP.Pocket.IsVehicleEntity( ent ) then
					SWGRP.Notify( ply, "You don't own that vehicle." )
				else
					SWGRP.Notify( ply, "You can't pocket that." )
				end
			end
			return false
		elseif not silent then
			SWGRP.Notify( ply, "Too far away." )
			return false
		end
	end

	if ply:InVehicle() then
		local veh = SWGRP.Pocket.ResolveTarget( ply:GetVehicle() )
		if IsValid( veh ) and SWGRP.Pocket.CanPocketEntity( ply, veh ) then
			return SWGRP.Pocket.StoreEntity( ply, veh )
		end
	end

	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) then
		if not silent then SWGRP.Notify( ply, "Nothing to pocket." ) end
		return false
	end

	return SWGRP.Pocket.StoreWeapon( ply, nil, wep:GetClass() )
end

function SWGRP.Pocket.Restore( ply )
	ply.SWGRP_PocketSlots = nil
	syncPocket( ply )
end

-- Pocket weapons are not persisted across map/server restarts.
function SWGRP.Pocket.ClearWeaponSlots( ply )
	if not IsValid( ply ) then return end

	local slots = SWGRP.Pocket.GetSlots( ply )
	local cleared = false

	for i = 1, SWGRP.Pocket.Max() do
		local item = SWGRP.Pocket.NormalizeItem( slots[i] )
		if item and item.kind == "weapon" then
			slots[i] = false
			cleared = true
		end
	end

	if cleared then
		syncPocket( ply )
	end
end

function SWGRP.Pocket.RequestDrop( ply )
	if not IsValid( ply ) then return end
	syncPocket( ply )
	net.Start( "SWGRP_PocketOpen" )
	net.Send( ply )
end

net.Receive( "SWGRP_PocketDrop", function( _, ply )
	SWGRP.Pocket.Drop( ply, net.ReadUInt( 4 ) )
end )

net.Receive( "SWGRP_PocketStore", function( _, ply )
	local slot = net.ReadUInt( 4 )
	local class = net.ReadString()
	SWGRP.Pocket.StoreWeapon( ply, slot > 0 and slot or nil, class )
end )

net.Receive( "SWGRP_PocketSwap", function( _, ply )
	SWGRP.Pocket.Swap( ply, net.ReadUInt( 4 ), net.ReadUInt( 4 ) )
end )

net.Receive( "SWGRP_PocketRequestSync", function( _, ply )
	syncPocket( ply )
end )

net.Receive( "SWGRP_PocketQuickStore", function( _, ply )
	SWGRP.Pocket.Store( ply, false )
end )

hook.Add( "SWGRPPlayerArrested", "SWGRP_PocketArrestDrop", function( target )
	if not IsValid( target ) then return end
	local slots = SWGRP.Pocket.GetSlots( target )
	for i = 1, SWGRP.Pocket.Max() do slots[i] = false end
	syncPocket( target )
end )

hook.Add( "PlayerInitialSpawn", "SWGRP_PocketInitialSync", function( ply )
	timer.Simple( 1, function()
		if IsValid( ply ) then syncPocket( ply ) end
	end )
end )

--[[---------------------------------------------------------------------------
    Shipment crate world GUI + spinning weapon preview (hook-driven so it
    works even when entity CLIENT blocks are not on the server ENT table).
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Shipment = SWGRP.Shipment or {}

local S = SWGRP.Shipment
local DRAW_MAX = 600
local PREVIEW_SPIN = 80
local PREVIEW_SCALE = 0.44
local PREVIEW_HOVER = 10
local PREVIEW_BOB = 2
local LABEL_OFFSET = 3

local function readRemaining( ent )
	return ent.GetRemaining and ent:GetRemaining() or ent:GetNW2Int( "Remaining", 0 )
end

local function readWeaponClass( ent )
	if ent.GetWeaponClass then
		local class = ent:GetWeaponClass()
		if class and class ~= "" then return class end
	end
	return ent:GetNW2String( "WeaponClass", "" )
end

local function readShipmentName( ent )
	if ent.GetShipmentName then
		local name = ent:GetShipmentName()
		if name and name ~= "" then return name end
	end
	return ent:GetNW2String( "ShipmentName", "" )
end

local function readPreviewModel( ent )
	if ent.GetPreviewModel then
		local mdl = ent:GetPreviewModel()
		if mdl and mdl ~= "" then return mdl end
	end
	return ent:GetNW2String( "PreviewModel", "" )
end

function S.GetDisplayName( ent )
	local class = readWeaponClass( ent )
	if class ~= "" then
		local swep = weapons.Get( class )
		if swep and swep.PrintName and swep.PrintName ~= "" then
			return swep.PrintName
		end
		return class
	end

	local name = readShipmentName( ent )
	if name ~= "" then return name end
	return "Shipment"
end

function S.GetLabelPos( ent )
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local cx = ( mins.x + maxs.x ) * 0.5
	local cy = ( mins.y + maxs.y ) * 0.5
	local cz = ( mins.z + maxs.z ) * 0.5

	local ply = LocalPlayer()
	if not IsValid( ply ) then
		return ent:LocalToWorld( Vector( maxs.x + LABEL_OFFSET, cy, cz ) )
	end

	local localEye = ent:WorldToLocal( ply:EyePos() )
	local toEye = localEye - Vector( cx, cy, cz )
	local localPos

	if math.abs( toEye.x ) >= math.abs( toEye.y ) then
		local faceX = toEye.x >= 0 and maxs.x or mins.x
		local bump = toEye.x >= 0 and LABEL_OFFSET or -LABEL_OFFSET
		localPos = Vector( faceX + bump, cy, cz )
	else
		local faceY = toEye.y >= 0 and maxs.y or mins.y
		local bump = toEye.y >= 0 and LABEL_OFFSET or -LABEL_OFFSET
		localPos = Vector( cx, faceY + bump, cz )
	end

	return ent:LocalToWorld( localPos )
end

function S.GetPreviewTop( ent )
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local _, rmaxs = ent:GetRenderBounds()
	local topZ = math.max( maxs.z, rmaxs.z )
	return ent:LocalToWorld( Vector(
		( mins.x + maxs.x ) * 0.5,
		( mins.y + maxs.y ) * 0.5,
		topZ
	) )
end

function S.ResolveWorldModel( ent, class )
	local networked = readPreviewModel( ent )
	if networked ~= "" and util.IsValidModel( networked ) then
		return networked
	end

	local swep = weapons.Get( class )
	local wm = swep and swep.WorldModel
	if wm and wm ~= "" and util.IsValidModel( wm ) then return wm end

	if SWGRP.GetWeaponWorldModel then
		wm = SWGRP.GetWeaponWorldModel( class )
		if wm and util.IsValidModel( wm ) then return wm end
	end

	return nil
end

function S.GetPreviewModel( ent )
	local class = readWeaponClass( ent )
	local wm = S.ResolveWorldModel( ent, class )
	local key = ( wm or "" ) .. "|" .. class

	if ent.SWGRP_PreviewKey == key and IsValid( ent.SWGRP_PreviewModel ) then
		return ent.SWGRP_PreviewModel
	end

	if IsValid( ent.SWGRP_PreviewModel ) then ent.SWGRP_PreviewModel:Remove() end
	ent.SWGRP_PreviewModel = nil
	ent.SWGRP_PreviewKey = key

	if not wm then return nil end

	local mdl = ClientsideModel( wm, RENDERGROUP_OPAQUE )
	if IsValid( mdl ) then
		mdl:SetNoDraw( true )
		ent.SWGRP_PreviewModel = mdl
	end

	return ent.SWGRP_PreviewModel
end

function S.DrawWeaponPreview( ent )
	local mdl = S.GetPreviewModel( ent )
	if not IsValid( mdl ) then return end

	local scale = PREVIEW_SCALE * 0.8
	local bob = math.sin( CurTime() * 2 ) * PREVIEW_BOB
	local target = S.GetPreviewTop( ent ) + Vector( 0, 0, PREVIEW_HOVER + bob )
	local ang = Angle( 0, ( CurTime() * PREVIEW_SPIN ) % 360, 0 )

	local offset = mdl:OBBCenter() * scale
	offset:Rotate( ang )

	mdl:SetModelScale( scale )
	mdl:SetPos( target - offset )
	mdl:SetAngles( ang )
	mdl:SetupBones()
	mdl:DrawModel()
end

function S.DrawCrate( ent )
	if not IsValid( ent ) then return end

	local dist = ent:GetPos():Distance( EyePos() )
	if dist > DRAW_MAX then return end

	S.DrawWeaponPreview( ent )

	local remaining = readRemaining( ent )
	local subtitle = remaining > 0
		and string.format( "SHIPMENT — %d left · Press E", remaining )
		or "SHIPMENT — Empty"

	if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
		SWGRP.UI.DrawWorldLabel(
			ent,
			S.GetDisplayName( ent ),
			subtitle,
			Color( 255, 120, 50 ),
			S.GetLabelPos( ent )
		)
	end
end

function S.DrawWeaponPickup( ent )
	if not IsValid( ent ) then return end
	if ent:GetPos():Distance( EyePos() ) > 400 then return end

	local class = ent.ReadWeaponClass and ent:ReadWeaponClass() or ent:GetNW2String( "WeaponClass", "" )
	local name = class
	local swep = weapons.Get( class )
	if swep and swep.PrintName then name = swep.PrintName end

	if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
		SWGRP.UI.DrawWorldLabel( ent, name, "Press E to take", SWGRP.UI.Colors.accent )
	end
end

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_ShipmentDraw", function( _, skybox )
	if skybox then return end

	for _, ent in ipairs( ents.FindByClass( "swgrp_shipment" ) ) do
		S.DrawCrate( ent )
	end

	for _, ent in ipairs( ents.FindByClass( "swgrp_weapon_pickup" ) ) do
		S.DrawWeaponPickup( ent )
	end
end )

hook.Add( "EntityRemoved", "SWGRP_ShipmentPreviewCleanup", function( ent )
	if IsValid( ent.SWGRP_PreviewModel ) then
		ent.SWGRP_PreviewModel:Remove()
	end
	ent.SWGRP_PreviewModel = nil
	ent.SWGRP_PreviewKey = nil
end )

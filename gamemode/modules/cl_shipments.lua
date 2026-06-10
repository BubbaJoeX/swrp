--[[---------------------------------------------------------------------------
    Shipment crate world GUI + spinning weapon preview
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Shipment = SWGRP.Shipment or {}

local S = SWGRP.Shipment
local DRAW_MAX = 600
local PREVIEW_SPIN = 80
local PREVIEW_SCALE = 0.44
local PREVIEW_HOVER = 10
local PREVIEW_BOB = 2
local LABEL_OFFSET = 4
local FACE_CAM_SCALE = 0.11

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

local function modelOk( mdl )
	return mdl and mdl ~= "" and ( util.IsValidModel( mdl ) or file.Exists( mdl, "GAME" ) )
end

local function readPreviewModel( ent )
	if ent.GetPreviewModel then
		local mdl = ent:GetPreviewModel()
		if modelOk( mdl ) then return mdl end
	end
	local nw = ent:GetNW2String( "PreviewModel", "" )
	if modelOk( nw ) then return nw end
	return ""
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

function S.GetFacePlane( ent )
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local cx = ( mins.x + maxs.x ) * 0.5
	local cy = ( mins.y + maxs.y ) * 0.5
	local cz = ( mins.z + maxs.z ) * 0.5

	local ply = LocalPlayer()
	if not IsValid( ply ) then return nil end

	local localEye = ent:WorldToLocal( ply:EyePos() )
	local toEye = localEye - Vector( cx, cy, cz )
	local bump = math.max( maxs.x - mins.x, maxs.y - mins.y ) * 0.04 + LABEL_OFFSET

	local worldPos, worldNorm

	if math.abs( toEye.x ) >= math.abs( toEye.y ) then
		local lx = toEye.x >= 0 and maxs.x or mins.x
		worldPos = ent:LocalToWorld( Vector( lx, cy, cz ) )
		worldNorm = toEye.x >= 0 and ent:GetRight() or -ent:GetRight()
	else
		local ly = toEye.y >= 0 and maxs.y or mins.y
		worldPos = ent:LocalToWorld( Vector( cx, ly, cz ) )
		worldNorm = toEye.y >= 0 and ent:GetForward() or -ent:GetForward()
	end

	worldPos = worldPos + worldNorm * bump

	local ang = worldNorm:Angle()
	ang:RotateAroundAxis( ang:Right(), 90 )

	return worldPos, ang
end

function S.GetPreviewTop( ent )
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local _, mmaxs = ent:GetModelBounds()
	local topZ = math.max( maxs.z, mmaxs.z )
	return ent:LocalToWorld( Vector(
		( mins.x + maxs.x ) * 0.5,
		( mins.y + maxs.y ) * 0.5,
		topZ
	) )
end

function S.ResolveWorldModel( ent, class )
	local networked = readPreviewModel( ent )
	if modelOk( networked ) then return networked end

	local swep = weapons.Get( class )
	local wm = swep and swep.WorldModel
	if modelOk( wm ) then return wm end

	if SWGRP.GetWeaponWorldModel then
		wm = SWGRP.GetWeaponWorldModel( class )
		if modelOk( wm ) then return wm end
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

	util.PrecacheModel( wm )
	local mdl = ClientsideModel( wm, RENDERGROUP_OPAQUE )
	if IsValid( mdl ) then
		mdl:SetNoDraw( true )
		ent.SWGRP_PreviewModel = mdl
	end

	return ent.SWGRP_PreviewModel
end

function S.DrawFaceLabel( ent, title, subtitle, accent )
	local pos, ang = S.GetFacePlane( ent )
	if not pos or not ang then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local dist = ply:EyePos():Distance( pos )
	if dist > DRAW_MAX then return end

	accent = accent or Color( 255, 120, 50 )
	local alpha = math.Clamp( ( DRAW_MAX - dist ) / 200, 0.35, 1 ) * 255
	local hasSub = subtitle ~= nil and subtitle ~= ""

	surface.SetFont( "DermaDefaultBold" )
	local tw = surface.GetTextSize( title )
	local sw = 0
	if hasSub then
		surface.SetFont( "DermaDefault" )
		sw = surface.GetTextSize( subtitle )
	end

	local boxW = math.max( tw, sw ) + 28
	local boxH = hasSub and 48 or 30

	cam.IgnoreZ( true )
	cam.Start3D2D( pos, ang, FACE_CAM_SCALE )
		draw.RoundedBox( 4, -boxW / 2, -boxH / 2, boxW, boxH, Color( 8, 12, 20, alpha * 0.88 ) )
		surface.SetDrawColor( accent.r, accent.g, accent.b, alpha )
		surface.DrawOutlinedRect( -boxW / 2, -boxH / 2, boxW, boxH, 1 )

		draw.SimpleText( title, "DermaDefaultBold", 0, hasSub and -8 or 0, Color( accent.r, accent.g, accent.b, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if hasSub then
			draw.SimpleText( subtitle, "DermaDefault", 0, 12, Color( 220, 220, 220, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	cam.End3D2D()
	cam.IgnoreZ( false )
end

function S.DrawWeaponPreview( ent )
	local mdl = S.GetPreviewModel( ent )
	if not IsValid( mdl ) then return end

	local crateScale = ent.GetModelScale and ent:GetModelScale() or 1
	local scale = PREVIEW_SCALE * crateScale
	local bob = math.sin( CurTime() * 2 ) * PREVIEW_BOB
	local target = S.GetPreviewTop( ent ) + ent:GetUp() * ( PREVIEW_HOVER + bob )

	local ang = ent:GetAngles()
	ang:RotateAroundAxis( ent:GetUp(), ( CurTime() * PREVIEW_SPIN ) % 360 )

	mdl:SetModelScale( scale )
	mdl:SetPos( target )
	mdl:SetAngles( ang )
	mdl:SetupBones()

	cam.IgnoreZ( true )
	render.SuppressEngineLighting( true )
	mdl:DrawModel()
	render.SuppressEngineLighting( false )
	cam.IgnoreZ( false )
end

function S.DrawCrateOverlay( ent )
	if not IsValid( ent ) then return end

	local dist = ent:GetPos():Distance( EyePos() )
	if dist > DRAW_MAX then return end

	S.DrawWeaponPreview( ent )

	local remaining = readRemaining( ent )
	local subtitle = remaining > 0
		and string.format( "%d left · Press E", remaining )
		or "Empty"

	S.DrawFaceLabel( ent, S.GetDisplayName( ent ), subtitle, Color( 255, 120, 50 ) )
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


hook.Add( "EntityRemoved", "SWGRP_ShipmentPreviewCleanup", function( ent )
	if IsValid( ent.SWGRP_PreviewModel ) then
		ent.SWGRP_PreviewModel:Remove()
	end
	ent.SWGRP_PreviewModel = nil
	ent.SWGRP_PreviewKey = nil
end )

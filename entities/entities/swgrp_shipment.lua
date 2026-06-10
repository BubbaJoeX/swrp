AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Shipment"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.CrateModel = "models/cw_furnitures11/cw_furnitures11.mdl"
ENT.FallbackModel = "models/Items/item_item_crate.mdl"
ENT.ModelScale = 0.4
ENT.PreviewSpinSpeed = 80
ENT.PreviewScale = 0.55
ENT.PreviewHover = 8
ENT.PreviewBob = 2
ENT.LabelFaceOffset = 3

local function modelOk( mdl )
	return mdl and mdl ~= "" and ( util.IsValidModel( mdl ) or file.Exists( mdl, "GAME" ) )
end

if SERVER then
	util.PrecacheModel( ENT.CrateModel )
	util.PrecacheModel( ENT.FallbackModel )
end

if CLIENT then
	util.PrecacheModel( ENT.CrateModel )
	util.PrecacheModel( ENT.FallbackModel )
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Remaining" )
	self:NetworkVar( "String", 0, "WeaponClass" )
	self:NetworkVar( "String", 1, "ShipmentName" )
	self:NetworkVar( "String", 2, "PreviewModel" )
end

function ENT:ReadRemaining()
	return self.GetRemaining and self:GetRemaining() or self:GetNW2Int( "Remaining", 0 )
end

function ENT:ReadWeaponClass()
	if self.GetWeaponClass then
		local class = self:GetWeaponClass()
		if class and class ~= "" then return class end
	end
	return self:GetNW2String( "WeaponClass", "" )
end

function ENT:ReadShipmentName()
	if self.GetShipmentName then
		local name = self:GetShipmentName()
		if name and name ~= "" then return name end
	end
	return self:GetNW2String( "ShipmentName", "" )
end

function ENT:ReadPreviewModelPath()
	if self.GetPreviewModel then
		local mdl = self:GetPreviewModel()
		if mdl and mdl ~= "" then return mdl end
	end
	return self:GetNW2String( "PreviewModel", "" )
end

function ENT:GetCrateModel()
	return self.CrateModel
end

if SERVER then
	function ENT:ApplyCrateModel()
		local candidates = {
			self.CrateModel,
			self.FallbackModel,
			"models/Items/item_item_crate.mdl",
		}

		local scale = self.ModelScale or 1

		for _, mdl in ipairs( candidates ) do
			if not modelOk( mdl ) then continue end

			self:SetModel( mdl )
			self:SetModelScale( scale )
			self:PhysicsInit( SOLID_VPHYSICS )
			if IsValid( self:GetPhysicsObject() ) then
				return true
			end
		end

		return false
	end

	function ENT:ResolvePreviewModel( class, data )
		local preview = data and ( data.previewModel or data.model )
		if modelOk( preview ) then
			return preview
		end

		if SWGRP and SWGRP.GetWeaponWorldModel then
			preview = SWGRP.GetWeaponWorldModel( class )
			if modelOk( preview ) then
				return preview
			end
		end

		local swep = weapons.Get( class )
		if swep and modelOk( swep.WorldModel ) then
			return swep.WorldModel
		end

		return ""
	end

	function ENT:ApplyShipmentData()
		local data = self.SWGRP_ShipmentData
		if not data then return end

		local separate = self.SWGRP_Separate
		local amount = math.max( 1, tonumber( data.amount ) or 1 )
		local class = ( data.entities and data.entities[1] ) or ""

		self:SetRemaining( separate and 1 or amount )
		self:SetWeaponClass( class )
		self:SetShipmentName( data.name or "" )
		self:SetPreviewModel( self:ResolvePreviewModel( class, data ) )
	end

	function ENT:SetShipmentData( data, separate )
		self.SWGRP_ShipmentData = data
		self.SWGRP_Separate = separate or false

		if self:EntIndex() > 0 then
			self:ApplyShipmentData()
		end
	end

	function ENT:SetShipmentId( id )
		local ship = SWGRP.Shipments and SWGRP.Shipments[tonumber( id )]
		if not ship then return false end

		self:SetShipmentData( ship, false )
		return true
	end

	function ENT:SetShipmentState( state )
		state = state or {}
		local class = state.weapon or ""
		self.SWGRP_ShipmentData = {
			name          = state.name or "",
			amount        = state.remaining or 1,
			entities      = { class },
			previewModel  = state.previewModel,
		}
		self.SWGRP_Separate = false

		if self:EntIndex() > 0 then
			self:ApplyShipmentData()
		end
	end

	function ENT:Initialize()
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		if not self:ApplyCrateModel() then
			ErrorNoHalt( "[SWGRP] swgrp_shipment failed to create physics — check crate models.\n" )
		end

		self:ApplyShipmentData()

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:GetEjectPos()
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local _, mmaxs = self:GetModelBounds()
		local topZ = math.max( maxs.z, mmaxs.z )
		return self:LocalToWorld( Vector(
			( mins.x + maxs.x ) * 0.5,
			( mins.y + maxs.y ) * 0.5,
			topZ + 6
		) )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.5

		if self:GetRemaining() <= 0 then
			SWGRP.Notify( activator, "This shipment crate is empty." )
			return
		end

		local class = self:GetWeaponClass()
		if class == "" or not weapons.Get( class ) then
			SWGRP.Notify( activator, "This shipment crate has no contents configured." )
			return
		end

		local pickup = SWGRP.Economy.EjectWeaponFromCrate( self, class, activator )
		if not IsValid( pickup ) then
			SWGRP.Notify( activator, "Couldn't eject weapon from crate." )
			return
		end

		self:SetRemaining( self:GetRemaining() - 1 )

		local label = self:GetShipmentName() ~= "" and self:GetShipmentName() or class
		local remaining = self:GetRemaining()

		if remaining > 0 then
			SWGRP.Notify( activator, string.format( "Ejected %s from the crate. %d remaining.", label, remaining ) )
		else
			SWGRP.Notify( activator, string.format( "Ejected the last %s. Crate emptied.", label ) )
			self:Remove()
		end
	end
end

if CLIENT then
	local DRAW_DIST = 700
	local PREVIEW_SPIN = 80
	local PREVIEW_SCALE = 1.0
	local PREVIEW_LIFT = 2
	local PREVIEW_BOB = 1.5

	local function modelOk( mdl )
		return mdl and mdl ~= "" and ( util.IsValidModel( mdl ) or file.Exists( mdl, "GAME" ) )
	end

	function ENT:GetRemainingClient()
		return self.GetRemaining and self:GetRemaining() or self:GetNW2Int( "Remaining", 0 )
	end

	function ENT:GetWeaponClassClient()
		if self.GetWeaponClass then
			local class = self:GetWeaponClass()
			if class and class ~= "" then return class end
		end
		return self:GetNW2String( "WeaponClass", "" )
	end

	function ENT:GetPreviewModelPath()
		if self.GetPreviewModel then
			local mdl = self:GetPreviewModel()
			if modelOk( mdl ) then return mdl end
		end
		local nw = self:GetNW2String( "PreviewModel", "" )
		if modelOk( nw ) then return nw end
		return ""
	end

	function ENT:GetDisplayTitle()
		local class = self:GetWeaponClassClient()
		if class ~= "" then
			local swep = weapons.Get( class )
			if swep and swep.PrintName and swep.PrintName ~= "" then
				return swep.PrintName
			end
			return class
		end

		if self.GetShipmentName then
			local name = self:GetShipmentName()
			if name and name ~= "" then return name end
		end
		local nwName = self:GetNW2String( "ShipmentName", "" )
		if nwName ~= "" then return nwName end

		return "Shipment"
	end

	function ENT:GetFaceLabelLocal()
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local cx = ( mins.x + maxs.x ) * 0.5
		local cy = ( mins.y + maxs.y ) * 0.5
		local cz = ( mins.z + maxs.z ) * 0.5

		local ply = LocalPlayer()
		if not IsValid( ply ) then return Vector( cx, cy, cz ) end

		local localEye = self:WorldToLocal( ply:EyePos() )
		local toEye = localEye - Vector( cx, cy, cz )
		local bump = math.max( maxs.x - mins.x, maxs.y - mins.y ) * 0.04 + 2

		if math.abs( toEye.x ) >= math.abs( toEye.y ) then
			local lx = toEye.x >= 0 and maxs.x or mins.x
			local nx = toEye.x >= 0 and 1 or -1
			return Vector( lx + nx * bump, cy, cz )
		end

		local ly = toEye.y >= 0 and maxs.y or mins.y
		local ny = toEye.y >= 0 and 1 or -1
		return Vector( cx, ly + ny * bump, cz )
	end

	function ENT:GetFaceLabelAngles()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return Angle( 0, 0, 90 ) end
		local relYaw = ply:EyeAngles().y - self:GetAngles().y
		return Angle( 0, relYaw, 90 )
	end

	function ENT:GetPreviewLocalPos( bob )
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local _, mmaxs = self:GetModelBounds()
		local topZ = math.max( maxs.z, mmaxs.z ) + PREVIEW_LIFT + ( bob or 0 )
		return Vector(
			( mins.x + maxs.x ) * 0.5,
			( mins.y + maxs.y ) * 0.5,
			topZ
		)
	end

	function ENT:ResolvePreviewWorldModel()
		local path = self:GetPreviewModelPath()
		if modelOk( path ) then return path end

		local class = self:GetWeaponClassClient()
		if class ~= "" then
			local swep = weapons.Get( class )
			if swep and modelOk( swep.WorldModel ) then return swep.WorldModel end
			if SWGRP and SWGRP.GetWeaponWorldModel then
				local wm = SWGRP.GetWeaponWorldModel( class )
				if modelOk( wm ) then return wm end
			end
		end

		return nil
	end

	function ENT:UpdateClientsideWeapon()
		local remaining = self:GetRemainingClient()
		if remaining <= 0 then
			if IsValid( self.SWGRP_CsWeapon ) then
				self.SWGRP_CsWeapon:SetParent( nil )
				self.SWGRP_CsWeapon:Remove()
			end
			self.SWGRP_CsWeapon = nil
			self.SWGRP_PreviewKey = nil
			return
		end

		local class = self:GetWeaponClassClient()
		local wm = self:ResolvePreviewWorldModel()
		if not wm then return end

		local key = wm .. "|" .. class
		if self.SWGRP_PreviewKey == key and IsValid( self.SWGRP_CsWeapon ) then return end

		if IsValid( self.SWGRP_CsWeapon ) then
			self.SWGRP_CsWeapon:SetParent( nil )
			self.SWGRP_CsWeapon:Remove()
		end

		util.PrecacheModel( wm )
		local mdl = ClientsideModel( wm, RENDERGROUP_TRANSLUCENT )
		if not IsValid( mdl ) then return end

		mdl:SetNoDraw( true )
		mdl:SetParent( self )
		self.SWGRP_CsWeapon = mdl
		self.SWGRP_PreviewKey = key
	end

	function ENT:PushEntityMatrix()
		local m = Matrix()
		m:Translate( self:GetPos() )
		m:Rotate( self:GetAngles() )
		cam.PushModelMatrix( m )
	end

	function ENT:PopEntityMatrix()
		cam.PopModelMatrix()
	end

	function ENT:DrawFaceGUI()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end
		if ply:EyePos():Distance( self:GetPos() ) > DRAW_DIST then return end

		local remaining = self:GetRemainingClient()
		local title = self:GetDisplayTitle()
		local subtitle = remaining > 0
			and string.format( "%d in crate · Press E", remaining )
			or "Empty"

		local span = math.max( self:OBBMaxs().x - self:OBBMins().x, self:OBBMaxs().y - self:OBBMins().y )
		local camScale = math.Clamp( span * 0.0045, 0.055, 0.13 )
		local accent = Color( 255, 120, 50 )

		surface.SetFont( "DermaDefaultBold" )
		local tw = surface.GetTextSize( title )
		surface.SetFont( "DermaDefault" )
		local sw = surface.GetTextSize( subtitle )
		local boxW = math.max( tw, sw ) + 30
		local boxH = 50

		cam.IgnoreZ( true )
		self:PushEntityMatrix()
		cam.Start3D2D( self:GetFaceLabelLocal(), self:GetFaceLabelAngles(), camScale )
			draw.RoundedBox( 6, -boxW / 2, -boxH / 2, boxW, boxH, Color( 8, 12, 20, 220 ) )
			surface.SetDrawColor( accent )
			surface.DrawOutlinedRect( -boxW / 2, -boxH / 2, boxW, boxH, 2 )

			draw.SimpleText( title, "DermaDefaultBold", 0, -10, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( subtitle, "DermaDefault", 0, 12, Color( 220, 220, 220 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		cam.End3D2D()
		self:PopEntityMatrix()
		cam.IgnoreZ( false )
	end

	function ENT:DrawSpinningWeapon()
		local remaining = self:GetRemainingClient()
		if remaining <= 0 then return end

		local ply = LocalPlayer()
		if not IsValid( ply ) or ply:EyePos():Distance( self:GetPos() ) > DRAW_DIST then return end

		self:UpdateClientsideWeapon()
		local mdl = self.SWGRP_CsWeapon
		if not IsValid( mdl ) then return end

		local bob = math.sin( CurTime() * 2 ) * PREVIEW_BOB
		local scale = PREVIEW_SCALE * ( self:GetModelScale() or 1 )

		if mdl:GetParent() ~= self then
			mdl:SetParent( self )
		end

		mdl:SetLocalPos( self:GetPreviewLocalPos( bob ) )
		mdl:SetLocalAngles( Angle( 0, ( CurTime() * PREVIEW_SPIN ) % 360, 0 ) )
		mdl:SetModelScale( scale )
		mdl:SetupBones()

		render.SuppressEngineLighting( true )
		mdl:DrawModel()
		render.SuppressEngineLighting( false )
	end

	function ENT:EnsureRenderBounds()
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local _, mmaxs = self:GetModelBounds()
		local topZ = math.max( maxs.z, mmaxs.z ) + 28
		self:SetRenderBounds(
			Vector( mins.x, mins.y, mins.z ),
			Vector( maxs.x, maxs.y, topZ )
		)
	end

	function ENT:Draw()
		self:EnsureRenderBounds()
		self:DrawModel()
		self:DrawFaceGUI()
		self:DrawSpinningWeapon()
	end

	hook.Add( "EntityRemoved", "SWGRP_ShipmentCsWeaponCleanup", function( ent )
		if ent:GetClass() ~= "swgrp_shipment" then return end
		if IsValid( ent.SWGRP_CsWeapon ) then
			ent.SWGRP_CsWeapon:SetParent( nil )
			ent.SWGRP_CsWeapon:Remove()
		end
		ent.SWGRP_CsWeapon = nil
		ent.SWGRP_PreviewKey = nil
	end )
end

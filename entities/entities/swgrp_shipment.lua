AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Shipment"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.CrateModel = "models/starwars/bandit/3rd_cargo_box.mdl"
ENT.FallbackModel = "models/Items/item_item_crate.mdl"
ENT.ModelScale = 0.8
ENT.PreviewSpinSpeed = 80
ENT.PreviewScale = 0.55
ENT.PreviewHover = 10
ENT.PreviewBob = 2
ENT.LabelFaceOffset = 3

if SERVER then
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

function ENT:ReadPreviewModel()
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

		for _, mdl in ipairs( candidates ) do
			if not mdl or mdl == "" or not util.IsValidModel( mdl ) then continue end

			self:SetModel( mdl )
			self:PhysicsInit( SOLID_VPHYSICS )
			if IsValid( self:GetPhysicsObject() ) then
				return true
			end
		end

		return false
	end

	function ENT:ResolvePreviewModel( class, data )
		local preview = data and ( data.previewModel or data.model )
		if preview and preview ~= "" and util.IsValidModel( preview ) then
			return preview
		end

		if SWGRP and SWGRP.GetWeaponWorldModel then
			preview = SWGRP.GetWeaponWorldModel( class )
			if preview and util.IsValidModel( preview ) then
				return preview
			end
		end

		local swep = weapons.Get( class )
		if swep and swep.WorldModel and util.IsValidModel( swep.WorldModel ) then
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
		self:ApplyCrateModel()
		self:SetModelScale( self.ModelScale or 1 )

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		if not IsValid( self:GetPhysicsObject() ) then
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
	function ENT:Draw()
		self:DrawModel()

		if SWGRP and SWGRP.Shipment and SWGRP.Shipment.DrawCrateOverlay then
			SWGRP.Shipment.DrawCrateOverlay( self )
		end
	end
end

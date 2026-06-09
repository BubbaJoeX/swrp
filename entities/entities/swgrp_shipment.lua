AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Shipment"
ENT.Category = "SWGRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Remaining" )
	self:NetworkVar( "String", 0, "WeaponClass" )
end

if SERVER then
	function ENT:SetShipmentData( data, separate )
		self.SWGRP_ShipmentData = data
		self.SWGRP_Separate = separate
		self:SetRemaining( separate and 1 or data.amount )
		self:SetWeaponClass( data.entities[1] or "" )
	end

	function ENT:Initialize()
		self:SetModel( "models/Items/item_item_crate.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if self:GetRemaining() <= 0 then return end

		local class = self:GetWeaponClass()
		if class == "" then return end

		activator:Give( class )
		self:SetRemaining( self:GetRemaining() - 1 )

		if self:GetRemaining() <= 0 then
			self:Remove()
		end
	end
end

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Pickup"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.FallbackModel = "models/weapons/w_pistol.mdl"

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "WeaponClass" )
end

function ENT:ReadWeaponClass()
	if self.GetWeaponClass then
		local class = self:GetWeaponClass()
		if class and class ~= "" then return class end
	end
	return self:GetNW2String( "WeaponClass", "" )
end

local function modelOk( mdl )
	return mdl and mdl ~= "" and ( util.IsValidModel( mdl ) or file.Exists( mdl, "GAME" ) )
end

if SERVER then
	function ENT:ResolveWorldModel( class, worldModel )
		local mdl = worldModel
		if not modelOk( mdl ) then
			if SWGRP and SWGRP.GetWeaponWorldModel then
				mdl = SWGRP.GetWeaponWorldModel( class )
			end
		end
		if not modelOk( mdl ) then
			local swep = weapons.Get( class )
			mdl = swep and swep.WorldModel
		end
		if not modelOk( mdl ) then
			mdl = self.FallbackModel
		end
		return mdl
	end

	function ENT:SetWeaponData( class, worldModel )
		self.SWGRP_PendingClass = class or ""
		self.SWGRP_PendingModel = worldModel

		if self:EntIndex() > 0 then
			self:ApplyWeaponData()
		end
	end

	function ENT:ApplyWeaponData()
		local class = self.SWGRP_PendingClass or self:GetWeaponClass() or ""
		local mdl = self:ResolveWorldModel( class, self.SWGRP_PendingModel )

		self:SetWeaponClass( class )
		self:SetModel( mdl )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

		if not IsValid( self:GetPhysicsObject() ) then
			self:PhysicsInitBox( self:OBBMins(), self:OBBMaxs() )
		end

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
		else
			self:SetMoveType( MOVETYPE_NONE )
			self:SetSolid( SOLID_BBOX )
		end
	end

	function ENT:Initialize()
		if self.SWGRP_PendingClass or self:GetWeaponClass() ~= "" then
			self:ApplyWeaponData()
		else
			self:SetWeaponData( "weapon_pistol" )
		end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		local class = self:GetWeaponClass()
		if class == "" or not weapons.Get( class ) then
			SWGRP.Notify( activator, "This weapon pickup is invalid." )
			self:Remove()
			return
		end

		if SWGRP.GrantWeapon( activator, class ) then
			local wep = activator:GetWeapon( class )
			if IsValid( wep ) then
				activator:SelectWeapon( class )
			end
			local swep = weapons.Get( class )
			local label = swep and swep.PrintName or class
			SWGRP.Notify( activator, "Equipped " .. label .. "." )
			self:Remove()
		else
			SWGRP.Notify( activator, "Couldn't equip that weapon." )
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		if SWGRP and SWGRP.Shipment and SWGRP.Shipment.DrawWeaponPickup then
			SWGRP.Shipment.DrawWeaponPickup( self )
		end
	end
end

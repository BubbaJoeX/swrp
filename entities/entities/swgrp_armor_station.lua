AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Armor Repair Station"
ENT.Category = "SWGRP"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_combine/suit_charger001.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		activator:SetArmor( 100 )
		self:EmitSound( "items/battery_pickup.wav" )
	end
end

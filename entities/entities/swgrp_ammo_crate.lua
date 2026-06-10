AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Energy Cell"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/starwars/items/energy_cell.mdl"

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if not SWGRP.Ammo or not SWGRP.Ammo.UseWorldCell( activator ) then return end
		self:Remove()
	end
end

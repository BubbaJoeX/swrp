AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ammo Resupply Crate"
ENT.Category = "SWGRP"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/Items/ammocrate_smg1.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		for _, wep in ipairs( activator:GetWeapons() ) do
			local ammoType = wep:GetPrimaryAmmoType()
			if ammoType >= 0 then
				activator:GiveAmmo( 30, ammoType, true )
			end
		end
	end
end

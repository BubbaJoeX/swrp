AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ration Dispenser"
ENT.Category = "SWGRP"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_junk/garbage_metalcan001a.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		-- Per-player cooldown so a held use key can't spam heal/feed/notifications.
		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 3

		activator:SetHealth( math.min( activator:GetMaxHealth(), activator:Health() + 15 ) )
		SWGRP.Hunger.Feed( activator, 35 )
	end
end

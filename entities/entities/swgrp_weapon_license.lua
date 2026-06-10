AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon License"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/props_lab/clipboard.mdl"

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

		if activator:SWGRP_HasLicense() then
			SWGRP.Notify( activator, "You already have a weapon license." )
			return
		end

		activator:SWGRP_SetLicense( true )
		SWGRP.Notify( activator, SWGRP.Lang.license_granted or "Weapon license granted." )
		self:EmitSound( "items/suitchargepick1.wav", 65 )
		self:Remove()
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "WEAPON LICENSE", "Press E to claim", SWGRP.UI.Colors.accent )
		end
	end
end

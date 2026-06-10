AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Medical Station"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/props/starwars/medical/health_droid.mdl"

-- Hold-to-heal tuning.
ENT.HealInterval = 0.1   -- seconds between heal ticks
ENT.HealPerTick  = 2     -- HP restored per tick (~20 HP/sec)

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		-- Continuous use fires :Use repeatedly while the player holds their use
		-- key, letting them top up health gradually rather than in one press.
		self:SetUseType( CONTINUOUS_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		local now = CurTime()
		self.SWGRP_NextHeal = self.SWGRP_NextHeal or {}
		if ( self.SWGRP_NextHeal[activator] or 0 ) > now then return end
		self.SWGRP_NextHeal[activator] = now + self.HealInterval

		local hp = activator:Health()
		local maxhp = activator:GetMaxHealth()
		if hp >= maxhp then return end

		activator:SetHealth( math.min( maxhp, hp + self.HealPerTick ) )

		if ( self.SWGRP_NextSound or 0 ) <= now then
			self.SWGRP_NextSound = now + 0.6
			self:EmitSound( "items/medshot4.wav", 55 )
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "MEDICAL STATION", "Hold E to heal", Color( 120, 220, 120 ) )
		end
	end
end

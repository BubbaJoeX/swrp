AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Armor Kiosk"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/starwars/items/shield_large.mdl"

-- Hold-to-recharge tuning.
ENT.ArmorInterval = 0.1   -- seconds between armor ticks
ENT.ArmorPerTick  = 2     -- armor restored per tick (~20/sec)
ENT.ArmorMax      = 100

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		-- Continuous use so players hold their use key to recharge armor over time.
		self:SetUseType( CONTINUOUS_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		local now = CurTime()
		self.SWGRP_NextCharge = self.SWGRP_NextCharge or {}
		if ( self.SWGRP_NextCharge[activator] or 0 ) > now then return end
		self.SWGRP_NextCharge[activator] = now + self.ArmorInterval

		local armor = activator:Armor()
		if armor >= self.ArmorMax then return end

		activator:SetArmor( math.min( self.ArmorMax, armor + self.ArmorPerTick ) )

		if ( self.SWGRP_NextSound or 0 ) <= now then
			self.SWGRP_NextSound = now + 0.6
			self:EmitSound( "items/battery_pickup.wav", 55 )
		end
	end
end

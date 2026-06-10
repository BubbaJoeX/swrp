AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Credit Press Case"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- WIP mount frame; sub-coordinate offsets for press placement are scripted here
-- when the final case model ships.
ENT.DefaultModel = "models/props_c17/suitcase_passenger_physics.mdl"
ENT.MountOffsets = {
	{ pos = Vector( 0, 0, 8 ), ang = Angle( 0, 0, 0 ) },
}

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "HasPress" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetHasPress( false )
		self.SWGRP_MountedPress = nil

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:GetMountTransform( slot )
		slot = slot or 1
		local offset = self.MountOffsets[slot] or self.MountOffsets[1]
		local pos = self:LocalToWorld( offset.pos )
		local ang = self:LocalToWorldAngles( offset.ang )
		return pos, ang
	end

	function ENT:MountPress( press )
		if not IsValid( press ) or press:GetClass() ~= "swgrp_credit_harvester" then return false end
		if self:GetHasPress() then return false end

		local pos, ang = self:GetMountTransform( 1 )
		press:SetPos( pos )
		press:SetAngles( ang )
		press:SetParent( self )

		local phys = press:GetPhysicsObject()
		if IsValid( phys ) then phys:EnableMotion( false ) end

		self.SWGRP_MountedPress = press
		self:SetHasPress( true )
		return true
	end

	function ENT:UnmountPress()
		if not IsValid( self.SWGRP_MountedPress ) then return end

		local press = self.SWGRP_MountedPress
		press:SetParent( nil )
		local phys = press:GetPhysicsObject()
		if IsValid( phys ) then phys:EnableMotion( true ) end

		self.SWGRP_MountedPress = nil
		self:SetHasPress( false )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if not SWGRP.Ownership or not SWGRP.Ownership.IsOwner( activator, self ) then
			SWGRP.Notify( activator, "You don't own this case." )
			return
		end

		if self:GetHasPress() then
			self:UnmountPress()
			SWGRP.Notify( activator, "Credit press unmounted from case." )
			return
		end

		local nearest, bestDist
		for _, ent in ipairs( ents.FindInSphere( self:GetPos(), 120 ) ) do
			if ent:GetClass() == "swgrp_credit_harvester" and ent ~= self.SWGRP_MountedPress then
				local dist = ent:GetPos():DistToSqr( self:GetPos() )
				if not bestDist or dist < bestDist then
					bestDist = dist
					nearest = ent
				end
			end
		end

		if not IsValid( nearest ) then
			SWGRP.Notify( activator, "Place a credit press nearby, then press E to mount it." )
			return
		end

		if self:MountPress( nearest ) then
			SWGRP.Notify( activator, "Credit press mounted to case." )
		end
	end

	function ENT:OnRemove()
		if IsValid( self.SWGRP_MountedPress ) then
			self.SWGRP_MountedPress:SetParent( nil )
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local status = self:GetHasPress() and "Press mounted" or "Empty case - E to mount"
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "CREDIT PRESS CASE", status, SWGRP.UI.Colors.accent )
		end
	end
end

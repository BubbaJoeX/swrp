AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Credit Harvester"
ENT.Category = "SWGRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "StoredCredits" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_c17/consolebox01a.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetStoredCredits( 0 )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end

		local ent = self
		timer.Create( "SWGRP_Harvester_" .. self:EntIndex(), 30, 0, function()
			if not IsValid( ent ) then return end
			if ent:GetStoredCredits() < 5000 then
				ent:SetStoredCredits( ent:GetStoredCredits() + math.random( 40, 80 ) )
			end
		end )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if self.SWGRP_Owner and self.SWGRP_Owner ~= activator then return end
		local stored = self:GetStoredCredits()
		if stored <= 0 then return end
		activator:SWGRP_AddCredits( stored )
		self:SetStoredCredits( 0 )
	end

	function ENT:OnRemove()
		timer.Remove( "SWGRP_Harvester_" .. self:EntIndex() )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end

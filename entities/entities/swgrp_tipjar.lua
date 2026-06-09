AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Tip Jar"
ENT.Category = "SWGRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Tips" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_lab/jar01b.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetTips( 0 )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		if self.SWGRP_Owner == activator then
			local tips = self:GetTips()
			if tips > 0 then
				activator:SWGRP_AddCredits( tips )
				self:SetTips( 0 )
				SWGRP.Notify( activator, "Collected tips: " .. SWGRP.FormatCredits( tips ) )
			end
			return
		end

		local tip = 25
		if activator:SWGRP_TakeCredits( tip ) then
			self:SetTips( self:GetTips() + tip )
			SWGRP.Notify( activator, "You tipped " .. SWGRP.FormatCredits( tip ) )
		end
	end
end

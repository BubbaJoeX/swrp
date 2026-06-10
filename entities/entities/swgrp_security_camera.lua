AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Security Camera"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/props/cs_office/security_camera.mdl"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "CamIndex" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end

		self:SetCamIndex( self:EntIndex() )
	end

	function ENT:GetCamPos()
		return self:GetPos() + self:GetUp() * 4 + self:GetForward() * 2
	end

	function ENT:GetCamAng()
		return self:GetAngles()
	end

	function ENT:LinkOwnerScreens()
		if not IsValid( self.SWGRP_Owner ) then return end

		for _, screen in ipairs( ents.FindByClass( "swgrp_security_screen" ) ) do
			if IsValid( screen ) and screen.SWGRP_Owner == self.SWGRP_Owner then
				screen:RefreshCameraList()
			end
		end
	end

	function ENT:OnRemove()
		for _, screen in ipairs( ents.FindByClass( "swgrp_security_screen" ) ) do
			if IsValid( screen ) then
				screen:RefreshCameraList()
			end
		end
	end
else
	function ENT:GetCamPos()
		return self:GetPos() + self:GetUp() * 4 + self:GetForward() * 2
	end

	function ENT:GetCamAng()
		return self:GetAngles()
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

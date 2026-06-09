AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Holo Sign"
ENT.Category = "SWGRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "SignText" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/hunter/plates/plate1x1.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetSignText( "Advertise here" )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if self.SWGRP_Owner ~= activator and not activator:IsAdmin() then return end
		activator:ChatPrint( "Use /sign <text> while looking at your holo sign." )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local pos = self:GetPos() + self:GetUp() * 2
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		cam.Start3D2D( pos, ang, 0.1 )
			draw.SimpleText( self:GetSignText(), "DermaDefault", 0, 0, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Galactic Letter"
ENT.Category = "SWGRP"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "LetterText" )
	self:NetworkVar( "String", 1, "AuthorName" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/swcw_items/sw_datapad.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		if self:GetLetterText() == "" then
			self:SetLetterText( "Empty message." )
		end
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		activator:ChatPrint( "[Letter from " .. ( self:GetAuthorName() ~= "" and self:GetAuthorName() or "Unknown" ) .. "] " .. self:GetLetterText() )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local pos = self:GetPos() + Vector( 0, 0, 8 )
		local ang = Angle( 0, LocalPlayer():EyeAngles().y - 90, 90 )

		cam.Start3D2D( pos, ang, 0.08 )
			draw.SimpleText( "Galactic Letter", "DermaDefaultBold", 0, -20, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_CENTER )
			draw.SimpleText( string.sub( self:GetLetterText(), 1, 48 ), "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

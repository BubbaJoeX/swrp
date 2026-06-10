AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Dropped Credits"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.CreditModel   = "models/sw_galactic_credits/galactic_credit.mdl"
ENT.FallbackModel = "models/props_lab/box01a.mdl"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Credits" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.CreditModel )
		self:PhysicsInit( SOLID_VPHYSICS )

		-- If the galactic credit model isn't mounted on this server the entity
		-- has no physics mesh and would snap to the world origin; fall back to a
		-- guaranteed HL2 prop so dropped money always lands where it was dropped.
		if not IsValid( self:GetPhysicsObject() ) then
			self:SetModel( self.FallbackModel )
			self:PhysicsInit( SOLID_VPHYSICS )
		end

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		activator:SWGRP_AddCredits( self:GetCredits() )
		self:Remove()
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local pos = self:GetPos() + Vector( 0, 0, 20 )
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )
		cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.1 )
			draw.SimpleText( SWGRP.FormatCredits( self:GetCredits() ), "DermaDefaultBold", 0, 0, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

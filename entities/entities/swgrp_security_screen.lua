AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Security Screen"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/props_lab/monitor01a.mdl"
ENT.ScreenMaterial = "swgrp/security_screen"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "ActiveFeed" )
	self:NetworkVar( "Int", 1, "FeedCount" )
	self:NetworkVar( "Entity", 0, "LinkedCamera" )
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

		self.SWGRP_CameraList = {}
		self:SetActiveFeed( 0 )
		self:SetFeedCount( 0 )
	end

	function ENT:RefreshCameraList()
		self.SWGRP_CameraList = {}

		if not IsValid( self.SWGRP_Owner ) then
			self:SetFeedCount( 0 )
			return
		end

		for _, cam in ipairs( ents.FindByClass( "swgrp_security_camera" ) ) do
			if IsValid( cam ) and cam.SWGRP_Owner == self.SWGRP_Owner then
				table.insert( self.SWGRP_CameraList, cam )
			end
		end

		self:SetFeedCount( #self.SWGRP_CameraList )
		if self:GetActiveFeed() >= #self.SWGRP_CameraList then
			self:SetActiveFeed( 0 )
		end

		local cam = self.SWGRP_CameraList[self:GetActiveFeed() + 1]
		self:SetLinkedCamera( IsValid( cam ) and cam or NULL )
	end

	function ENT:GetActiveCamera()
		local idx = self:GetActiveFeed() + 1
		return self.SWGRP_CameraList and self.SWGRP_CameraList[idx]
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if not SWGRP.Ownership or not SWGRP.Ownership.IsOwner( activator, self ) then
			if not activator:IsAdmin() then
				SWGRP.Notify( activator, "You don't own this security screen." )
				return
			end
		end

		self:RefreshCameraList()
		local count = #self.SWGRP_CameraList
		if count == 0 then
			SWGRP.Notify( activator, "No cameras linked. Place security cameras first." )
			return
		end

		local nextFeed = ( self:GetActiveFeed() + 1 ) % count
		self:SetActiveFeed( nextFeed )

		local cam = self.SWGRP_CameraList[nextFeed + 1]
		self:SetLinkedCamera( IsValid( cam ) and cam or NULL )
		local label = IsValid( cam ) and ( "Camera " .. ( nextFeed + 1 ) ) or "Feed"
		SWGRP.Notify( activator, "Switched to " .. label .. " (" .. ( nextFeed + 1 ) .. "/" .. count .. ")." )
	end
else
	function ENT:Draw()
		self:DrawModel()

		local count = self:GetFeedCount()
		if count <= 0 then return end

		local camEnt = self:GetLinkedCamera()
		if not IsValid( camEnt ) then return end

		if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) > 400000 then return end

		if SWGRP.Security and SWGRP.Security.RenderCameraView then
			SWGRP.Security.RenderCameraView( camEnt )
		end

		local rt = SWGRP.Security and SWGRP.Security.GetRT( camEnt:EntIndex() )
		if not rt then return end

		local camIdx = self:GetActiveFeed()
		local pos = self:GetPos() + self:GetForward() * 2.2 + self:GetUp() * 2
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )

		cam.Start3D2D( pos, ang, 0.05 )
			surface.SetDrawColor( 255, 255, 255, 255 )
			surface.SetMaterial( Material( "!" .. rt:GetName() ) )
			surface.DrawTexturedRect( -40, -30, 80, 60 )
			draw.SimpleText( "CAM " .. ( camIdx + 1 ) .. "/" .. count, "DermaDefault", 0, 35, Color( 200, 220, 255 ), TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

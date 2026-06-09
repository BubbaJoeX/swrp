AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Security Keypad"
ENT.Category = "SWGRP"
ENT.Spawnable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Cracking" )
	self:NetworkVar( "Entity", 0, "LinkedDoor" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_lab/keypad.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end

		self:LinkNearestDoor()
	end

	function ENT:LinkNearestDoor()
		local best, bestDist
		for _, ent in ipairs( ents.FindInSphere( self:GetPos(), 128 ) ) do
			if IsValid( ent ) and ent.isDoor and ent:isDoor() then
				local d = self:GetPos():DistToSqr( ent:GetPos() )
				if not bestDist or d < bestDist then
					best, bestDist = ent, d
				end
			end
		end
		if IsValid( best ) then
			self:SetLinkedDoor( best )
		end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		local door = self:GetLinkedDoor()
		if not IsValid( door ) then
			self:LinkNearestDoor()
			door = self:GetLinkedDoor()
		end

		if not IsValid( door ) then
			activator:ChatPrint( "This keypad is not linked to a door." )
			return
		end

		if not SWGRP.Doors or not SWGRP.Doors.CanAccess( activator, door ) then
			activator:ChatPrint( "Access denied." )
			return
		end

		local data = SWGRP.Doors.GetMasterData and SWGRP.Doors.GetMasterData( door )
		local locked = data and data.locked
		SWGRP.Doors.SetLockState( door, not locked )
		self:EmitSound( "buttons/button9.wav" )
	end

	-- Called by the keypad cracker SWEP.
	function ENT:BeginCrack( ply )
		if self:GetCracking() then return end

		local door = self:GetLinkedDoor()
		if not IsValid( door ) then
			self:LinkNearestDoor()
			door = self:GetLinkedDoor()
		end
		if not IsValid( door ) then
			ply:ChatPrint( "This keypad is not linked to a door." )
			return
		end

		self:SetCracking( true )
		self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 60 )

		local crackTime = SWGRP.Config and SWGRP.Config.KeypadCrackTime or 8

		timer.Simple( crackTime, function()
			if not IsValid( self ) then return end
			self:SetCracking( false )
			local d = self:GetLinkedDoor()
			if IsValid( d ) and SWGRP.Doors then
				SWGRP.Doors.SetLockState( d, false )
			end
			self:EmitSound( "buttons/button1.wav" )
			if IsValid( ply ) then
				SWGRP.Notify( ply, "Keypad cracked. Door unlocked." )
				SWGRP.Log( "law", ply:Nick() .. " (" .. ply:SteamID() .. ") cracked a keypad" )
			end
		end )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )

		local col = self:GetCracking() and Color( 255, 60, 60 ) or ( SWGRP.Config and SWGRP.Config.HUDColorAccent or Color( 80, 200, 255 ) )

		cam.Start3D2D( self:GetPos() + self:GetUp() * 6, ang, 0.05 )
			draw.SimpleText( self:GetCracking() and "BYPASSING..." or "LOCKED", "DermaDefaultBold", 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

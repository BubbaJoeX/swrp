if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Keypad Cracker"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click on a security keypad or door to bypass the lock."
SWEP.Category = "SWGRP"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.Slot = 2
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true
SWEP.HoldType = "normal"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

local function crackTime()
	return SWGRP.Config and SWGRP.Config.KeypadCrackTime or 8
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 1 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	local tr = owner:GetEyeTrace()
	if not IsValid( tr.Entity ) then return end
	if tr.HitPos:DistToSqr( owner:GetShootPos() ) > 16384 then -- 128 units
		SWGRP.Notify( owner, "Get closer to the keypad." )
		return
	end

	local ent = tr.Entity

	if ent:GetClass() == "swgrp_keypad" then
		ent:BeginCrack( owner )
		self:SetNextPrimaryFire( CurTime() + crackTime() )
		return
	end

	if ent.isDoor and ent:isDoor() then
		self:SetNextPrimaryFire( CurTime() + crackTime() )
		self:EmitSound( "ambient/levels/labs/electric_explosion1.wav", 60 )
		SWGRP.Notify( owner, "Bypassing door lock..." )

		timer.Simple( crackTime(), function()
			if not IsValid( self ) or not IsValid( ent ) then return end
			if SWGRP.Doors then SWGRP.Doors.SetLockState( ent, false ) end
			if IsValid( owner ) then
				SWGRP.Notify( owner, "Door lock bypassed." )
				SWGRP.Log( "law", owner:Nick() .. " (" .. owner:SteamID() .. ") bypassed a door lock" )
			end
		end )
		return
	end

	SWGRP.Notify( owner, "Aim at a keypad or door." )
end

function SWEP:SecondaryAttack()
end

if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Door Admin Tool"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click a door to open its admin configuration menu."
SWEP.Category = "SWGRP"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true
SWEP.HoldType = "pistol"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:Deploy()
	if SERVER and IsValid( self:GetOwner() ) then
		self:GetOwner():ChatPrint( "[SWGRP] Door tool equipped. Left-click a door." )
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.4 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then owner = self.Owner end
	if not IsValid( owner ) then return end

	if SWGRP.Doors and SWGRP.Doors.AdminDoorToolUse then
		SWGRP.Doors.AdminDoorToolUse( owner )
	else
		owner:ChatPrint( "[SWGRP] Door tool: server module not loaded. Restart the map/server." )
	end
end

function SWEP:SecondaryAttack()
end

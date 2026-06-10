if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Map Adjuster"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: open fog and light settings for this map."
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
SWEP.SlotPos = 6
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.UseHands = true
SWEP.HoldType = "pistol"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.4 )
	if CLIENT then return end
	if SWGRP.MapAdjust and SWGRP.MapAdjust.AdminToolPrimary then
		SWGRP.MapAdjust.AdminToolPrimary( self:GetOwner() )
	end
end

function SWEP:SecondaryAttack()
end

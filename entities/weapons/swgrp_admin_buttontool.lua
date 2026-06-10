if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Control Admin Tool"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click a map button or prop_dynamic to configure ownership."
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
SWEP.SlotPos = 3
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
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.4 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then owner = self.Owner end
	if not IsValid( owner ) then return end

	if SWGRP.Doors and SWGRP.Doors.AdminButtonToolUse then
		SWGRP.Doors.AdminButtonToolUse( owner )
	else
		owner:ChatPrint( "[SWGRP] Button tool: server module not loaded. Restart the map/server." )
	end
end

function SWEP:SecondaryAttack()
end

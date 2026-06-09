if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Restraint Bindings"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: Restrain player. Right click: Release."
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
SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.HoldType = "normal"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	if not SWGRP.Restraint.CanRestrain( self.Owner ) then return end

	self:SetNextPrimaryFire( CurTime() + 1 )

	local tr = self.Owner:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:IsPlayer() then return end

	SWGRP.Restraint.Restrain( self.Owner, tr.Entity )
end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	self:SetNextSecondaryFire( CurTime() + 1 )

	local tr = self.Owner:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:IsPlayer() then return end

	SWGRP.Restraint.Release( tr.Entity, self.Owner )
end

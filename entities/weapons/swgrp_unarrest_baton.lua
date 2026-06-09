if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Release Baton"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: Release detained player."
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
SWEP.Slot = 0
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.UseHands = true
SWEP.HoldType = "melee"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 1 )
	if CLIENT then return end
	if not self.Owner:SWGRP_IsGovernment() then return end

	local tr = self.Owner:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:IsPlayer() then return end
	if tr.HitPos:DistToSqr( self.Owner:GetShootPos() ) > 10000 then return end -- 100 units
	if not tr.Entity:SWGRP_IsArrested() then return end

	SWGRP.Police.UnArrest( tr.Entity, self.Owner )
end

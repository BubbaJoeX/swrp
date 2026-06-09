if SERVER then AddCSLuaFile() end



SWEP.PrintName = "Security Bypass"

SWEP.Author = "SWGRP"

SWEP.Instructions = "Left click: Bypass door lock."

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

SWEP.SlotPos = 1

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



	local tr = self.Owner:GetEyeTrace()

	if not IsValid( tr.Entity ) or not tr.Entity:isDoor() then return end



	self:SetNextPrimaryFire( CurTime() + 6 )

	SWGRP.Lockpick.Start( self.Owner, tr.Entity )

end


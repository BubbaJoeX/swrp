if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Climb Gloves"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Hold right mouse against a wall to climb."
SWEP.Category = "SWGRP"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.HoldType = "normal"

SWEP.ClimbSpeed = 180
SWEP.WallDist = 48
SWEP.WallCheck = 64

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:CanClimb( ply )
	if not IsValid( ply ) or not ply:Alive() then return false end
	if ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then return false end

	local tr = util.TraceLine( {
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * self.WallCheck,
		filter = ply,
		mask = MASK_SOLID,
	} )

	if not tr.Hit or tr.HitNormal:Dot( Vector( 0, 0, 1 ) ) > 0.6 then return false end
	if ply:GetPos():DistToSqr( tr.HitPos ) > self.WallDist * self.WallDist then return false end

	return true, tr
end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	local ok, tr = self:CanClimb( owner )
	if not ok then return end

	local vel = owner:GetVelocity()
	vel.z = self.ClimbSpeed
	owner:SetVelocity( vel - tr.HitNormal * 20 )

	self:SetNextSecondaryFire( CurTime() + 0.08 )
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.5 )
end

function SWEP:DrawHUD()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local ok = self:CanClimb( ply )
	if ok then
		draw.SimpleText( "Hold RIGHT CLICK to climb", "DermaDefault", ScrW() * 0.5, ScrH() * 0.8, Color( 120, 220, 255 ), TEXT_ALIGN_CENTER )
	end
end

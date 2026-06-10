if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Jail Spawn Tool"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: add jail point. Right click: menu. Reload: remove nearest."
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
SWEP.SlotPos = 5
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
		local owner = self:GetOwner()
		if SWGRP.JailSpawns and SWGRP.JailSpawns.SyncTo then
			SWGRP.JailSpawns.SyncTo( owner )
		end
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.35 )
	if CLIENT then return end
	if SWGRP.JailSpawns and SWGRP.JailSpawns.AdminToolPrimary then
		SWGRP.JailSpawns.AdminToolPrimary( self:GetOwner() )
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + 0.35 )
	if CLIENT then return end
	if SWGRP.JailSpawns and SWGRP.JailSpawns.AdminToolSecondary then
		SWGRP.JailSpawns.AdminToolSecondary( self:GetOwner() )
	end
end

function SWEP:Reload()
	if CLIENT then return end
	if SWGRP.JailSpawns and SWGRP.JailSpawns.AdminToolReload then
		SWGRP.JailSpawns.AdminToolReload( self:GetOwner() )
	end
	self:SetNextPrimaryFire( CurTime() + 0.35 )
	self:SetNextSecondaryFire( CurTime() + 0.35 )
end

function SWEP:DrawHUD()
	if SERVER then return end
	local count = SWGRP.JailSpawns and SWGRP.JailSpawns.Preview and #SWGRP.JailSpawns.Preview or 0
	draw.SimpleText( "Jail points: " .. count .. " on map", "DermaDefault", ScrW() * 0.5, ScrH() * 0.78, Color( 255, 120, 120 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

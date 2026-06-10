if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Mount Offset Tool"
SWEP.Author = "SWGRP"
SWEP.Instructions = "RMB parent · Reload freeze north · LMB capture · M export menu · Del clear all offsets"
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
SWEP.SlotPos = 7
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
	local owner = self:GetOwner()
	if SERVER and IsValid( owner ) and SWGRP.MountOffset then
		if SWGRP.MountOffset.SyncTo then
			SWGRP.MountOffset.SyncTo( owner )
		end
		if SWGRP.MountOffset.OpenMenuFor then
			SWGRP.MountOffset.OpenMenuFor( owner )
		end
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.35 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.MountOffset and SWGRP.MountOffset.AdminToolPrimary then
		SWGRP.MountOffset.AdminToolPrimary( owner )
	else
		owner:ChatPrint( "[SWGRP] Mount offset tool: server module not loaded." )
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + 0.35 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.MountOffset and SWGRP.MountOffset.AdminToolSecondary then
		SWGRP.MountOffset.AdminToolSecondary( owner )
	end
end

function SWEP:Reload()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.MountOffset and SWGRP.MountOffset.AdminToolReload then
		SWGRP.MountOffset.AdminToolReload( owner )
	end

	self:SetNextPrimaryFire( CurTime() + 0.35 )
	self:SetNextSecondaryFire( CurTime() + 0.35 )
end

function SWEP:DrawHUD()
	if SERVER then return end

	local MO = SWGRP.MountOffset
	local main = MO and MO.Client and MO.Client.mainName or "none"
	local count = MO and MO.Client and MO.Client.offsets and #MO.Client.offsets or 0

	draw.SimpleText(
		"Parent: " .. main .. "  |  offsets: " .. count,
		"DermaDefaultBold",
		ScrW() * 0.5,
		ScrH() * 0.76,
		Color( 255, 180, 50 ),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER
	)
	draw.SimpleText(
		"M menu · Del clear · RMB parent · Reload north · LMB capture",
		"DermaDefault",
		ScrW() * 0.5,
		ScrH() * 0.76 + 18,
		Color( 200, 200, 200 ),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER
	)
end

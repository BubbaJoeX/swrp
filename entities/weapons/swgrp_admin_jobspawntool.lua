if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Job Spawn Tool"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: add spawn. Right click: menu. Reload: remove nearest."
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
SWEP.SlotPos = 4
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
		owner:ChatPrint( "[SWGRP] Job spawn tool equipped." )
		owner:ChatPrint( "[SWGRP] Left click: add spawn. Right click: menu. Reload: remove nearest." )

		if SWGRP.JobSpawns and SWGRP.JobSpawns.SyncTo then
			SWGRP.JobSpawns.SyncTo( owner, SWGRP.JobSpawns.GetSelectedCommand( owner ) )
		end
	end
	return true
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.35 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.JobSpawns and SWGRP.JobSpawns.AdminToolPrimary then
		SWGRP.JobSpawns.AdminToolPrimary( owner )
	else
		owner:ChatPrint( "[SWGRP] Job spawn tool: server module not loaded. Restart the map/server." )
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + 0.35 )
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.JobSpawns and SWGRP.JobSpawns.AdminToolSecondary then
		SWGRP.JobSpawns.AdminToolSecondary( owner )
	end
end

function SWEP:Reload()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if SWGRP.JobSpawns and SWGRP.JobSpawns.AdminToolReload then
		SWGRP.JobSpawns.AdminToolReload( owner )
	end

	self:SetNextPrimaryFire( CurTime() + 0.35 )
	self:SetNextSecondaryFire( CurTime() + 0.35 )
end

function SWEP:DrawHUD()
	if SERVER then return end

	local cmd = SWGRP.JobSpawns and SWGRP.JobSpawns.SelectedCmd or LocalPlayer():GetNWString( "SWGRP_JobSpawnCmd", "" )
	if cmd == "" then cmd = "colonist" end

	local count = 0
	if SWGRP.JobSpawns and SWGRP.JobSpawns.Preview and SWGRP.JobSpawns.Preview[cmd] then
		count = #SWGRP.JobSpawns.Preview[cmd]
	end

	draw.SimpleText(
		"Job spawn: " .. cmd .. " (" .. count .. " on map)",
		"DermaDefault",
		ScrW() * 0.5,
		ScrH() * 0.78,
		Color( 120, 220, 255 ),
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER
	)
end

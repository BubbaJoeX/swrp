if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Structure Keys"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: Lock/Unlock door, vehicle, or owned control. Right click: Knock. (Press F2 to manage doors)"
SWEP.Category = "SWGRP"
SWEP.Spawnable = true
SWEP.AdminOnly = false

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
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = "models/swcw_items/sw_datapad.mdl"
SWEP.UseHands = true
SWEP.HoldType = "normal"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	self:SetNextPrimaryFire( CurTime() + 0.5 )

	local tr = self.Owner:GetEyeTrace()
	local ent = tr.Entity
	if not IsValid( ent ) then return end
	if tr.HitPos:DistToSqr( self.Owner:GetShootPos() ) > 150 * 150 then return end

	if ent:isDoor() then
		SWGRP.Doors.ToggleLock( self.Owner, ent )
		return
	end

	local veh = SWGRP.VehiclesMgr and SWGRP.VehiclesMgr.Resolve and SWGRP.VehiclesMgr.Resolve( ent )
	if veh and SWGRP.IsManagedVehicle( veh ) then
		SWGRP.VehiclesMgr.ToggleLock( self.Owner, veh )
		return
	end

	if SWGRP.Doors.IsControl( ent ) and SWGRP.Doors.IsButtonOwned( ent ) then
		SWGRP.Doors.ToggleControlLock( self.Owner, ent )
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	self:SetNextSecondaryFire( CurTime() + 1 )

	local tr = self.Owner:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:isDoor() then return end
	if tr.HitPos:DistToSqr( self.Owner:GetShootPos() ) > 150 * 150 then return end

	if SWGRP.Doors.Knock then
		SWGRP.Doors.Knock( self.Owner, tr.Entity )
	end
end

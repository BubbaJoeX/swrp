if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Battering Ram"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: Force door open (warrant required)."
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

SWEP.Weight = 5
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true
SWEP.HoldType = "melee2"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	if not self.Owner:SWGRP_IsGovernment() then return end

	self:SetNextPrimaryFire( CurTime() + 2 )
	self:EmitSound( "physics/wood/wood_crate_break" .. math.random( 1, 5 ) .. ".wav" )

	local tr = self.Owner:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:isDoor() then return end

	local d = SWGRP.Doors.GetMasterData( tr.Entity )
	if d and d.owner and not SWGRP.Police.HasWarrant( d.owner ) then
		self.Owner:ChatPrint( "Warrant required to breach this structure." )
		return
	end

	SWGRP.Doors.SetLockState( tr.Entity, false )
end

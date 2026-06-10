if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Grappler"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left: attach & reel. Right: detach. Reels players and entities."
SWEP.Category = "SWGRP"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 2
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true
SWEP.HoldType = "pistol"

SWEP.MaxRange = 1200
SWEP.ReelForce = 450
SWEP.RopeLength = 32

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

function SWEP:Deploy()
	if SERVER then
		self:Detach()
	end
	return true
end

function SWEP:Holster()
	if SERVER then
		self:Detach()
	end
	return true
end

function SWEP:OnRemove()
	if SERVER then
		self:Detach()
	end
end

function SWEP:GetGrappleTrace()
	local owner = self:GetOwner()
	if not IsValid( owner ) then return nil end

	return util.TraceLine( {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + owner:GetAimVector() * self.MaxRange,
		filter = owner,
		mask = MASK_SOLID,
	} )
end

function SWEP:Detach()
	if IsValid( self.GrappleRope ) then
		self.GrappleRope:Remove()
	end
	if IsValid( self.GrappleTarget ) and self.GrappleTarget:IsPlayer() then
		self.GrappleTarget:SetMoveType( MOVETYPE_WALK )
	end
	self.GrappleRope = nil
	self.GrappleTarget = nil
	self.GrappleWorldPos = nil
end

function SWEP:Attach()
	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	self:Detach()

	local tr = self:GetGrappleTrace()
	if not tr or not tr.Hit then return end

	local target = tr.Entity
	local attachPos = tr.HitPos

	local phys = IsValid( target ) and target:GetPhysicsObject()
	if IsValid( target ) and target ~= game.GetWorld() and ( target:IsPlayer() or IsValid( phys ) ) then
		self.GrappleTarget = target
		self.GrappleWorldPos = nil
	else
		self.GrappleTarget = nil
		self.GrappleWorldPos = attachPos
	end

	local rope = constraint.Rope(
		owner,
		IsValid( target ) and target or game.GetWorld(),
		0, 0,
		owner:WorldSpaceCenter(),
		IsValid( target ) and target:WorldSpaceCenter() or attachPos,
		self.RopeLength,
		0,
		8000,
		1,
		"cable/rope",
		false
	)

	self.GrappleRope = rope
	owner:EmitSound( "weapons/crossbow/hit1.wav", 60 )
end

function SWEP:Reel()
	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if IsValid( self.GrappleTarget ) then
		local target = self.GrappleTarget
		local dir = ( owner:GetPos() - target:GetPos() )
		dir.z = dir.z * 0.5
		dir:Normalize()

		if target:IsPlayer() then
			target:SetVelocity( dir * self.ReelForce )
		else
			local phys = target:GetPhysicsObject()
			if IsValid( phys ) then
				phys:ApplyForceCenter( dir * self.ReelForce * phys:GetMass() )
			end
		end
	elseif self.GrappleWorldPos then
		local dir = ( owner:GetPos() - self.GrappleWorldPos )
		dir:Normalize()
		owner:SetVelocity( dir * self.ReelForce * 0.5 )
	end

	if IsValid( self.GrappleRope ) then
		local len = math.max( 16, self.GrappleRope:GetKeyValues().length or self.RopeLength - 8 )
		-- Shorten rope gradually via constraint replacement is expensive; apply pull instead.
	end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not IsValid( owner ) then return end

	if not IsValid( self.GrappleRope ) then
		self:Attach()
	else
		self:Reel()
	end

	self:SetNextPrimaryFire( CurTime() + 0.1 )
end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	self:Detach()
	self:EmitSound( "weapons/smg1/switch.wav", 55 )

	self:SetNextSecondaryFire( CurTime() + 0.3 )
end

if CLIENT then
	function SWEP:DrawHUD()
		if IsValid( self.GrappleRope ) or self.GrappleWorldPos then
			draw.SimpleText( "REELING - Right click to detach", "DermaDefault", ScrW() * 0.5, ScrH() * 0.78, Color( 255, 180, 50 ), TEXT_ALIGN_CENTER )
		else
			draw.SimpleText( "Left click to grapple", "DermaDefault", ScrW() * 0.5, ScrH() * 0.78, Color( 200, 200, 200 ), TEXT_ALIGN_CENTER )
		end
	end
end

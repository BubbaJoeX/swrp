AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Repulsor Hovercrate"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/kingpommes/emperors_tower/imp_crates/imp_crate_single_base_static.mdl"
ENT.FollowDistance = 58
ENT.HoverHeight = 38
ENT.BobAmount = 5
ENT.BobSpeed = 2.4
ENT.FollowLerp = 8
ENT.LockMargin = 8
ENT.LockMarginTop = 28
ENT.LockScanRadius = 80

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "RepulsorActive" )
end

local function IsOwner( ent, ply )
	if not IsValid( ply ) then return false end
	if ent.SWGRP_Owner == ply then return true end
	if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, ent ) then return true end
	return false
end

local function CanLockClass( ent )
	if not IsValid( ent ) then return false end
	if ent:IsPlayer() or ent:IsNPC() or ent:IsWeapon() then return false end
	if ent:GetClass() == "swgrp_hovercrate" then return false end
	if ent:GetClass() == "swgrp_dropped_credits" then return false end
	if IsValid( ent:GetParent() ) and ent:GetParent():GetClass() == "swgrp_hovercrate" then return false end
	return true
end

if SERVER then
	util.PrecacheModel( ENT.DefaultModel )

	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		if not IsValid( self:GetPhysicsObject() ) then
			self:PhysicsInitBox( self:OBBMins(), self:OBBMaxs() )
		end

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetRepulsorActive( false )

		self.SWGRP_Locked = self.SWGRP_Locked or {}

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:EntityOverlaps( ent )
		if not IsValid( ent ) then return false end

		local localPos = self:WorldToLocal( ent:GetPos() )
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local m = self.LockMargin
		local mTop = self.LockMarginTop

		return localPos.x >= mins.x - m
			and localPos.x <= maxs.x + m
			and localPos.y >= mins.y - m
			and localPos.y <= maxs.y + m
			and localPos.z >= mins.z - m
			and localPos.z <= maxs.z + mTop
	end

	function ENT:CanLockEntity( ent, ply )
		if not CanLockClass( ent ) then return false end
		if ent.SWGRP_LockedToHovercrate then return false end
		if not IsValid( ply ) or not IsOwner( self, ply ) then return false end
		if ent:GetParent() == self then return false end
		return self:EntityOverlaps( ent )
	end

	function ENT:SyncEntityPhysics( ent, pos, ang, wake )
		if not IsValid( ent ) then return end

		pos = pos or ent:GetPos()
		ang = ang or ent:GetAngles()

		ent:SetPos( pos )
		ent:SetAngles( ang )

		local phys = ent:GetPhysicsObject()
		if not IsValid( phys ) then return end

		phys:SetPos( pos )
		phys:SetAngles( ang )
		phys:SetVelocity( Vector( 0, 0, 0 ) )
		phys:SetAngleVelocity( Vector( 0, 0, 0 ) )

		if wake then
			phys:EnableMotion( true )
			phys:Wake()
		else
			phys:EnableMotion( false )
		end
	end

	function ENT:LockEntity( ent, ply )
		if not CanLockClass( ent ) then return false end
		if ent.SWGRP_LockedToHovercrate then return false end
		if ply and not self:CanLockEntity( ent, ply ) then return false end
		if not self:EntityOverlaps( ent ) then return false end

		ent.SWGRP_PreLockMoveType = ent:GetMoveType()
		ent.SWGRP_PreLockSolid = ent:GetSolid()

		local localPos = self:WorldToLocal( ent:GetPos() )
		local localAng = self:WorldToLocalAngles( ent:GetAngles() )

		ent:SetParent( self, 0 )
		ent:SetLocalPos( localPos )
		ent:SetLocalAngles( localAng )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:SetSolid( SOLID_VPHYSICS )
		ent.SWGRP_LockedToHovercrate = self

		self:SyncEntityPhysics( ent, ent:GetPos(), ent:GetAngles(), false )

		self.SWGRP_Locked[ent] = true
		return true
	end

	function ENT:SyncLockedChildrenPhysics( wake )
		for ent in pairs( self.SWGRP_Locked or {} ) do
			if not IsValid( ent ) then continue end
			if ent:GetParent() ~= self then continue end
			self:SyncEntityPhysics( ent, ent:GetPos(), ent:GetAngles(), wake )
		end
	end

	function ENT:TryLockNearby( ply )
		ply = ply or self.SWGRP_Owner
		if not IsValid( ply ) or not IsOwner( self, ply ) then return false end

		local locked = false
		for _, ent in ipairs( ents.FindInSphere( self:GetPos(), self.LockScanRadius ) ) do
			if ent == self then continue end
			if self:CanLockEntity( ent, ply ) and self:LockEntity( ent, ply ) then
				locked = true
			end
		end

		return locked
	end

	function ENT:ReleaseLockedEntity( ent, wake )
		if not IsValid( ent ) then return end

		local pos, ang = ent:GetPos(), ent:GetAngles()

		ent:SetParent( nil )
		ent.SWGRP_LockedToHovercrate = nil

		if ent.SWGRP_PreLockMoveType then
			ent:SetMoveType( ent.SWGRP_PreLockMoveType )
			ent.SWGRP_PreLockMoveType = nil
		else
			ent:SetMoveType( MOVETYPE_VPHYSICS )
		end

		if ent.SWGRP_PreLockSolid then
			ent:SetSolid( ent.SWGRP_PreLockSolid )
			ent.SWGRP_PreLockSolid = nil
		end

		self:SyncEntityPhysics( ent, pos, ang, wake or true )

		self.SWGRP_Locked[ent] = nil
	end

	function ENT:ReleaseAllLocked()
		for ent in pairs( self.SWGRP_Locked or {} ) do
			self:ReleaseLockedEntity( ent )
		end
		self.SWGRP_Locked = {}
	end

	function ENT:GetFollowTargetPos()
		local ply = self.SWGRP_FollowPlayer
		if not IsValid( ply ) then return self:GetPos() end

		local bob = math.sin( CurTime() * self.BobSpeed ) * self.BobAmount
		local flatFwd = Vector( ply:GetForward().x, ply:GetForward().y, 0 )

		if flatFwd:LengthSqr() < 0.01 then
			flatFwd = Angle( 0, ply:EyeAngles().y, 0 ):Forward()
			flatFwd.z = 0
		end
		if flatFwd:LengthSqr() > 0.01 then
			flatFwd:Normalize()
		else
			flatFwd = Vector( 1, 0, 0 )
		end

		local target = ply:GetPos() + flatFwd * self.FollowDistance
		target.z = ply:GetPos().z + self.HoverHeight + bob

		return target, math.deg( math.atan2( flatFwd.y, flatFwd.x ) )
	end

	function ENT:SyncPhysicsTransform( pos, ang )
		self:SyncEntityPhysics( self, pos, ang, false )
	end

	function ENT:ActivateRepulsor( ply )
		if not IsValid( ply ) then return false end
		if not IsOwner( self, ply ) then
			SWGRP.Notify( ply, "You don't own this repulsor crate." )
			return false
		end

		self:SyncPhysicsTransform()

		self.SWGRP_FollowPlayer = ply
		self:SetRepulsorActive( true )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:EnableMotion( false )
		end

		SWGRP.Notify( ply, "Repulsor crate active. Press E on the crate to deactivate." )
		return true
	end

	function ENT:DeactivateRepulsor( ply )
		local pos, ang = self:GetPos(), self:GetAngles()

		self:SetRepulsorActive( false )
		self.SWGRP_FollowPlayer = nil
		self:SetCollisionGroup( COLLISION_GROUP_NONE )
		self:SetMoveType( MOVETYPE_VPHYSICS )

		self:SyncPhysicsTransform( pos, ang )
		self:SyncLockedChildrenPhysics( false )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:EnableMotion( true )
			phys:Wake()
		end

		if IsValid( ply ) then
			SWGRP.Notify( ply, "Repulsor crate deactivated." )
		end
	end

	function ENT:Think()
		if not self:GetRepulsorActive() then
			self:NextThink( CurTime() + 0.5 )
			return true
		end

		local ply = self.SWGRP_FollowPlayer
		if not IsValid( ply ) or not ply:Alive() then
			self:DeactivateRepulsor()
			self:NextThink( CurTime() + 0.5 )
			return true
		end

		local target, yaw = self:GetFollowTargetPos()
		local alpha = math.Clamp( FrameTime() * self.FollowLerp, 0, 1 )
		local newPos = LerpVector( alpha, self:GetPos(), target )
		local newAng = LerpAngle( alpha, self:GetAngles(), Angle( 0, yaw, 0 ) )

		self:SetPos( newPos )
		self:SetAngles( newAng )
		self:SyncLockedChildrenPhysics( false )

		self:NextThink( CurTime() )
		return true
	end

	function ENT:StartTouch( ent )
		if not CanLockClass( ent ) or ent.SWGRP_LockedToHovercrate then return end
		if not IsValid( self.SWGRP_Owner ) then return end
		if not self:EntityOverlaps( ent ) then return end
		if not self:CanLockEntity( ent, self.SWGRP_Owner ) then return end

		self:LockEntity( ent, self.SWGRP_Owner )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.45

		if not IsOwner( self, activator ) then
			SWGRP.Notify( activator, "You don't own this repulsor crate." )
			return
		end

		if self:GetRepulsorActive() then
			self:DeactivateRepulsor( activator )
		else
			self:ActivateRepulsor( activator )
		end
	end

	function ENT:OnRemove()
		self:DeactivateRepulsor()
		self:ReleaseAllLocked()
	end

	local function TryHovercrateLock( ply, ent )
		if not IsValid( ply ) or not IsValid( ent ) then return end

		for _, crate in ipairs( ents.FindInSphere( ent:GetPos(), 80 ) ) do
			if crate:GetClass() ~= "swgrp_hovercrate" then continue end
			if not crate:CanLockEntity( ent, ply ) then continue end
			if crate:LockEntity( ent, ply ) then
				SWGRP.Notify( ply, "Item locked to repulsor crate." )
			end
			break
		end
	end

	hook.Add( "GravGunOnDropped", "SWGRP_HovercrateLock", function( ply, ent )
		timer.Simple( 0, function()
			if not IsValid( ent ) then return end
			TryHovercrateLock( ply, ent )
		end )
	end )

	hook.Add( "OnPhysgunDrop", "SWGRP_HovercrateLock", function( ply, ent )
		timer.Simple( 0, function()
			if not IsValid( ent ) then return end
			TryHovercrateLock( ply, ent )
		end )
	end )

	hook.Add( "GravGunPickup", "SWGRP_HovercrateLocked", function( ply, ent )
		if IsValid( ent ) and ent.SWGRP_LockedToHovercrate then return false end
		if IsValid( ent ) and ent:GetClass() == "swgrp_hovercrate" and ent:GetRepulsorActive() then return false end
	end )

	hook.Add( "PhysgunPickup", "SWGRP_HovercrateLocked", function( ply, ent )
		if IsValid( ent ) and ent.SWGRP_LockedToHovercrate then return false end
		if IsValid( ent ) and ent:GetClass() == "swgrp_hovercrate" and ent:GetRepulsorActive() then return false end
	end )
end

if CLIENT then
	util.PrecacheModel( ENT.DefaultModel )

	function ENT:Draw()
		self:DrawModel()

		local ply = LocalPlayer()
		if not IsValid( ply ) or ply:GetPos():Distance( self:GetPos() ) > 700 then return end

		local active = self.GetRepulsorActive and self:GetRepulsorActive()
		local subtitle = active and "Press E to deactivate" or "Press E — Initiate Repulsor Crate"
		local accent = active and Color( 120, 220, 255 ) or Color( 255, 180, 50 )

		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "REPULSOR CRATE", subtitle, accent )
		end
	end
end

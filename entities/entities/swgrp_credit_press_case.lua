AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Credit Press Case"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/starwars/syphadias/props/sw_tor/bioware_ea/props/city/city_market_stand_01.mdl"
ENT.LabelClearance = 16

ENT.MountOffsets = {
	{ pos = Vector( 7.2002, -20.9653, 39.3027 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.6309, -7.1509, 39.3027 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.5327, 7.1479, 39.3027 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.6367, 20.813, 39.3027 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.3345, -20.9629, 61.1133 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.4722, -7.1562, 61.1133 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.5186, 6.8877, 61.1133 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 7.7578, 20.9282, 61.1133 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 13.6118, -20.269, 0.9434 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 13.7471, 0.063, 0.9434 ), ang = Angle( 0, 0, 0 ) },
	{ pos = Vector( 12.54, 22.3271, 0.9434 ), ang = Angle( 0, 0, 0 ) },
}

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "MountedCount" )
end

function ENT:GetMaxMounts()
	return #( self.MountOffsets or {} )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetMountedCount( 0 )
		self.SWGRP_MountedPresses = {}

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:GetMountTransform( slot )
		slot = slot or 1
		local offset = self.MountOffsets[slot] or self.MountOffsets[1]
		if not offset then return self:GetPos(), self:GetAngles() end

		local pos = self:LocalToWorld( offset.pos )
		local ang = self:LocalToWorldAngles( offset.ang )
		return pos, ang
	end

	function ENT:FindEmptySlot()
		for i = 1, self:GetMaxMounts() do
			if not IsValid( self.SWGRP_MountedPresses[i] ) then
				return i
			end
		end
	end

	function ENT:GetMountedPress( slot )
		return self.SWGRP_MountedPresses[slot]
	end

	function ENT:CountMounted()
		local n = 0
		for i = 1, self:GetMaxMounts() do
			if IsValid( self.SWGRP_MountedPresses[i] ) then
				n = n + 1
			end
		end
		return n
	end

	function ENT:SyncMountedCount()
		self:SetMountedCount( self:CountMounted() )
	end

	function ENT:IsPressMountable( press, owner )
		if not IsValid( press ) or press:GetClass() ~= "swgrp_credit_harvester" then
			return false
		end

		if IsValid( press:GetParent() ) and press:GetParent() ~= self then
			return false
		end

		if IsValid( press.SWGRP_MountCase ) and press.SWGRP_MountCase ~= self then
			return false
		end

		for i = 1, self:GetMaxMounts() do
			if self.SWGRP_MountedPresses[i] == press then
				return false
			end
		end

		if SWGRP.Ownership and not SWGRP.Ownership.IsOwner( owner, press ) then
			return false
		end

		return true
	end

	function ENT:MountPress( press, slot )
		if not IsValid( press ) or press:GetClass() ~= "swgrp_credit_harvester" then
			return false
		end

		slot = slot or self:FindEmptySlot()
		if not slot then return false end

		local pos, ang = self:GetMountTransform( slot )
		press:SetPos( pos )
		press:SetAngles( ang )
		press:SetParent( self )

		local phys = press:GetPhysicsObject()
		if IsValid( phys ) then phys:EnableMotion( false ) end

		press.SWGRP_MountCase = self
		press.SWGRP_MountSlot = slot
		self.SWGRP_MountedPresses[slot] = press
		self:SyncMountedCount()
		return true
	end

	function ENT:UnmountPress( slot )
		local press = self.SWGRP_MountedPresses[slot]
		if not IsValid( press ) then return false end

		press:SetParent( nil )
		local phys = press:GetPhysicsObject()
		if IsValid( phys ) then phys:EnableMotion( true ) end

		press.SWGRP_MountCase = nil
		press.SWGRP_MountSlot = nil
		self.SWGRP_MountedPresses[slot] = nil
		self:SyncMountedCount()
		return true
	end

	function ENT:UnmountAll()
		local removed = 0
		for i = 1, self:GetMaxMounts() do
			if self:UnmountPress( i ) then
				removed = removed + 1
			end
		end
		return removed
	end

	function ENT:CollectAllMounted( activator )
		local total = 0
		local presses = 0

		for i = 1, self:GetMaxMounts() do
			local press = self.SWGRP_MountedPresses[i]
			if not IsValid( press ) then continue end

			local stored = press:GetStoredCredits()
			if stored <= 0 then continue end

			activator:SWGRP_AddCredits( stored )
			press:SetStoredCredits( 0 )
			total = total + stored
			presses = presses + 1
		end

		return total, presses
	end

	function ENT:FindNearestPress( owner )
		local nearest, bestDist

		for _, ent in ipairs( ents.FindInSphere( self:GetPos(), 120 ) ) do
			if not self:IsPressMountable( ent, owner ) then continue end

			local dist = ent:GetPos():DistToSqr( self:GetPos() )
			if not bestDist or dist < bestDist then
				bestDist = dist
				nearest = ent
			end
		end

		return nearest
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if not SWGRP.Ownership or not SWGRP.Ownership.IsOwner( activator, self ) then
			SWGRP.Notify( activator, "You don't own this case." )
			return
		end

		if activator:KeyDown( IN_DUCK ) then
			local removed = self:UnmountAll()
			if removed > 0 then
				SWGRP.Notify( activator, "Unmounted " .. removed .. " credit press(es) from case." )
			else
				SWGRP.Notify( activator, "No presses mounted on this case." )
			end
			return
		end

		local total, presses = self:CollectAllMounted( activator )
		if total > 0 then
			SWGRP.Notify( activator, string.format(
				"Collected %s from %d mounted press(es).",
				SWGRP.FormatCredits( total ),
				presses
			) )
			return
		end

		local slot = self:FindEmptySlot()
		if not slot then
			SWGRP.Notify( activator, "All mount slots are full. Hold Ctrl and press E to unmount." )
			return
		end

		local nearest = self:FindNearestPress( activator )
		if not IsValid( nearest ) then
			SWGRP.Notify( activator, "Place a credit press nearby, then press E to mount it." )
			return
		end

		if self:MountPress( nearest, slot ) then
			SWGRP.Notify( activator, string.format(
				"Credit press mounted in slot %d (%d/%d).",
				slot,
				self:CountMounted(),
				self:GetMaxMounts()
			) )
		end
	end

	function ENT:OnRemove()
		for i = 1, self:GetMaxMounts() do
			local press = self.SWGRP_MountedPresses[i]
			if IsValid( press ) then
				press:SetParent( nil )
				press.SWGRP_MountCase = nil
				press.SWGRP_MountSlot = nil
			end
		end
	end
end

if CLIENT then
	function ENT:GetLabelPos()
		local mins, maxs = self:OBBMins(), self:OBBMaxs()
		local centerX = ( mins.x + maxs.x ) * 0.5
		local centerY = ( mins.y + maxs.y ) * 0.5

		local topRowZ = 0
		for _, mount in ipairs( self.MountOffsets or {} ) do
			if mount.pos.z > topRowZ then
				topRowZ = mount.pos.z
			end
		end

		return self:LocalToWorld( Vector( centerX, centerY, topRowZ + self.LabelClearance ) )
	end

	function ENT:Draw()
		self:DrawModel()

		local mounted = self.GetMountedCount and self:GetMountedCount() or self:GetNW2Int( "MountedCount", 0 )
		local maxSlots = self:GetMaxMounts()
		local status

		if mounted > 0 then
			status = mounted .. "/" .. maxSlots .. " mounted — E collect all · Ctrl+E unmount"
		else
			status = "E mount press (" .. maxSlots .. " slots)"
		end

		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "CREDIT PRESS CASE", status, SWGRP.UI.Colors.accent, self:GetLabelPos() )
		end
	end
end

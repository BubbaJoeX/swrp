--[[---------------------------------------------------------------------------
    Mount Offset Tool - parent-relative placement for ENT.MountOffsets
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MountOffset = SWGRP.MountOffset or {}

local MO = SWGRP.MountOffset

-- Parent frozen with Angle(0,0,0) so GetForward() == world +X (map north).
MO.NORTH_ANGLES = Angle( 0, 0, 0 )

local function AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

local function GetSession( ply )
	if not IsValid( ply ) then return nil end
	ply.SWGRP_MountOffset = ply.SWGRP_MountOffset or { offsets = {} }
	ply.SWGRP_MountOffset.offsets = ply.SWGRP_MountOffset.offsets or {}
	return ply.SWGRP_MountOffset
end

local function PlayerTrace( ply, dist )
	dist = dist or 2048
	return util.TraceLine( {
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * dist,
		filter = ply,
	} )
end

local function SerializeVec( v )
	return {
		x = math.Round( v.x, 4 ),
		y = math.Round( v.y, 4 ),
		z = math.Round( v.z, 4 ),
	}
end

local function SerializeAng( a )
	return {
		p = math.Round( a.p, 4 ),
		y = math.Round( a.y, 4 ),
		r = math.Round( a.r, 4 ),
	}
end

function MO.SyncTo( ply )
	if not AdminAllowed( ply ) then return end

	local session = GetSession( ply )
	local main = session.main

	net.Start( "SWGRP_MountOffsetSync" )
		net.WriteUInt( IsValid( main ) and main:EntIndex() or 0, 16 )
		net.WriteString( IsValid( main ) and main:GetClass() or "" )
		net.WriteBool( session.parentFrozen or false )
		net.WriteUInt( #session.offsets, 8 )
		for _, entry in ipairs( session.offsets ) do
			net.WriteFloat( entry.pos.x )
			net.WriteFloat( entry.pos.y )
			net.WriteFloat( entry.pos.z )
			net.WriteFloat( entry.ang.p )
			net.WriteFloat( entry.ang.y )
			net.WriteFloat( entry.ang.r )
		end
	net.Send( ply )
end

function MO.SetMain( ply, ent )
	if not AdminAllowed( ply ) or not IsValid( ent ) then return false end

	local session = GetSession( ply )
	session.main = ent
	session.parentFrozen = false
	SWGRP.Notify( ply, "Parent set: " .. ent:GetClass() .. " #" .. ent:EntIndex() )
	MO.SyncTo( ply )
	return true
end

function MO.FreezeParentNorth( ply )
	if not AdminAllowed( ply ) then return false end

	local session = GetSession( ply )
	local main = session.main
	if not IsValid( main ) then
		SWGRP.Notify( ply, "Set parent first (RMB on the case prop)." )
		return false
	end

	main:SetAngles( MO.NORTH_ANGLES )

	local phys = main:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
		phys:Wake()
	end

	session.parentFrozen = true
	SWGRP.Notify( ply, "Parent frozen at true north (+X). Forward: " .. tostring( main:GetForward() ) )
	MO.SyncTo( ply )
	return true
end

function MO.CaptureFromTrace( ply )
	if not AdminAllowed( ply ) then return false end

	local session = GetSession( ply )
	local main = session.main
	if not IsValid( main ) then
		SWGRP.Notify( ply, "Set parent first (RMB), then Reload to freeze it north." )
		return false
	end

	local tr = PlayerTrace( ply )
	if not tr.Hit then
		SWGRP.Notify( ply, "Click a prop or world surface to capture a point." )
		return false
	end

	local worldPos = tr.HitPos
	local localPos = main:WorldToLocal( worldPos )

	local localAng
	local ent = tr.Entity
	if IsValid( ent ) and ent ~= main and not ent:IsPlayer() then
		localAng = main:WorldToLocalAngles( ent:GetAngles() )
	else
		localAng = Angle( 0, 0, 0 )
	end

	local entry = {
		pos = SerializeVec( localPos ),
		ang = SerializeAng( localAng ),
	}

	table.insert( session.offsets, entry )

	local src = IsValid( ent ) and ent ~= main and not ent:IsPlayer() and ent:GetClass() or "world"
	SWGRP.Notify( ply, string.format(
		"Slot %d from %s — local pos (%.2f, %.2f, %.2f) ang (%.2f, %.2f, %.2f)",
		#session.offsets, src,
		entry.pos.x, entry.pos.y, entry.pos.z,
		entry.ang.p, entry.ang.y, entry.ang.r
	) )

	MO.SyncTo( ply )
	return true
end

function MO.ClearOffsets( ply )
	if not AdminAllowed( ply ) then return end
	local session = GetSession( ply )
	session.offsets = {}
	SWGRP.Notify( ply, "Mount offsets cleared." )
	MO.SyncTo( ply )
end

function MO.RemoveLast( ply )
	if not AdminAllowed( ply ) then return end
	local session = GetSession( ply )
	if #session.offsets == 0 then return end
	table.remove( session.offsets )
	SWGRP.Notify( ply, "Removed last mount offset." )
	MO.SyncTo( ply )
end

function MO.AdminToolPrimary( ply )
	MO.CaptureFromTrace( ply )
end

function MO.AdminToolSecondary( ply )
	local tr = PlayerTrace( ply )
	if IsValid( tr.Entity ) then
		MO.SetMain( ply, tr.Entity )
	end
end

function MO.AdminToolReload( ply )
	MO.FreezeParentNorth( ply )
end

net.Receive( "SWGRP_MountOffsetAction", function( _, ply )
	if not AdminAllowed( ply ) then return end

	local action = net.ReadString()
	if action == "clear" then
		MO.ClearOffsets( ply )
	elseif action == "remove" then
		MO.RemoveLast( ply )
	elseif action == "freezenorth" then
		MO.FreezeParentNorth( ply )
	elseif action == "capture" then
		MO.CaptureFromTrace( ply )
	elseif action == "setmain" then
		local tr = PlayerTrace( ply )
		if IsValid( tr.Entity ) then MO.SetMain( ply, tr.Entity ) end
	end
end )

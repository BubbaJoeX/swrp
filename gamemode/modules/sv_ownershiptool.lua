--[[---------------------------------------------------------------------------
    Admin Ownership Changer
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.OwnershipTool = SWGRP.OwnershipTool or {}

local OT = SWGRP.OwnershipTool

function OT.AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

function OT.OpenMenu( ply, ent )
	if not OT.AdminAllowed( ply ) or not IsValid( ent ) then return end

	local owner = SWGRP.Ownership and SWGRP.Ownership.GetOwner( ent )
	local ownerName = IsValid( owner ) and owner:Nick() or "None"

	local players = {}
	for _, p in ipairs( player.GetAll() ) do
		table.insert( players, { sid = p:SteamID(), name = p:Nick() } )
	end

	net.Start( "SWGRP_OwnershipMenu" )
		net.WriteUInt( ent:EntIndex(), 16 )
		net.WriteString( ent:GetClass() )
		net.WriteString( ownerName )
		net.WriteUInt( #players, 8 )
		for _, row in ipairs( players ) do
			net.WriteString( row.sid )
			net.WriteString( row.name )
		end
	net.Send( ply )
end

function OT.SetOwner( ply, entIndex, steamId )
	if not OT.AdminAllowed( ply ) then return end

	local ent = Entity( entIndex )
	if not IsValid( ent ) then
		SWGRP.Notify( ply, "Entity no longer exists." )
		return
	end

	local target = nil
	if steamId and steamId ~= "" then
		for _, p in ipairs( player.GetAll() ) do
			if p:SteamID() == steamId then
				target = p
				break
			end
		end
	end

	if SWGRP.Ownership then
		if IsValid( target ) then
			SWGRP.Ownership.SetOwner( ent, target )
			SWGRP.Notify( ply, "Ownership set to " .. target:Nick() )
		else
			ent.SWGRP_Owner = nil
			if ent.CPPISetOwner then ent:CPPISetOwner( NULL ) end
			SWGRP.Notify( ply, "Ownership cleared." )
		end
	end
end

function OT.AdminToolPrimary( ply )
	if not OT.AdminAllowed( ply ) then return end

	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if not IsValid( ent ) then
		SWGRP.Notify( ply, "Aim at an entity or prop." )
		return
	end

	OT.OpenMenu( ply, ent )
end

net.Receive( "SWGRP_OwnershipAction", function( _, ply )
	if not OT.AdminAllowed( ply ) then return end

	local entIndex = net.ReadUInt( 16 )
	local steamId = net.ReadString()
	OT.SetOwner( ply, entIndex, steamId )
end )

--[[---------------------------------------------------------------------------
    Entity Ownership & Sandbox Tool Protection

    Purchased / deployed SWGRP entities get SWGRP_Owner + CPPI owner. Only the
    owner (or admins) may physgun, grav gun, tool, or pocket them.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Ownership = SWGRP.Ownership or {}

local O = SWGRP.Ownership

local PUBLIC_CLASSES = {
	swgrp_dropped_credits = true,
}

local function isSwgrpEntity( ent )
	return IsValid( ent ) and string.sub( ent:GetClass(), 1, 6 ) == "swgrp_"
end

function O.SetOwner( ent, ply )
	if not IsValid( ent ) or not IsValid( ply ) then return end

	ent.SWGRP_Owner = ply
	if ent.CPPISetOwner then
		ent:CPPISetOwner( ply )
	end
end

function O.GetOwner( ent )
	if not IsValid( ent ) then return nil end

	if IsValid( ent.SWGRP_Owner ) then
		return ent.SWGRP_Owner
	end

	if isfunction( ent.CPPIGetOwner ) then
		local owner = ent:CPPIGetOwner()
		if IsValid( owner ) then
			ent.SWGRP_Owner = owner
			return owner
		end
	end

	return nil
end

function O.IsOwner( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return false end
	local owner = O.GetOwner( ent )
	return IsValid( owner ) and owner == ply
end

-- True when the player may physgun / grav gun / pocket / tool this entity.
function O.CanTouch( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return false end
	if ply:IsAdmin() then return true end

	local class = ent:GetClass()
	if PUBLIC_CLASSES[class] then return true end

	local owner = O.GetOwner( ent )
	if IsValid( owner ) then
		return owner == ply
	end

	if ent.SWGRP_PocketableVehicle or SWGRP.IsPocketableVehicleClass( ent:GetClass() ) then
		return false
	end

	-- Unowned SWGRP deployables are locked down for everyone except admins.
	if isSwgrpEntity( ent ) then
		return false
	end

	-- Sandbox props always receive an owner via PlayerSpawnedProp.
	return true
end

local function denyTouch( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) then return false end
	if O.CanTouch( ply, ent ) then return end

	local owner = O.GetOwner( ent )
	if IsValid( owner ) and owner ~= ply then
		ply.SWGRP_OwnershipWarn = ply.SWGRP_OwnershipWarn or 0
		if CurTime() - ply.SWGRP_OwnershipWarn > 1.5 then
			ply.SWGRP_OwnershipWarn = CurTime()
			SWGRP.Notify( ply, "You don't own this." )
		end
	end

	return false
end

hook.Add( "PlayerSpawnedProp", "SWGRP_PropOwner", function( ply, model, ent )
	O.SetOwner( ent, ply )
end )

hook.Add( "CanTool", "SWGRP_OwnershipTool", function( ply, tr, tool )
	if not IsValid( tr.Entity ) then return end
	return denyTouch( ply, tr.Entity )
end )

hook.Add( "PhysgunPickup", "SWGRP_OwnershipPhys", function( ply, ent )
	return denyTouch( ply, ent )
end )

hook.Add( "GravGunPickup", "SWGRP_OwnershipGrav", function( ply, ent )
	return denyTouch( ply, ent )
end )

hook.Add( "GravGunPunt", "SWGRP_OwnershipGravPunt", function( ply, ent )
	return denyTouch( ply, ent )
end )

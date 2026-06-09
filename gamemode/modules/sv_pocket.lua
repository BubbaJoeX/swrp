--[[---------------------------------------------------------------------------
    Pocket - store multiple weapons (DarkRP-style multi-item pocket)

    Items persist in the swgrp_players.pocket column as a JSON list. A single
    legacy class string is still loaded as a one-item pocket for compatibility.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Pocket = SWGRP.Pocket or {}

local BLOCKED = {
	swgrp_keys = true,
	weapon_physgun = true,
	weapon_physcannon = true,
	gmod_tool = true,
	gmod_camera = true,
}

function SWGRP.Pocket.Max()
	return SWGRP.Config and SWGRP.Config.MaxPocket or 8
end

-- Normalises whatever was loaded from persistence into a list of classes.
function SWGRP.Pocket.GetItems( ply )
	if not IsValid( ply ) then return {} end

	if not istable( ply.SWGRP_PocketItems ) then
		local legacy = ply.SWGRP_Pocket
		ply.SWGRP_PocketItems = {}
		if isstring( legacy ) and legacy ~= "" then
			if string.sub( legacy, 1, 1 ) == "[" then
				ply.SWGRP_PocketItems = util.JSONToTable( legacy ) or {}
			else
				ply.SWGRP_PocketItems = { legacy }
			end
		end
	end

	return ply.SWGRP_PocketItems
end

local function syncPocket( ply )
	local items = SWGRP.Pocket.GetItems( ply )
	-- Keep the legacy column populated with a JSON list.
	ply.SWGRP_Pocket = util.TableToJSON( items )
	ply:SetNWString( "SWGRP_Pocket", items[1] or "" )
	ply:SetNWInt( "SWGRP_PocketCount", #items )

	net.Start( "SWGRP_PocketSync" )
		net.WriteUInt( #items, 8 )
		for _, class in ipairs( items ) do
			net.WriteString( class )
		end
	net.Send( ply )

	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
end

SWGRP.Pocket.Sync = syncPocket

function SWGRP.Pocket.Store( ply )
	if not IsValid( ply ) or ply:SWGRP_IsRestrained() or ply:SWGRP_IsArrested() then return end

	local items = SWGRP.Pocket.GetItems( ply )
	if #items >= SWGRP.Pocket.Max() then
		SWGRP.Notify( ply, "Your pocket is full." )
		return
	end

	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) then return end

	local class = wep:GetClass()
	if BLOCKED[class] then
		SWGRP.Notify( ply, "You cannot pocket that item." )
		return
	end

	ply:StripWeapon( class )
	table.insert( items, class )
	syncPocket( ply )
	SWGRP.Notify( ply, "Stored " .. class .. " in pocket (" .. #items .. "/" .. SWGRP.Pocket.Max() .. ")." )
end

-- index optional; when nil drops the most-recently stored item.
function SWGRP.Pocket.Drop( ply, index )
	if not IsValid( ply ) then return end

	local items = SWGRP.Pocket.GetItems( ply )
	if #items == 0 then
		SWGRP.Notify( ply, "Your pocket is empty." )
		return
	end

	index = tonumber( index )
	if not index or index < 1 or index > #items then
		index = #items
	end

	local class = table.remove( items, index )
	ply:Give( class )
	ply:SelectWeapon( class )
	syncPocket( ply )
	SWGRP.Notify( ply, "Retrieved " .. class .. " from pocket." )
end

function SWGRP.Pocket.Restore( ply )
	-- Items stay stored across spawns; just resend the list to the client.
	syncPocket( ply )
end

-- Drop last item directly, or open a selection menu when several are stored.
function SWGRP.Pocket.RequestDrop( ply )
	if not IsValid( ply ) then return end
	local items = SWGRP.Pocket.GetItems( ply )

	if #items == 0 then
		SWGRP.Notify( ply, "Your pocket is empty." )
		return
	end

	if #items == 1 then
		SWGRP.Pocket.Drop( ply, 1 )
		return
	end

	net.Start( "SWGRP_PocketOpen" )
	net.Send( ply )
end

net.Receive( "SWGRP_PocketDrop", function( len, ply )
	local index = net.ReadUInt( 8 )
	SWGRP.Pocket.Drop( ply, index )
end )

-- Drop everything when arrested (contraband stays out of jail).
hook.Add( "SWGRPPlayerArrested", "SWGRP_PocketArrestDrop", function( target )
	if not IsValid( target ) then return end
	local items = SWGRP.Pocket.GetItems( target )
	if #items == 0 then return end
	target.SWGRP_PocketItems = {}
	syncPocket( target )
end )

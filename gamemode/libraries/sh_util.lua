--[[---------------------------------------------------------------------------
    SWGRP Utilities
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Util = SWGRP.Util or {}

function SWGRP.Util.PlayerInRange( speaker, range )
	local listeners = {}
	local speakPos = speaker:GetPos()

	for _, ply in ipairs( player.GetAll() ) do
		if ply:GetPos():DistToSqr( speakPos ) <= range * range then
			table.insert( listeners, ply )
		end
	end

	return listeners
end

function SWGRP.Util.GetPlayersInSphere( pos, range )
	local result = {}
	for _, ply in ipairs( player.GetAll() ) do
		if ply:GetPos():DistToSqr( pos ) <= range * range then
			table.insert( result, ply )
		end
	end
	return result
end

function SWGRP.Util.IsEmpty( pos, ignore )
	local tr = util.TraceHull( {
		start = pos,
		endpos = pos,
		mins = Vector( -16, -16, 0 ),
		maxs = Vector( 16, 16, 72 ),
		filter = ignore,
	} )
	return not tr.Hit
end

function SWGRP.Util.FindEmptyPos( pos, ignore, distance, step, area )
	if SWGRP.Util.IsEmpty( pos, ignore ) and SWGRP.Util.IsEmpty( pos + area, ignore ) then
		return pos
	end

	for dist = step, distance, step do
		for dir = -1, 1, 2 do
			local try = pos + Vector( dist * dir, 0, 0 )
			if SWGRP.Util.IsEmpty( try, ignore ) and SWGRP.Util.IsEmpty( try + area, ignore ) then
				return try
			end
			try = pos + Vector( 0, dist * dir, 0 )
			if SWGRP.Util.IsEmpty( try, ignore ) and SWGRP.Util.IsEmpty( try + area, ignore ) then
				return try
			end
		end
	end

	return pos
end

function SWGRP.Util.SplitArgs( text )
	local args = {}
	for word in string.gmatch( text, "%S+" ) do
		table.insert( args, word )
	end
	return args
end

function SWGRP.Util.GetDoorEnts( ent )
	local doors = {}
	if ent:isDoor() then
		table.insert( doors, ent )
	end
	return doors
end

function SWGRP.Util.IsDoor( ent )
	if not IsValid( ent ) then return false end
	local classes = SWGRP.Doors and SWGRP.Doors.Classes or {}
	return classes[ent:GetClass()] == true
end

local entMeta = FindMetaTable( "Entity" )
if entMeta and not entMeta.isDoor then
	function entMeta:isDoor()
		return SWGRP.Util.IsDoor( self )
	end
end

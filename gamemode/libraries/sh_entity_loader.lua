--[[---------------------------------------------------------------------------
    SWGRP entity script loader (shared)

    Registers gamemode entity scripts on both server and client so NetworkVar
    accessors (Get/Set*) exist on clientside Draw and prediction code. Server-only
    sv_entity_loader previously registered entities only on the host, which left
    clients without those methods.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.EntityLoader = SWGRP.EntityLoader or {}

local L = SWGRP.EntityLoader
local gmFolder = GM and GM.FolderName or "swgrp"

function L.LoadOne( filename )
	local class = string.StripExtension( filename )
	local path = gmFolder .. "/entities/entities/" .. filename

	ENT = {}

	local ok, err = pcall( include, path )
	if not ok then
		ErrorNoHalt( "[SWGRP] Failed to load entity '" .. class .. "': " .. tostring( err ) .. "\n" )
		ENT = nil
		return false
	end

	scripted_ents.Register( ENT, class )
	if SERVER then
		AddCSLuaFile( path )
	end
	ENT = nil
	return true
end

function L.LoadAll()
	local files = file.Find( gmFolder .. "/entities/entities/*.lua", "LUA" )
	if not files then return 0 end

	local count = 0
	for _, f in ipairs( files ) do
		if L.LoadOne( f ) then count = count + 1 end
	end

	return count
end

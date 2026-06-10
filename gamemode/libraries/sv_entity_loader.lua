--[[---------------------------------------------------------------------------
    SWGRP entity script loader

    GMod registers gamemode entity scripts once when the map loads. New entity
    .lua files added while the server is running (or after swgrp_reloadcontent)
    are invisible to ents.Create until they are included and registered again.
    This loader scans entities/entities/*.lua on startup and whenever CSV
    content is hot-reloaded so new equipment types work without a map change.
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
	AddCSLuaFile( path )
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

L.LoadAll()

--[[---------------------------------------------------------------------------
    Send gamemode content/ files (materials, etc.) to joining clients.
---------------------------------------------------------------------------]]

if not SERVER then return end

local gmFolder = GM.FolderName or "swgrp"
local contentRoot = "gamemodes/" .. gmFolder .. "/content"
local contentPrefix = contentRoot .. "/"

local function AddContentDir( dir )
	local files, folders = file.Find( dir .. "/*", "GAME" )
	if not files then return end

	for _, f in ipairs( files ) do
		local full = dir .. "/" .. f
		if string.sub( full, 1, #contentPrefix ) == contentPrefix then
			local rel = string.sub( full, #contentPrefix + 1 )
			if string.EndsWith( rel, ".vmt" ) or string.EndsWith( rel, ".png" ) or string.EndsWith( rel, ".jpg" ) then
				resource.AddFile( rel )
			end
		end
	end

	for _, sub in ipairs( folders or {} ) do
		if sub ~= "." and sub ~= ".." then
			AddContentDir( dir .. "/" .. sub )
		end
	end
end

if file.Exists( contentRoot, "GAME" ) then
	AddContentDir( contentRoot )
	print( "[SWGRP] Registered gamemode content/ for client download." )
end

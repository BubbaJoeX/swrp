--[[---------------------------------------------------------------------------
    SWGRP CSV Content Loader
    Master data files live in gamemodes/swgrp/data/*.csv
    Optional overrides: gamemodes/swgrp/gamemode/custom/data/*.csv
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Content = SWGRP.Content or {}

local C = SWGRP.Content

C.BasePath = "gamemodes/swgrp/data/"
C.CustomPath = "gamemodes/swgrp/gamemode/custom/data/"

C.Stats = {
	jobs = 0,
	entities = 0,
	shipments = 0,
	foods = 0,
	ammo = 0,
	vehicles = 0,
}

local JOB_FLAGS = {
	hobo = true,
	cook = true,
	medic = true,
	doctor = true,
	bountyhunter = true,
	hasLicense = true,
	governor = true,
	officer = true,
	stormtrooper = true,
	commander = true,
	chief = true,
	whitelist = true,
	disguise = true,
}

local ALLEGIANCE_MAP = {
	NEUTRAL = SWGRP.Allegiance and SWGRP.Allegiance.NEUTRAL or "neutral",
	IMPERIAL = SWGRP.Allegiance and SWGRP.Allegiance.IMPERIAL or "imperial",
	REBEL = SWGRP.Allegiance and SWGRP.Allegiance.REBEL or "rebel",
	UNDERWORLD = SWGRP.Allegiance and SWGRP.Allegiance.UNDERWORLD or "underworld",
	neutral = SWGRP.Allegiance and SWGRP.Allegiance.NEUTRAL or "neutral",
	imperial = SWGRP.Allegiance and SWGRP.Allegiance.IMPERIAL or "imperial",
	rebel = SWGRP.Allegiance and SWGRP.Allegiance.REBEL or "rebel",
	underworld = SWGRP.Allegiance and SWGRP.Allegiance.UNDERWORLD or "underworld",
}

function C.Trim( str )
	if str == nil then return "" end
	return string.match( str, "^%s*(.-)%s*$" ) or ""
end

function C.SplitList( str, sep )
	str = C.Trim( str )
	if str == "" or str == "*" then return {} end

	sep = sep or "|"
	local out = {}
	for part in string.gmatch( str, "[^" .. sep .. "]+" ) do
		part = C.Trim( part )
		if part ~= "" then
			table.insert( out, part )
		end
	end
	return out
end

function C.ToBool( str )
	str = string.lower( C.Trim( str ) )
	return str == "1" or str == "true" or str == "yes" or str == "y"
end

function C.ToInt( str, default )
	local n = tonumber( C.Trim( str ) )
	if n == nil then return default or 0 end
	return math.floor( n )
end

function C.ToColor( str )
	str = C.Trim( str )
	local r, g, b = string.match( str, "(%d+)[%s,]+(%d+)[%s,]+(%d+)" )
	if not r then return Color( 255, 255, 255 ) end
	return Color( tonumber( r ), tonumber( g ), tonumber( b ) )
end

-- Lowercased list of profession *commands* from an allow string, or nil for an
-- unrestricted ("" / "*") field. Unlike ResolveTeams this keeps the raw command
-- text so runtime checks don't depend on numeric team ids staying stable across
-- content reloads / Lua refreshes.
function C.AllowedCommands( str )
	str = C.Trim( str )
	if str == "" or str == "*" then return nil end

	local out = {}
	for c in string.gmatch( str, "[^,]+" ) do
		c = string.lower( C.Trim( c ) )
		if c ~= "" then table.insert( out, c ) end
	end

	if #out == 0 then return nil end
	return out
end

function C.ResolveTeams( str )
	str = C.Trim( str )
	if str == "" or str == "*" then return nil end

	local teams = {}
	for cmd in string.gmatch( str, "[^,]+" ) do
		cmd = string.lower( C.Trim( cmd ) )
		local job, id = SWGRP.GetJobByCommand( cmd )
		if id then
			table.insert( teams, id )
		else
			ErrorNoHalt( "[SWGRP] Unknown profession in allowed list: " .. cmd .. "\n" )
		end
	end

	if #teams == 0 then return nil end
	return teams
end

function C.ParseCSVLine( line )
	local result = {}
	local field = ""
	local inQuotes = false
	local i = 1

	while i <= #line do
		local c = string.sub( line, i, i )

		if c == '"' then
			if inQuotes and string.sub( line, i + 1, i + 1 ) == '"' then
				field = field .. '"'
				i = i + 2
			else
				inQuotes = not inQuotes
				i = i + 1
			end
		elseif c == "," and not inQuotes then
			table.insert( result, field )
			field = ""
			i = i + 1
		else
			field = field .. c
			i = i + 1
		end
	end

	table.insert( result, field )

	for idx, val in ipairs( result ) do
		result[idx] = C.Trim( val )
	end

	return result
end

function C.ParseCSV( raw )
	local rows = {}
	if not raw or raw == "" then return rows end

	local headers = nil

	for line in string.gmatch( raw .. "\n", "([^\n]*)\n" ) do
		line = C.Trim( line )
		if line ~= "" and string.sub( line, 1, 1 ) ~= "#" then
			local fields = C.ParseCSVLine( line )

			if not headers then
				headers = {}
				for _, h in ipairs( fields ) do
					table.insert( headers, string.lower( C.Trim( h ) ) )
				end
			else
				local row = {}
				for i, h in ipairs( headers ) do
					row[h] = fields[i] or ""
				end
				table.insert( rows, row )
			end
		end
	end

	return rows
end

function C.ReadRows( filename )
	local rows = {}
	local raw = file.Read( C.BasePath .. filename, "GAME" )
	if raw then
		rows = C.ParseCSV( raw )
	end

	local customRaw = file.Read( C.CustomPath .. filename, "GAME" )
	if customRaw then
		local customRows = C.ParseCSV( customRaw )
		for _, row in ipairs( customRows ) do
			table.insert( rows, row )
		end
	end

	return rows
end

function C.Get( row, ... )
	for i = 1, select( "#", ... ) do
		local key = select( i, ... )
		local val = row[key]
		if val and C.Trim( val ) ~= "" then
			return val
		end
	end
	return ""
end

function C.ApplyJobFlags( data, flagsStr )
	for flag in string.gmatch( string.lower( flagsStr or "" ), "[^,%s]+" ) do
		flag = C.Trim( flag )
		if JOB_FLAGS[flag] then
			data[flag] = true
		end
	end
end

function C.LoadJobs()
	local rows = C.ReadRows( "jobs.csv" )

	for _, row in ipairs( rows ) do
		local name = C.Get( row, "name" )
		local command = string.lower( C.Get( row, "command" ) )
		if name ~= "" and command ~= "" then
		local models = C.SplitList( C.Get( row, "models", "model" ), "|" )
		if #models == 0 then
			models = { "models/player/group01/male_01.mdl" }
		end

		local allegianceKey = string.upper( C.Get( row, "allegiance" ) )
		local data = {
			color = C.ToColor( C.Get( row, "color" ) ),
			model = #models == 1 and models[1] or models,
			description = C.Get( row, "description" ),
			weapons = C.SplitList( C.Get( row, "weapons" ), "|" ),
			command = command,
			max = C.ToInt( C.Get( row, "max" ), 0 ),
			salary = C.ToInt( C.Get( row, "salary" ), 45 ),
			admin = C.ToInt( C.Get( row, "admin" ), 0 ),
			vote = C.ToBool( C.Get( row, "vote" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "General",
			allegiance = ALLEGIANCE_MAP[allegianceKey] or ALLEGIANCE_MAP.NEUTRAL,
		}

		C.ApplyJobFlags( data, C.Get( row, "flags" ) )

		local teamId = SWGRP.RegisterJob( name, data )
		_G["TEAM_" .. string.upper( command )] = teamId
		C.Stats.jobs = C.Stats.jobs + 1
		end
	end

	if C.Stats.jobs == 0 then
		TEAM_COLONIST = SWGRP.RegisterJob( "Colonist", {
			color = Color( 20, 150, 20 ),
			model = { "models/player/group01/male_01.mdl" },
			description = "Default colonist profession.",
			weapons = {},
			command = "colonist",
			max = 0,
			salary = 45,
			category = "Civilians",
			allegiance = SWGRP.Allegiance.NEUTRAL,
		} )
		C.Stats.jobs = 1
	end

	TEAM_DEFAULT = TEAM_COLONIST or TEAM_DEFAULT
end

function C.LoadEntities()
	for _, row in ipairs( C.ReadRows( "entities.csv" ) ) do
		local class = C.Get( row, "class", "entity" )
		local name = C.Get( row, "name" )
		if class ~= "" and name ~= "" then
		SWGRP.RegisterEntity( class, {
			name = name,
			model = C.Get( row, "model" ),
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			max = C.ToInt( C.Get( row, "max" ), 0 ),
			cmd = C.Get( row, "cmd", "command" ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			allowedcmds = C.AllowedCommands( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Structures & Commerce",
		} )
		C.Stats.entities = C.Stats.entities + 1
		end
	end
end

function C.LoadShipments()
	for _, row in ipairs( C.ReadRows( "shipments.csv" ) ) do
		local name = C.Get( row, "name" )
		if name ~= "" then
			local entities = C.SplitList( C.Get( row, "entities", "weapons" ), "|" )
			if #entities > 0 then
		SWGRP.RegisterShipment( name, {
			model = C.Get( row, "model" ) ~= "" and C.Get( row, "model" ) or "models/Items/item_item_crate.mdl",
			previewModel = C.Get( row, "preview_model", "previewmodel" ),
			entities = entities,
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			amount = C.ToInt( C.Get( row, "amount" ), 10 ),
			separate = C.ToBool( C.Get( row, "separate", "allow_separate" ) ),
			pricesep = C.ToInt( C.Get( row, "price_separate", "pricesep" ), 0 ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			allowedcmds = C.AllowedCommands( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Shipments",
		} )
		C.Stats.shipments = C.Stats.shipments + 1
			end
		end
	end
end

function C.LoadFoods()
	for _, row in ipairs( C.ReadRows( "foods.csv" ) ) do
		local name = C.Get( row, "name" )
		if name ~= "" then
		SWGRP.RegisterFood( name, {
			model = C.Get( row, "model" ),
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			hunger = C.ToInt( C.Get( row, "hunger" ), 0 ),
			health = C.ToInt( C.Get( row, "health" ), 0 ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			allowedcmds = C.AllowedCommands( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Rations",
		} )
		C.Stats.foods = C.Stats.foods + 1
		end
	end
end

function C.LoadSpices()
	for _, row in ipairs( C.ReadRows( "spices.csv" ) ) do
		local name = C.Get( row, "name" )
		if name ~= "" then
		SWGRP.RegisterSpice( name, {
			model = C.Get( row, "model" ),
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			hunger = C.ToInt( C.Get( row, "hunger_change", "hunger" ), 0 ),
			health = C.ToInt( C.Get( row, "health_change", "health" ), 0 ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			allowedcmds = C.AllowedCommands( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Spice",
		} )
		C.Stats.spices = C.Stats.spices + 1
		end
	end
end

function C.LoadAmmo()
	for _, row in ipairs( C.ReadRows( "ammo.csv" ) ) do
		local name = C.Get( row, "name" )
		if name ~= "" then
		SWGRP.RegisterAmmoType( name, {
			ammoType = C.Get( row, "ammo_type", "ammotype" ),
			model = C.Get( row, "model" ),
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			amountGiven = C.ToInt( C.Get( row, "amount", "amountgiven" ), 0 ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			allowedcmds = C.AllowedCommands( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Ammunition",
		} )
		C.Stats.ammo = C.Stats.ammo + 1
		end
	end
end

function C.LoadVehicles()
	for _, row in ipairs( C.ReadRows( "vehicles.csv" ) ) do
		local name = C.Get( row, "name" )
		if name ~= "" then
		local pocketCol = C.Trim( C.Get( row, "pocketable" ) )
		local pocketable = pocketCol == "" or C.ToBool( pocketCol )

		SWGRP.RegisterVehicle( {
			name = name,
			model = C.Get( row, "model" ),
			class = C.Get( row, "class" ) ~= "" and C.Get( row, "class" ) or "prop_vehicle_jeep",
			script = C.Get( row, "script" ),
			price = C.ToInt( C.Get( row, "price" ), 0 ),
			allowed = C.ResolveTeams( C.Get( row, "allowed" ) ),
			category = C.Get( row, "category" ) ~= "" and C.Get( row, "category" ) or "Vehicles",
			pocketable = pocketable,
		} )
		C.Stats.vehicles = C.Stats.vehicles + 1
		end
	end
end

function C.LoadAll()
	C.Stats = { jobs = 0, entities = 0, shipments = 0, foods = 0, spices = 0, ammo = 0, vehicles = 0 }

	C.LoadJobs()
	C.LoadEntities()
	C.LoadShipments()
	C.LoadFoods()
	C.LoadSpices()
	C.LoadAmmo()
	C.LoadVehicles()

	local s = C.Stats
	MsgC( Color( 255, 180, 50 ), string.format(
		"[SWGRP] CSV content loaded: %d jobs, %d entities, %d shipments, %d foods, %d spices, %d ammo, %d vehicles\n",
		s.jobs, s.entities, s.shipments, s.foods, s.spices, s.ammo, s.vehicles
	) )

	if SWGRP.Ammo and SWGRP.Ammo.PatchWeaponTables then
		SWGRP.Ammo.PatchWeaponTables()
	end
end

-- Re-read all CSV content at runtime. Jobs are updated in place (their team ids
-- are preserved via RegisterJob), while the keyed/array catalogs are rebuilt so
-- edits to models, prices, etc. take effect without a map change.
function C.Reload()
	-- Empty in place so any cached references remain valid.
	table.Empty( SWGRP.Entities )
	table.Empty( SWGRP.Shipments )
	table.Empty( SWGRP.Foods )
	table.Empty( SWGRP.Spices )
	table.Empty( SWGRP.AmmoTypes )
	table.Empty( SWGRP.Vehicles )

	C.LoadAll()

	-- Re-register entity .lua scripts so newly added types (e.g. spice terminal)
	-- work after a CSV reload without restarting the map.
	if SERVER and SWGRP.EntityLoader and SWGRP.EntityLoader.LoadAll then
		local n = SWGRP.EntityLoader.LoadAll()
		MsgC( Color( 255, 180, 50 ), string.format( "[SWGRP] Reloaded %d entity scripts.\n", n ) )
	end

	if SERVER and SWGRP.JobSpawns and SWGRP.JobSpawns.ApplyAll then
		SWGRP.JobSpawns.ApplyAll()
	end
end

if SERVER then
	concommand.Add( "swgrp_reloadcontent", function( ply )
		if IsValid( ply ) and not ply:IsSuperAdmin() then
			SWGRP.Notify( ply, "Only superadmins can reload content." )
			return
		end

		C.Reload()

		for _, p in ipairs( player.GetAll() ) do
			if not IsValid( p ) then continue end
			if SWGRP.JobsMgr and SWGRP.JobsMgr.ApplyModel then
				SWGRP.JobsMgr.ApplyModel( p, p:Team() )
			end
		end

		net.Start( "SWGRP_ReloadContent" )
		net.Broadcast()

		local msg = "[SWGRP] Content reloaded from CSV."
		if IsValid( ply ) then ply:ChatPrint( msg ) else print( msg ) end
	end )
else
	net.Receive( "SWGRP_ReloadContent", function()
		C.Reload()

		-- Drop any cached F4 menu so it rebuilds against the new data on next open.
		if IsValid( SWGRP.F4Frame ) then
			SWGRP.F4Frame:Remove()
			SWGRP.F4Frame = nil
		end
	end )
end

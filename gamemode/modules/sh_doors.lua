--[[---------------------------------------------------------------------------
    Door System - Shared helpers
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Doors = SWGRP.Doors or {}

SWGRP.Doors.Classes = {
	["func_door"] = true,
	["func_door_rotating"] = true,
	["prop_door_rotating"] = true,
}

SWGRP.Doors.ButtonClasses = {
	["func_button"] = true,
	["func_rot_button"] = true,
	["momentary_rot_button"] = true,
	["gmod_button"] = true,
}

-- Structure flags label the area past a door (informational, owner-set).
SWGRP.Doors.Flags = {
	{ id = "",         label = "None",         color = Color( 200, 200, 200 ) },
	{ id = "kos",      label = "KOS",          color = Color( 220, 60, 60 ) },
	{ id = "building", label = "Building",     color = Color( 80, 160, 255 ) },
	{ id = "private",  label = "Private",      color = Color( 255, 180, 50 ) },
	{ id = "public",   label = "Public",       color = Color( 80, 200, 120 ) },
	{ id = "noraid",   label = "No Raiding",   color = Color( 180, 120, 220 ) },
}

function SWGRP.Doors.GetFlagInfo( id )
	id = id or ""
	for _, f in ipairs( SWGRP.Doors.Flags ) do
		if f.id == id then return f end
	end
	return SWGRP.Doors.Flags[1]
end

function SWGRP.Doors.IsValidFlag( id )
	for _, f in ipairs( SWGRP.Doors.Flags ) do
		if f.id == id then return true end
	end
	return false
end

function SWGRP.Doors.IsButton( ent )
	if not IsValid( ent ) then return false end
	return SWGRP.Doors.ButtonClasses[ent:GetClass()] == true
end

-- Map "controls" are entities that can be made ownable/lockable on a per-entity
-- basis by an admin (buttons plus prop_dynamic props used as consoles/levers).
-- prop_dynamic is opt-in only: a decorative prop is never affected unless an
-- admin explicitly grants ownership to it.
SWGRP.Doors.ControlClasses = {
	["prop_dynamic"] = true,
}

function SWGRP.Doors.IsControl( ent )
	if not IsValid( ent ) then return false end
	if SWGRP.Doors.ButtonClasses[ent:GetClass()] then return true end
	return SWGRP.Doors.ControlClasses[ent:GetClass()] == true
end

function SWGRP.Doors.GetTargetName( ent )
	if not IsValid( ent ) then return "" end
	return ent:GetName() or ""
end

function SWGRP.Doors.GetHammerTarget( ent )
	if not IsValid( ent ) then return "" end

	local kv = ent.GetKeyValues and ent:GetKeyValues() or {}
	local target = kv.target or kv.Target or ""

	if target == "" and ent.GetInternalVariable then
		target = ent:GetInternalVariable( "m_target" ) or ent:GetInternalVariable( "target" ) or ""
	end

	return target
end

--[[---------------------------------------------------------------------------
    Door access groups (allegiance, individual jobs, custom team lists)

    A door group key is either:
      * "allegiance:<id>"  - any job whose allegiance matches (e.g. imperial)
      * "job:<teamId>"     - a single profession / team
      * a custom name in SWGRP.DoorGroups / SWGRP.Config.DoorGroups (team list)
---------------------------------------------------------------------------]]

function SWGRP.Doors.GetGroupList()
	local seen, list = {}, {}

	local function add( key, label, sort, kind )
		if not key or key == "" or seen[key] then return end
		seen[key] = true
		list[#list + 1] = { key = key, label = label or key, sort = sort or 100, kind = kind or "custom" }
	end

	for id, data in pairs( SWGRP.AllegianceData or {} ) do
		add( "allegiance:" .. id, data.name, data.sortOrder or 50, "allegiance" )
	end

	for teamId, job in pairs( SWGRP.Jobs or {} ) do
		local label = job.name or ( "Team " .. teamId )
		if job.category and job.category ~= "" then
			label = job.category .. " — " .. label
		end
		add( "job:" .. teamId, label, 120, "job" )
	end

	for name in pairs( SWGRP.DoorGroups or {} ) do add( name, name, 200, "custom" ) end
	if SWGRP.Config and SWGRP.Config.DoorGroups then
		for name in pairs( SWGRP.Config.DoorGroups ) do add( name, name, 210, "custom" ) end
	end

	table.sort( list, function( a, b )
		if a.sort ~= b.sort then return a.sort < b.sort end
		return a.label < b.label
	end )

	return list
end

function SWGRP.Doors.GetGroupLabel( key )
	if not key or key == "" then return "None" end

	local alle = string.match( key, "^allegiance:(.+)$" )
	if alle then
		local d = SWGRP.AllegianceData and SWGRP.AllegianceData[alle]
		return d and d.name or alle
	end

	local teamId = tonumber( string.match( key, "^job:(%d+)$" ) )
	if teamId then
		local job = SWGRP.GetJob and SWGRP.GetJob( teamId )
		return job and job.name or ( "Job " .. teamId )
	end

	return key
end

function SWGRP.Doors.PlayerInGroup( ply, key )
	if not IsValid( ply ) or not key or key == "" then return false end

	local alle = string.match( key, "^allegiance:(.+)$" )
	if alle then
		local job = SWGRP.GetJob and SWGRP.GetJob( ply:Team() )
		if job and SWGRP.GetJobAllegiance then
			return SWGRP.GetJobAllegiance( job ) == alle
		end
		return false
	end

	local teamId = tonumber( string.match( key, "^job:(%d+)$" ) )
	if teamId then
		return ply:Team() == teamId
	end

	local teams = ( SWGRP.DoorGroups and SWGRP.DoorGroups[key] )
		or ( SWGRP.Config and SWGRP.Config.DoorGroups and SWGRP.Config.DoorGroups[key] )
	if istable( teams ) then
		for _, t in ipairs( teams ) do
			if t and ply:Team() == t then return true end
		end
	end

	return false
end

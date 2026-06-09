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

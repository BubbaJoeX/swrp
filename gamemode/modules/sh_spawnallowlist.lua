--[[---------------------------------------------------------------------------
    Q Menu Spawn Allowlist (non-admin players)
    Extend via custom/*.lua using SWGRP.SpawnAllowlist.Register()
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.SpawnAllowlist = SWGRP.SpawnAllowlist or {}

local Allow = SWGRP.SpawnAllowlist

Allow.Lists = {
	props     = {},
	weapons   = {},
	entities  = {},
	vehicles  = {},
	npcs      = {},
	effects   = {},
	ragdolls  = {},
}

function Allow.Normalize( id )
	return string.lower( string.Trim( id or "" ) )
end

function Allow.Register( category, id )
	if not Allow.Lists[category] or not id then return end
	Allow.Lists[category][Allow.Normalize( id )] = true
end

function Allow.RegisterMany( category, ids )
	if not istable( ids ) then return end
	for _, id in ipairs( ids ) do
		Allow.Register( category, id )
	end
end

function Allow.IsEnabled()
	return not SWGRP.Config or SWGRP.Config.SpawnAllowlistEnabled:GetBool()
end

function Allow.CanBypass( ply )
	if not IsValid( ply ) then return false end
	if ply:IsSuperAdmin() then return true end
	if SWGRP.FAdmin and SWGRP.FAdmin.CanSpawn( ply ) then return true end
	return ply:IsAdmin()
end

-- Q-menu weapons tab: superadmins only; regular players buy from shipments.
function Allow.CanBypassWeapons( ply )
	return IsValid( ply ) and ply:IsSuperAdmin()
end

function Allow.IsAllowed( ply, category, id )
	if not Allow.IsEnabled() then return true end
	if Allow.CanBypass( ply ) then return true end

	local list = Allow.Lists[category]
	if not list then return false end

	return list[Allow.Normalize( id )] == true
end

-- Default colonist / RP building props
Allow.RegisterMany( "props", {
	"models/props_c17/furniturechair001a.mdl",
	"models/props_c17/furniturecouch001a.mdl",
	"models/props_c17/furnituredrawer001a.mdl",
	"models/props_c17/furnituretable001a.mdl",
	"models/props_c17/furnituretable002a.mdl",
	"models/props_c17/furnituretable003a.mdl",
	"models/props_c17/furniturebed001a.mdl",
	"models/props_interior/furniture_chair01a.mdl",
	"models/props_interior/furniture_couch01a.mdl",
	"models/props_interior/furniture_desk01a.mdl",
	"models/props_c17/concrete_barrier001a.mdl",
	"models/props_c17/streetsign004e.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_junk/wood_crate002a.mdl",
	"models/props_junk/cardboard_box001a.mdl",
	"models/props_junk/cardboard_box003a.mdl",
	"models/props_junk/metalbucket01a.mdl",
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props_c17/lamp_shade001a.mdl",
	"models/props_c17/shelfunit01a.mdl",
	"models/props_lab/monitor01a.mdl",
	"models/props_lab/monitor01b.mdl",
	"models/props/cs_office/offcorkboarda.mdl",
	"models/props/cs_office/offpaintinga.mdl",
	"models/props/cs_office/offpaintingb.mdl",
	"models/props/cs_office/plant01.mdl",
	"models/props/cs_office/trash_can.mdl",
} )

-- Gamemode entities purchased via F4 should not need Q menu access; keep empty by default.

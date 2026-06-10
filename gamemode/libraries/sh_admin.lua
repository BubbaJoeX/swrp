--[[---------------------------------------------------------------------------
    SWGRP Admin Authority - unified permission gate (shared)

    Every admin-facing system (the Imperial Command Console, its console/chat
    command mirrors, and the existing door/button tools) routes its permission
    check through here so the rules stay consistent and auditable in one place.

    Authority order:
      * Superadmins always pass.
      * Admins pass.
      * If FAdmin is installed, an explicit "AdminMenu" privilege also passes.

    A small set of irreversible / server-wide actions are restricted to
    superadmins regardless of the above (ban, convar edits, content reload).
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Admin = SWGRP.Admin or {}

function SWGRP.Admin.CanUse( ply )
	if not IsValid( ply ) then
		-- The server console (nil/NULL caller) is fully trusted.
		return ply == nil
	end
	if ply:IsSuperAdmin() then return true end
	if ply:IsAdmin() then return true end

	if SWGRP.FAdmin and SWGRP.FAdmin.Available and SWGRP.FAdmin.Available() then
		if FAdmin.Access.PlayerHasPrivilege( ply, "AdminMenu" ) then return true end
	end

	return false
end

-- Actions that mutate the server irreversibly or affect everyone are locked to
-- superadmins. Everything else only needs CanUse().
SWGRP.Admin.SuperAdminActions = {
	ban           = true,
	setconvar     = true,
	reloadcontent = true,
}

function SWGRP.Admin.CanDoAction( ply, action )
	if not SWGRP.Admin.CanUse( ply ) then return false end
	if SWGRP.Admin.SuperAdminActions[action] then
		-- The server console (nil) and superadmins clear the higher bar.
		if ply ~= nil and not ply:IsSuperAdmin() then return false end
	end
	return true
end

-- Server ConVars the console is permitted to change. Anything not listed is
-- rejected so the menu can never be coerced into flipping unrelated cvars.
SWGRP.Admin.ConVarWhitelist = {
	swgrp_taxenabled      = true,
	swgrp_taxrate         = true,
	swgrp_hungerenabled   = true,
	swgrp_hungerrate      = true,
	swgrp_nlr             = true,
	swgrp_nlrtime         = true,
	swgrp_logging         = true,
	swgrp_sandbox_tools   = true,
	swgrp_spawnallowlist  = true,
	swgrp_paydayinterval  = true,
	swgrp_startcredits    = true,
	swgrp_missioncooldown = true,
	swgrp_propcount       = true,
	swgrp_maxdoors        = true,
}

-- Friendly labels + control hints for the Systems tab. type "bool" renders a
-- toggle; "number" renders a value field.
SWGRP.Admin.SystemToggles = {
	{ cvar = "swgrp_taxenabled",     label = "Imperial Taxation",      kind = "bool" },
	{ cvar = "swgrp_taxrate",        label = "Tax Rate (0-1)",         kind = "number" },
	{ cvar = "swgrp_hungerenabled",  label = "Hunger / Rations",       kind = "bool" },
	{ cvar = "swgrp_nlr",            label = "New Life Rule",          kind = "bool" },
	{ cvar = "swgrp_nlrtime",        label = "NLR Seconds",            kind = "number" },
	{ cvar = "swgrp_logging",        label = "RP Action Logging",      kind = "bool" },
	{ cvar = "swgrp_sandbox_tools",  label = "Sandbox Tools (0/1/2)",  kind = "number" },
	{ cvar = "swgrp_spawnallowlist", label = "Prop Spawn Allowlist",   kind = "bool" },
	{ cvar = "swgrp_paydayinterval", label = "Payday Interval (s)",    kind = "number" },
	{ cvar = "swgrp_startcredits",   label = "Starting Credits",       kind = "number" },
}

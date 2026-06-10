--[[---------------------------------------------------------------------------
    Law Enforcement - Wanted, Warrants, Arrest, License
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Police = SWGRP.Police or {}

SWGRP.Police.Warrants = SWGRP.Police.Warrants or {}
SWGRP.Police.JailCells = SWGRP.Police.JailCells or {}

function SWGRP.Police.CanEnforce( ply )
	return ply:SWGRP_IsGovernment()
end

function SWGRP.Police.SetWanted( target, reason, actor )
	if not IsValid( target ) then return end
	if SWGRP.Police.CanEnforce( target ) then return end

	target:SWGRP_SetWanted( reason )
	SWGRP.Hooks.Call( "SWGRPPlayerWanted", target, reason, actor )
	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.wanted_set, target:Nick(), reason ) )
	end
end

function SWGRP.Police.ClearWanted( target, actor )
	if not IsValid( target ) then return end
	target:SWGRP_UnWanted()
	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.wanted_cleared, target:Nick() ) )
	end
end

function SWGRP.Police.SetWarrant( target, reason, actor )
	if not IsValid( target ) or not IsValid( actor ) then return end
	if not SWGRP.Police.CanEnforce( actor ) then return end

	SWGRP.Police.Warrants[target:SteamID()] = {
		reason = reason,
		expire = os.time() + SWGRP.Config.WarrantTime,
		officer = IsValid( actor ) and actor:SteamID() or "",
	}
	SWGRP.Persistence.SaveWarrant(
		target:SteamID(),
		reason,
		SWGRP.Police.Warrants[target:SteamID()].expire,
		SWGRP.Police.Warrants[target:SteamID()].officer
	)
	SWGRP.Notify( nil, "Search warrant issued for " .. target:Nick() .. ": " .. reason )
end

function SWGRP.Police.HasWarrant( target )
	local w = SWGRP.Police.Warrants[target:SteamID()]
	return w and w.expire > os.time()
end

function SWGRP.Police.ClearWarrant( target )
	if not IsValid( target ) then return end
	SWGRP.Police.Warrants[target:SteamID()] = nil
	SWGRP.Persistence.DeleteWarrant( target:SteamID() )
end

function SWGRP.Police.GetJailPos()
	if SWGRP.JailPositions and #SWGRP.JailPositions > 0 then
		local cell = SWGRP.JailPositions[math.random( #SWGRP.JailPositions )]
		return cell.pos, cell.ang
	end

	local def = SWGRP.Config.DefaultJailPos
	if def and def ~= vector_origin then
		return def, SWGRP.Config.DefaultJailAng or angle_zero
	end

	-- No jail configured for this map: fall back to a spawn point so detainees
	-- don't get teleported to world origin (0,0,0).
	local spawns = ents.FindByClass( "info_player_*" )
	if #spawns > 0 then
		local s = spawns[math.random( #spawns )]
		return s:GetPos() + Vector( 0, 0, 8 ), s:GetAngles()
	end

	return def or vector_origin, SWGRP.Config.DefaultJailAng or angle_zero
end

function SWGRP.Police.Arrest( target, actor, time )
	if not IsValid( target ) or not IsValid( actor ) then return end
	if not SWGRP.Police.CanEnforce( actor ) then return end
	if target:SWGRP_IsArrested() then return end

	time = time or SWGRP.Config.ArrestTime
	target:SWGRP_SetArrested( true )
	target.SWGRP_ArrestExpire = os.time() + time
	target:SWGRP_UnWanted()
	target:StripWeapons()

	local pos, ang = SWGRP.Police.GetJailPos()
	target:SetPos( pos )
	target:SetEyeAngles( ang )

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.arrested, target:Nick() ) )
	end
	SWGRP.Hooks.Call( "SWGRPPlayerArrested", target, actor )
	SWGRP.Factions.Add( actor, "imperial", 2 )

	timer.Create( "SWGRP_Arrest_" .. target:SteamID64(), time, 1, function()
		if IsValid( target ) then SWGRP.Police.UnArrest( target ) end
	end )
end

-- Admin override: detain a player regardless of the actor's profession. Mirrors
-- Arrest() but skips the CanEnforce gate (the caller is already an admin).
function SWGRP.Police.AdminArrest( target, time )
	if not IsValid( target ) then return end
	if target:SWGRP_IsArrested() then return end

	time = time or SWGRP.Config.ArrestTime
	target:SWGRP_SetArrested( true )
	target.SWGRP_ArrestExpire = os.time() + time
	target:SWGRP_UnWanted()
	target:StripWeapons()

	local pos, ang = SWGRP.Police.GetJailPos()
	target:SetPos( pos )
	target:SetEyeAngles( ang )

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.arrested, target:Nick() ) )
	end
	SWGRP.Hooks.Call( "SWGRPPlayerArrested", target, nil )

	timer.Create( "SWGRP_Arrest_" .. target:SteamID64(), time, 1, function()
		if IsValid( target ) then SWGRP.Police.UnArrest( target ) end
	end )
end

function SWGRP.Police.UnArrest( target, actor )
	if not IsValid( target ) then return end
	if actor and not SWGRP.Police.CanEnforce( actor ) then return end

	target:SWGRP_SetArrested( false )
	target.SWGRP_ArrestExpire = nil
	timer.Remove( "SWGRP_Arrest_" .. target:SteamID64() )

	local pos = SWGRP.Config.DefaultReleasePos
	if pos ~= Vector( 0, 0, 0 ) then
		target:SetPos( pos )
	else
		target:Spawn()
	end

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.unarrested, target:Nick() ) )
	end
	SWGRP.Hooks.Call( "SWGRPPlayerUnarrested", target, actor )
end

function SWGRP.Police.GrantLicense( ply, actor )
	if not IsValid( ply ) or not IsValid( actor ) then return end
	local job = SWGRP.GetJob( actor:Team() )
	if not ( job and ( job.chief or job.governor or job.officer ) ) then return end

	ply:SWGRP_SetLicense( true )
	SWGRP.Notify( ply, SWGRP.Lang.license_granted )
end

function SWGRP.Police.RevokeLicense( ply, actor )
	if not IsValid( ply ) or not IsValid( actor ) then return end
	local job = SWGRP.GetJob( actor:Team() )
	if not ( job and ( job.chief or job.governor or job.officer ) ) then return end

	ply:SWGRP_SetLicense( false )
	SWGRP.Notify( ply, SWGRP.Lang.license_revoked )
end

timer.Create( "SWGRP_WantedExpire", 30, 0, function()
	for _, ply in ipairs( player.GetAll() ) do
		if ply:SWGRP_IsWanted() and ply.SWGRP_WantedExpire and os.time() > ply.SWGRP_WantedExpire then
			SWGRP.Police.ClearWanted( ply )
		end
	end
end )

timer.Create( "SWGRP_WarrantExpire", 60, 0, function()
	for sid, w in pairs( SWGRP.Police.Warrants ) do
		if w.expire <= os.time() then
			SWGRP.Police.Warrants[sid] = nil
			SWGRP.Persistence.DeleteWarrant( sid )
		end
	end
end )

hook.Add( "PlayerSpawn", "SWGRP_ArrestedSpawn", function( ply )
	if ply:SWGRP_IsArrested() then
		local pos = SWGRP.Police.GetJailPos()
		ply:SetPos( pos )
	end
end )

hook.Add( "PlayerCanPickupWeapon", "SWGRP_LicenseCheck", function( ply, wep )
	if not IsValid( wep ) then return end
	local class = wep:GetClass()
	if class == "weapon_physgun" or class == "gmod_tool" or class == "weapon_physcannon" then return end
	if string.StartWith( class, "swgrp_" ) then return end

	if ply.SWGRP_SkipLicensePickup == class then return true end
	if SWGRP.IsGrantedWeapon and SWGRP.IsGrantedWeapon( ply, class ) then return true end

	local job = SWGRP.GetJob( ply:Team() )
	if job and ( job.hasLicense or job.stormtrooper or job.governor ) then return end
	if ply:SWGRP_HasLicense() then return end
	if ply:SWGRP_IsGovernment() then return end

	if class ~= "weapon_fists" and class ~= "weapon_crowbar" then
		return false
	end
end )

hook.Add( "canLockpick", "SWGRP_Lockpick", function( ply, ent, trace )
	if not IsValid( ent ) or not ent:isDoor() then return false end
	local d = SWGRP.Doors.GetMasterData( ent )
	if not d then return true end
	if SWGRP.Doors.CanAccess( ply, ent ) then return false end
	if SWGRP.Police.HasWarrant( ply ) then return true end
	return true
end )

hook.Add( "onLockpickCompleted", "SWGRP_LockpickDone", function( ply, success, ent )
	if success and IsValid( ent ) and ent:isDoor() then
		SWGRP.Doors.SetLockState( ent, false )
	end
end )

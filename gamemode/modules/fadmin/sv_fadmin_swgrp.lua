--[[---------------------------------------------------------------------------
    SWGRP hooks for bundled FAdmin
---------------------------------------------------------------------------]]

function SWGRP.GiveSandboxTools( ply )
	if not IsValid( ply ) or not SWGRP.FAdmin then return end

	-- Only manage the sandbox tool classes themselves. This must never strip
	-- job weapons or swgrp_keys.
	for _, class in ipairs( SWGRP.FAdmin.SandboxWeapons ) do
		local allowed = SWGRP.FAdmin.ShouldGiveWeapon( ply, class )
		if allowed and not ply:HasWeapon( class ) then
			ply:Give( class )
		elseif not allowed and ply:HasWeapon( class ) then
			ply:StripWeapon( class )
		end
	end
end

local function RefreshLoadout( ply )
	if not IsValid( ply ) then return end
	if SWGRP.GiveJobLoadout then
		SWGRP.GiveJobLoadout( ply )
	end
end

hook.Add( "FAdmin_SetAccess", "SWGRP_FAdminRefresh", RefreshLoadout )

--[[---------------------------------------------------------------------------
    FAdmin command helpers
---------------------------------------------------------------------------]]

local function hasAccess( ply, target )
	if FAdmin.Access.PlayerHasPrivilege( ply, "SWGRP_AdminCommands", target ) then
		return true
	end
	FAdmin.Messages.SendMessage( ply, 5, "No access!" )
	return false
end

local function resolveTargets( ply, query )
	local targets = FAdmin.FindPlayer( query )
	if not targets or #targets == 0 or not IsValid( targets[1] ) then
		FAdmin.Messages.SendMessage( ply, 1, "Player not found" )
		return nil
	end
	return targets
end

-- Admin arrest that bypasses the government CanEnforce restriction.
local function adminArrest( admin, target )
	if not IsValid( target ) then return end

	if target:SWGRP_IsArrested() then
		SWGRP.Police.UnArrest( target )
		return
	end

	local time = SWGRP.Config.ArrestTime
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
	SWGRP.Hooks.Call( "SWGRPPlayerArrested", target, admin )

	timer.Create( "SWGRP_Arrest_" .. target:SteamID64(), time, 1, function()
		if IsValid( target ) then SWGRP.Police.UnArrest( target ) end
	end )
end

local function cmdSetCredits( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	local amount = math.floor( tonumber( args[2] ) or 0 )
	for _, t in ipairs( targets ) do
		if IsValid( t ) then t:SWGRP_SetCredits( amount ) end
	end
	return true
end

local function cmdGiveCredits( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	local amount = math.floor( tonumber( args[2] ) or 0 )
	for _, t in ipairs( targets ) do
		if IsValid( t ) then t:SWGRP_AddCredits( amount ) end
	end
	return true
end

local function cmdSetJob( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	local job, id = SWGRP.GetJobByCommand( args[2] or "" )
	if not id then
		FAdmin.Messages.SendMessage( ply, 1, "Unknown job" )
		return false
	end

	for _, t in ipairs( targets ) do
		if IsValid( t ) and SWGRP.JobsMgr and SWGRP.JobsMgr.SetJob then
			SWGRP.JobsMgr.SetJob( t, id, true )
		end
	end
	return true
end

local function cmdArrest( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	for _, t in ipairs( targets ) do
		if IsValid( t ) then adminArrest( ply, t ) end
	end
	return true
end

local function cmdWanted( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	local reason = table.concat( args, " ", 2 )
	if reason == "" then reason = "Wanted by administration" end

	for _, t in ipairs( targets ) do
		if not IsValid( t ) then continue end
		if t:SWGRP_IsWanted() then
			t:SWGRP_UnWanted()
		else
			t:SWGRP_SetWanted( reason )
			SWGRP.Hooks.Call( "SWGRPPlayerWanted", t, reason, ply )
		end
	end
	return true
end

local function cmdUnArrest( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	for _, t in ipairs( targets ) do
		if IsValid( t ) and t:SWGRP_IsArrested() then SWGRP.Police.UnArrest( t ) end
	end
	return true
end

local function cmdUnWanted( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	for _, t in ipairs( targets ) do
		if IsValid( t ) then SWGRP.Police.ClearWanted( t, ply ) end
	end
	return true
end

local function cmdHeal( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	local amount = tonumber( args[2] )
	for _, t in ipairs( targets ) do
		if IsValid( t ) and t:Alive() then
			if amount then
				t:SetHealth( math.min( t:GetMaxHealth(), t:Health() + amount ) )
				if SWGRP.Hunger and SWGRP.Hunger.Add then
					SWGRP.Hunger.Add( t, amount )
				end
			else
				t:SetHealth( t:GetMaxHealth() )
				if SWGRP.Hunger and SWGRP.Hunger.Set then
					SWGRP.Hunger.Set( t, SWGRP.Config.HungerMax )
				end
			end
		end
	end
	return true
end

local function cmdSlay( ply, cmd, args )
	if not hasAccess( ply ) then return false end
	local targets = resolveTargets( ply, args[1] )
	if not targets then return false end

	for _, t in ipairs( targets ) do
		if IsValid( t ) and t:Alive() then t:Kill() end
	end
	return true
end

local function cmdReloadContent( ply )
	if IsValid( ply ) and not ply:IsSuperAdmin() then
		FAdmin.Messages.SendMessage( ply, 5, "Superadmin only!" )
		return false
	end

	if SWGRP.Content and SWGRP.Content.Reload then
		SWGRP.Content.Reload()
	end
	for _, p in ipairs( player.GetAll() ) do
		if IsValid( p ) and SWGRP.JobsMgr and SWGRP.JobsMgr.ApplyModel then
			SWGRP.JobsMgr.ApplyModel( p, p:Team() )
		end
	end
	net.Start( "SWGRP_ReloadContent" )
	net.Broadcast()

	if IsValid( ply ) then FAdmin.Messages.SendMessage( ply, 4, "Content reloaded." ) end
	return true
end

local function cmdReindexDoors( ply )
	if IsValid( ply ) and not ply:IsSuperAdmin() then
		FAdmin.Messages.SendMessage( ply, 5, "Superadmin only!" )
		return false
	end

	if SWGRP.Doors and SWGRP.Doors.InitializeMap then
		SWGRP.Doors.InitializeMap()
	end

	if IsValid( ply ) then FAdmin.Messages.SendMessage( ply, 4, "Doors re-indexed." ) end
	return true
end

if FAdmin and FAdmin.StartHooks then
	FAdmin.StartHooks["SWGRP_Server"] = function()
		if not FAdmin.Access or not FAdmin.Commands then return end

		FAdmin.Access.AddPrivilege( "SWGRP_AdminCommands", 1 )

		FAdmin.Commands.AddCommand( "SWGRPSetCredits",   cmdSetCredits,   "<Player>", "<amount>" )
		FAdmin.Commands.AddCommand( "SWGRPGiveCredits",  cmdGiveCredits,  "<Player>", "<amount>" )
		FAdmin.Commands.AddCommand( "SWGRPSetJob",       cmdSetJob,       "<Player>", "<job command>" )
		FAdmin.Commands.AddCommand( "SWGRPArrest",       cmdArrest,       "<Player>" )
		FAdmin.Commands.AddCommand( "SWGRPUnArrest",     cmdUnArrest,     "<Player>" )
		FAdmin.Commands.AddCommand( "SWGRPWanted",       cmdWanted,       "<Player>", "[reason]" )
		FAdmin.Commands.AddCommand( "SWGRPUnWanted",     cmdUnWanted,     "<Player>" )
		FAdmin.Commands.AddCommand( "SWGRPHeal",         cmdHeal,         "<Player>", "[amount]" )
		FAdmin.Commands.AddCommand( "SWGRPSlay",         cmdSlay,         "<Player>" )
		FAdmin.Commands.AddCommand( "SWGRPReloadContent", cmdReloadContent )
		FAdmin.Commands.AddCommand( "SWGRPReindexDoors", cmdReindexDoors )
	end
end

if CAMI and CAMI.RegisterPrivilege then
	CAMI.RegisterPrivilege( {
		Name = "SWGRP_GetAdminWeapons",
		MinAccess = "admin",
	} )

	CAMI.RegisterPrivilege( {
		Name = "SWGRP_AdminCommands",
		MinAccess = "admin",
	} )
end

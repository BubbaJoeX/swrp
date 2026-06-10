--[[---------------------------------------------------------------------------
    SWGRP Imperial Command Console - server authority

    Central admin control surface for every gameplay system. Drives both the
    themed VGUI console (cl_admin.lua) and a full set of console/chat command
    mirrors. Every entry point funnels through SWGRP.Admin.CanDoAction so the
    permission rules live in exactly one place (libraries/sh_admin.lua).

    Nothing here trusts the client: targets are re-validated server-side, amounts
    are clamped, and ConVar edits are restricted to an explicit whitelist.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Admin = SWGRP.Admin or {}

local USE_DISTANCE_SQR = 96 * 96

local function ActorName( ply )
	if not IsValid( ply ) then return "Server console" end
	return ply:Nick() .. " (" .. ply:SteamID() .. ")"
end

local function Log( admin, text )
	SWGRP.Log( "admin", ActorName( admin ) .. " " .. text )
end

local function Tell( admin, msg )
	if IsValid( admin ) then
		SWGRP.Notify( admin, msg )
	else
		print( "[SWGRP-Admin] " .. msg )
	end
end

--[[---------------------------------------------------------------------------
    State sync (treasury / lottery pool are server-only, so push them on demand)
---------------------------------------------------------------------------]]

function SWGRP.Admin.SendState( ply )
	if not IsValid( ply ) then return end
	net.Start( "SWGRP_AdminSync" )
		net.WriteInt( math.floor( SWGRP.Economy and SWGRP.Economy.Treasury or 0 ), 32 )
		net.WriteInt( math.floor( SWGRP.Government and SWGRP.Government.LotteryPool or 0 ), 32 )
	net.Send( ply )
end

--[[---------------------------------------------------------------------------
    Action handlers. Each receives an already-resolved, validated set of args so
    the net receiver and the console-command mirrors can share one code path.
---------------------------------------------------------------------------]]

local Actions = {}

-- ---- Economy / player wallet ------------------------------------------------

function Actions.setcredits( admin, target, amount )
	if not IsValid( target ) or not target:IsPlayer() then return end
	amount = math.Clamp( math.floor( amount or 0 ), 0, 1000000000 )
	target:SWGRP_SetCredits( amount )
	Tell( admin, "Set " .. target:Nick() .. "'s credits to " .. SWGRP.FormatCredits( amount ) .. "." )
	Log( admin, "set credits of " .. ActorName( target ) .. " to " .. amount )
end

function Actions.addcredits( admin, target, amount )
	if not IsValid( target ) or not target:IsPlayer() then return end
	amount = math.floor( amount or 0 )
	if amount >= 0 then
		target:SWGRP_AddCredits( amount )
	else
		target:SWGRP_SetCredits( math.max( 0, target:SWGRP_GetCredits() + amount ) )
	end
	Tell( admin, "Adjusted " .. target:Nick() .. "'s credits by " .. amount .. "." )
	Log( admin, "adjusted credits of " .. ActorName( target ) .. " by " .. amount )
end

function Actions.setbank( admin, target, amount )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Banking.SetBalance( target, amount )
	Tell( admin, "Set " .. target:Nick() .. "'s bank balance to " .. SWGRP.FormatCredits( SWGRP.Banking.GetBalance( target ) ) .. "." )
	Log( admin, "set bank balance of " .. ActorName( target ) .. " to " .. amount )
end

-- ---- Jobs -------------------------------------------------------------------

function Actions.setjob( admin, target, teamId )
	if not IsValid( target ) or not target:IsPlayer() then return end
	teamId = tonumber( teamId )
	if not teamId or not SWGRP.Jobs[teamId] then
		Tell( admin, "Unknown profession id." )
		return
	end
	SWGRP.JobsMgr.SetJob( target, teamId, true )
	Tell( admin, "Forced " .. target:Nick() .. " into " .. ( SWGRP.Jobs[teamId].name or tostring( teamId ) ) .. "." )
	Log( admin, "forced " .. ActorName( target ) .. " into job " .. ( SWGRP.Jobs[teamId].name or tostring( teamId ) ) )
end

-- ---- Player movement / state ------------------------------------------------

function Actions.bring( admin, target )
	if not IsValid( admin ) or not IsValid( target ) or not target:IsPlayer() then return end
	target.SWGRP_AdminReturnPos = target.SWGRP_AdminReturnPos or target:GetPos()
	target:SetPos( admin:GetPos() + admin:GetForward() * 64 + Vector( 0, 0, 8 ) )
	Tell( admin, "Brought " .. target:Nick() .. "." )
	Log( admin, "brought " .. ActorName( target ) )
end

function Actions.gotoplayer( admin, target )
	if not IsValid( admin ) or not IsValid( target ) or not target:IsPlayer() then return end
	admin.SWGRP_AdminReturnPos = admin.SWGRP_AdminReturnPos or admin:GetPos()
	admin:SetPos( target:GetPos() + target:GetForward() * -64 + Vector( 0, 0, 8 ) )
	Tell( admin, "Teleported to " .. target:Nick() .. "." )
	Log( admin, "teleported to " .. ActorName( target ) )
end

function Actions.returnpos( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	if target.SWGRP_AdminReturnPos then
		target:SetPos( target.SWGRP_AdminReturnPos )
		target.SWGRP_AdminReturnPos = nil
		Tell( admin, "Returned " .. target:Nick() .. "." )
		Log( admin, "returned " .. ActorName( target ) )
	else
		Tell( admin, target:Nick() .. " has no stored position." )
	end
end

function Actions.freeze( admin, target, state )
	if not IsValid( target ) or not target:IsPlayer() then return end
	target:Freeze( state and true or false )
	Tell( admin, ( state and "Froze " or "Unfroze " ) .. target:Nick() .. "." )
	Log( admin, ( state and "froze " or "unfroze " ) .. ActorName( target ) )
end

function Actions.slay( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	if target:Alive() then target:Kill() end
	Tell( admin, "Slayed " .. target:Nick() .. "." )
	Log( admin, "slayed " .. ActorName( target ) )
end

function Actions.god( admin, target, state )
	if not IsValid( target ) or not target:IsPlayer() then return end
	if state then target:GodEnable() else target:GodDisable() end
	target.SWGRP_AdminGod = state and true or nil
	Tell( admin, ( state and "Enabled" or "Disabled" ) .. " god mode for " .. target:Nick() .. "." )
	Log( admin, ( state and "enabled" or "disabled" ) .. " god mode for " .. ActorName( target ) )
end

function Actions.heal( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	target:SetHealth( target:GetMaxHealth() )
	target:SetArmor( 100 )
	Tell( admin, "Healed " .. target:Nick() .. "." )
	Log( admin, "healed " .. ActorName( target ) )
end

function Actions.sethunger( admin, target, amount )
	if not IsValid( target ) or not target:IsPlayer() or not SWGRP.Hunger then return end
	SWGRP.Hunger.Set( target, math.Clamp( math.floor( amount or 0 ), 0, SWGRP.Config.HungerMax ) )
	Tell( admin, "Set " .. target:Nick() .. "'s rations to " .. target:SWGRP_GetHunger() .. "." )
	Log( admin, "set hunger of " .. ActorName( target ) )
end

function Actions.cloak( admin, target, state )
	if not IsValid( target ) or not target:IsPlayer() then return end
	if state then
		target:SetRenderMode( RENDERMODE_TRANSALPHA )
		target:SetColor( Color( 255, 255, 255, 0 ) )
	else
		target:SetRenderMode( RENDERMODE_NORMAL )
		target:SetColor( Color( 255, 255, 255, 255 ) )
	end
	target.SWGRP_AdminCloaked = state and true or nil
	Tell( admin, ( state and "Cloaked " or "Uncloaked " ) .. target:Nick() .. "." )
	Log( admin, ( state and "cloaked " or "uncloaked " ) .. ActorName( target ) )
end

-- ---- Law enforcement --------------------------------------------------------

function Actions.setwanted( admin, target, reason )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Police.SetWanted( target, reason ~= "" and reason or "Imperial directive", admin )
	Log( admin, "marked " .. ActorName( target ) .. " wanted" )
end

function Actions.clearwanted( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Police.ClearWanted( target, admin )
	Log( admin, "cleared wanted on " .. ActorName( target ) )
end

function Actions.arrest( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Police.AdminArrest( target )
	Log( admin, "detained " .. ActorName( target ) )
end

function Actions.unarrest( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Police.UnArrest( target )
	Log( admin, "released " .. ActorName( target ) )
end

function Actions.clearwarrant( admin, target )
	if not IsValid( target ) or not target:IsPlayer() then return end
	SWGRP.Police.ClearWarrant( target )
	Tell( admin, "Cleared warrant on " .. target:Nick() .. "." )
	Log( admin, "cleared warrant on " .. ActorName( target ) )
end

function Actions.license( admin, target, state )
	if not IsValid( target ) or not target:IsPlayer() then return end
	target:SWGRP_SetLicense( state and true or false )
	Tell( admin, ( state and "Granted" or "Revoked" ) .. " weapon permit for " .. target:Nick() .. "." )
	Log( admin, ( state and "granted" or "revoked" ) .. " license for " .. ActorName( target ) )
end

-- ---- Moderation -------------------------------------------------------------

function Actions.kick( admin, target, reason )
	if not IsValid( target ) or not target:IsPlayer() then return end
	Log( admin, "kicked " .. ActorName( target ) .. ": " .. ( reason or "" ) )
	target:Kick( "[Imperial Command] " .. ( reason ~= "" and reason or "Removed by an administrator" ) )
end

function Actions.ban( admin, target, minutes, reason )
	if not IsValid( target ) or not target:IsPlayer() then return end
	minutes = math.Clamp( math.floor( minutes or 0 ), 0, 525600 )
	Log( admin, "banned " .. ActorName( target ) .. " for " .. minutes .. "m: " .. ( reason or "" ) )
	target:Ban( minutes, true )
end

-- ---- Server-wide economy / government ---------------------------------------

function Actions.settreasury( admin, amount )
	SWGRP.Economy.Treasury = math.max( 0, math.floor( amount or 0 ) )
	Tell( admin, "Imperial treasury set to " .. SWGRP.FormatCredits( SWGRP.Economy.Treasury ) .. "." )
	Log( admin, "set treasury to " .. SWGRP.Economy.Treasury )
end

function Actions.payday( admin )
	SWGRP.Economy.Payday()
	Tell( admin, "Forced a payday cycle." )
	Log( admin, "forced a payday" )
end

function Actions.lottery( admin )
	SWGRP.Government.RunLottery()
	Tell( admin, "Forced a lottery draw." )
	Log( admin, "forced a lottery draw" )
end

function Actions.addlaw( admin, text )
	if not text or text == "" then return end
	SWGRP.Government.AddLaw( text )
	Tell( admin, "Edict added." )
	Log( admin, "added edict: " .. text )
end

function Actions.removelaw( admin, index )
	SWGRP.Government.RemoveLaw( tonumber( index ) or 0 )
	Tell( admin, "Edict removed." )
	Log( admin, "removed edict #" .. tostring( index ) )
end

function Actions.resetlaws( admin )
	SWGRP.Government.ResetLaws()
	Tell( admin, "Edicts reset to defaults." )
	Log( admin, "reset edicts" )
end

function Actions.agenda( admin, text )
	SWGRP.Government.SetAgenda( text or "" )
	Tell( admin, "Governor agenda updated." )
	Log( admin, "set agenda" )
end

function Actions.lockdown( admin, state )
	SWGRP.Government.AdminSetLockdown( state and true or false )
	Log( admin, ( state and "started" or "ended" ) .. " lockdown" )
end

function Actions.broadcast( admin, text )
	if not text or text == "" then return end
	if SWGRP.Advert and SWGRP.Advert.Broadcast then
		SWGRP.Advert.Broadcast( "Imperial Command", text, SWGRP.Config.HUDColorDanger )
	end
	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( "[IMPERIAL COMMAND] " .. text )
	end
	Log( admin, "broadcast: " .. text )
end

-- ---- System toggles ---------------------------------------------------------

function Actions.setconvar( admin, name, value )
	if not SWGRP.Admin.ConVarWhitelist[name] then
		Tell( admin, "ConVar '" .. tostring( name ) .. "' is not adjustable from the console." )
		return
	end
	RunConsoleCommand( name, tostring( value ) )
	Tell( admin, "Set " .. name .. " = " .. tostring( value ) .. "." )
	Log( admin, "set convar " .. name .. " = " .. tostring( value ) )
end

function Actions.reloadcontent( admin )
	if SWGRP.Content and SWGRP.Content.Reload then
		SWGRP.Content.Reload()
		for _, p in ipairs( player.GetAll() ) do
			if IsValid( p ) and SWGRP.JobsMgr and SWGRP.JobsMgr.ApplyModel then
				SWGRP.JobsMgr.ApplyModel( p, p:Team() )
			end
		end
		Tell( admin, "CSV content reloaded." )
		Log( admin, "reloaded CSV content" )
	end
end

function Actions.clearhits( admin )
	if SWGRP.Hitman and SWGRP.Hitman.ClearAll then SWGRP.Hitman.ClearAll() end
	Tell( admin, "All bounty contracts cleared." )
	Log( admin, "cleared all bounty contracts" )
end

function Actions.clearwarrants( admin )
	for sid in pairs( SWGRP.Police.Warrants ) do
		SWGRP.Police.Warrants[sid] = nil
		if SWGRP.Persistence and SWGRP.Persistence.DeleteWarrant then
			SWGRP.Persistence.DeleteWarrant( sid )
		end
	end
	Tell( admin, "All search warrants cleared." )
	Log( admin, "cleared all warrants" )
end

SWGRP.Admin.Actions = Actions

--[[---------------------------------------------------------------------------
    Network entry point
---------------------------------------------------------------------------]]

net.Receive( "SWGRP_AdminAction", function( _, ply )
	local action = net.ReadString()

	if action == "requeststate" then
		if SWGRP.Admin.CanUse( ply ) then SWGRP.Admin.SendState( ply ) end
		return
	end

	if not SWGRP.Admin.CanDoAction( ply, action ) then
		SWGRP.Notify( ply, "You are not authorized for that action." )
		return
	end

	-- Player-target actions read an entity first; server-wide actions don't.
	if action == "setcredits" then
		Actions.setcredits( ply, net.ReadEntity(), net.ReadInt( 32 ) )
	elseif action == "addcredits" then
		Actions.addcredits( ply, net.ReadEntity(), net.ReadInt( 32 ) )
	elseif action == "setbank" then
		Actions.setbank( ply, net.ReadEntity(), net.ReadInt( 32 ) )
	elseif action == "setjob" then
		Actions.setjob( ply, net.ReadEntity(), net.ReadUInt( 16 ) )
	elseif action == "bring" then
		Actions.bring( ply, net.ReadEntity() )
	elseif action == "goto" then
		Actions.gotoplayer( ply, net.ReadEntity() )
	elseif action == "return" then
		Actions.returnpos( ply, net.ReadEntity() )
	elseif action == "freeze" then
		Actions.freeze( ply, net.ReadEntity(), net.ReadBool() )
	elseif action == "slay" then
		Actions.slay( ply, net.ReadEntity() )
	elseif action == "god" then
		Actions.god( ply, net.ReadEntity(), net.ReadBool() )
	elseif action == "heal" then
		Actions.heal( ply, net.ReadEntity() )
	elseif action == "sethunger" then
		Actions.sethunger( ply, net.ReadEntity(), net.ReadUInt( 8 ) )
	elseif action == "cloak" then
		Actions.cloak( ply, net.ReadEntity(), net.ReadBool() )
	elseif action == "setwanted" then
		Actions.setwanted( ply, net.ReadEntity(), net.ReadString() )
	elseif action == "clearwanted" then
		Actions.clearwanted( ply, net.ReadEntity() )
	elseif action == "arrest" then
		Actions.arrest( ply, net.ReadEntity() )
	elseif action == "unarrest" then
		Actions.unarrest( ply, net.ReadEntity() )
	elseif action == "clearwarrant" then
		Actions.clearwarrant( ply, net.ReadEntity() )
	elseif action == "license" then
		Actions.license( ply, net.ReadEntity(), net.ReadBool() )
	elseif action == "kick" then
		Actions.kick( ply, net.ReadEntity(), net.ReadString() )
	elseif action == "ban" then
		Actions.ban( ply, net.ReadEntity(), net.ReadUInt( 32 ), net.ReadString() )
	elseif action == "settreasury" then
		Actions.settreasury( ply, net.ReadInt( 32 ) )
		SWGRP.Admin.SendState( ply )
	elseif action == "payday" then
		Actions.payday( ply )
	elseif action == "lottery" then
		Actions.lottery( ply )
		SWGRP.Admin.SendState( ply )
	elseif action == "addlaw" then
		Actions.addlaw( ply, net.ReadString() )
	elseif action == "removelaw" then
		Actions.removelaw( ply, net.ReadUInt( 8 ) )
	elseif action == "resetlaws" then
		Actions.resetlaws( ply )
	elseif action == "agenda" then
		Actions.agenda( ply, net.ReadString() )
	elseif action == "lockdown" then
		Actions.lockdown( ply, net.ReadBool() )
	elseif action == "broadcast" then
		Actions.broadcast( ply, net.ReadString() )
	elseif action == "setconvar" then
		Actions.setconvar( ply, net.ReadString(), net.ReadString() )
	elseif action == "reloadcontent" then
		Actions.reloadcontent( ply )
	elseif action == "clearhits" then
		Actions.clearhits( ply )
		SWGRP.Admin.SendState( ply )
	elseif action == "clearwarrants" then
		Actions.clearwarrants( ply )
	end
end )

--[[---------------------------------------------------------------------------
    Console + chat command mirrors. Every command resolves its target/args and
    funnels into the same Actions table after the shared permission gate.
---------------------------------------------------------------------------]]

local function AdminConCommand( name, fn )
	concommand.Add( name, function( ply, _, args )
		if not SWGRP.Admin.CanUse( ply ) then
			Tell( ply, "You are not authorized." )
			return
		end
		fn( ply, args )
	end )
end

AdminConCommand( "swgrp_setcredits", function( ply, args )
	Actions.setcredits( ply, SWGRP.FindPlayer( args[1] ), tonumber( args[2] ) or 0 )
end )

AdminConCommand( "swgrp_addcredits", function( ply, args )
	Actions.addcredits( ply, SWGRP.FindPlayer( args[1] ), tonumber( args[2] ) or 0 )
end )

AdminConCommand( "swgrp_setbank", function( ply, args )
	Actions.setbank( ply, SWGRP.FindPlayer( args[1] ), tonumber( args[2] ) or 0 )
end )

AdminConCommand( "swgrp_forcejob", function( ply, args )
	local target = SWGRP.FindPlayer( args[1] )
	local teamId = tonumber( args[2] )
	if not teamId then
		local _, id = SWGRP.GetJobByCommand( args[2] or "" )
		teamId = id
	end
	Actions.setjob( ply, target, teamId )
end )

AdminConCommand( "swgrp_bring", function( ply, args ) Actions.bring( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_goto", function( ply, args ) Actions.gotoplayer( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_return", function( ply, args ) Actions.returnpos( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_slay", function( ply, args ) Actions.slay( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_heal_admin", function( ply, args ) Actions.heal( ply, SWGRP.FindPlayer( args[1] ) ) end )

AdminConCommand( "swgrp_freeze", function( ply, args )
	Actions.freeze( ply, SWGRP.FindPlayer( args[1] ), tobool( args[2] == nil and true or args[2] ) )
end )

AdminConCommand( "swgrp_god", function( ply, args )
	Actions.god( ply, SWGRP.FindPlayer( args[1] ), tobool( args[2] == nil and true or args[2] ) )
end )

AdminConCommand( "swgrp_cloak", function( ply, args )
	Actions.cloak( ply, SWGRP.FindPlayer( args[1] ), tobool( args[2] == nil and true or args[2] ) )
end )

AdminConCommand( "swgrp_arrest", function( ply, args ) Actions.arrest( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_unarrest", function( ply, args ) Actions.unarrest( ply, SWGRP.FindPlayer( args[1] ) ) end )
AdminConCommand( "swgrp_clearwarrant", function( ply, args ) Actions.clearwarrant( ply, SWGRP.FindPlayer( args[1] ) ) end )

AdminConCommand( "swgrp_setwanted", function( ply, args )
	local target = SWGRP.FindPlayer( args[1] )
	table.remove( args, 1 )
	Actions.setwanted( ply, target, table.concat( args, " " ) )
end )

AdminConCommand( "swgrp_clearwanted", function( ply, args ) Actions.clearwanted( ply, SWGRP.FindPlayer( args[1] ) ) end )

AdminConCommand( "swgrp_givepermit", function( ply, args )
	Actions.license( ply, SWGRP.FindPlayer( args[1] ), true )
end )
AdminConCommand( "swgrp_revokepermit", function( ply, args )
	Actions.license( ply, SWGRP.FindPlayer( args[1] ), false )
end )

AdminConCommand( "swgrp_payday", function( ply ) Actions.payday( ply ) end )
AdminConCommand( "swgrp_lottery", function( ply ) Actions.lottery( ply ) end )
AdminConCommand( "swgrp_settreasury", function( ply, args ) Actions.settreasury( ply, tonumber( args[1] ) or 0 ) end )
AdminConCommand( "swgrp_clearhits", function( ply ) Actions.clearhits( ply ) end )
AdminConCommand( "swgrp_clearwarrants", function( ply ) Actions.clearwarrants( ply ) end )

AdminConCommand( "swgrp_lockdown_admin", function( ply, args )
	Actions.lockdown( ply, tobool( args[1] == nil and true or args[1] ) )
end )

AdminConCommand( "swgrp_addedict", function( ply, args ) Actions.addlaw( ply, table.concat( args, " " ) ) end )
AdminConCommand( "swgrp_resetedicts", function( ply ) Actions.resetlaws( ply ) end )

AdminConCommand( "swgrp_imperial_broadcast", function( ply, args ) Actions.broadcast( ply, table.concat( args, " " ) ) end )

-- /admin opens the console for authorized players (the actual UI lives client-side).
SWGRP.RegisterChatCommand( "admin", {
	description = "Open the Imperial Command Console (admins)",
	execute = function( ply )
		if not SWGRP.Admin.CanUse( ply ) then
			SWGRP.Notify( ply, "You are not authorized." )
			return
		end
		net.Start( "SWGRP_AdminMenu" )
		net.Send( ply )
	end,
})

SWGRP.RegisterChatCommand( "adminmenu", {
	description = "Alias for /admin",
	execute = function( ply, args )
		SWGRP.ChatCmds["admin"].execute( ply, args )
	end,
})

print( "[SWGRP] Imperial Command Console (server) loaded." )

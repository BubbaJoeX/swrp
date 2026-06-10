--[[---------------------------------------------------------------------------
    SWGRP SQLite Persistence
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.DB = SWGRP.DB or {}

local function SWGRP_DB_AddColumn( tableName, column, definition )
	local cols = sql.Query( "PRAGMA table_info(" .. tableName .. ")" )
	if cols then
		for _, c in ipairs( cols ) do
			if c.name == column then return end
		end
	end
	sql.Query( "ALTER TABLE " .. tableName .. " ADD COLUMN " .. column .. " " .. definition )
end

function SWGRP.DB.Initialize()
	if not sql then return end

	sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_players (
		steamid TEXT PRIMARY KEY,
		credits INTEGER DEFAULT 500,
		license INTEGER DEFAULT 0,
		last_team INTEGER DEFAULT 1,
		bank INTEGER DEFAULT 0,
		hunger INTEGER DEFAULT 100,
		faction_imperial INTEGER DEFAULT 0,
		faction_rebel INTEGER DEFAULT 0,
		faction_underworld INTEGER DEFAULT 0,
		prof_xp TEXT DEFAULT '{}',
		materials TEXT DEFAULT '{}',
		contraband TEXT DEFAULT '{}'
	)]] )

	SWGRP_DB_AddColumn( "swgrp_players", "bank", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "hunger", "INTEGER DEFAULT 100" )
	SWGRP_DB_AddColumn( "swgrp_players", "faction_imperial", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "faction_rebel", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "faction_underworld", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "prof_xp", "TEXT DEFAULT '{}'" )
	SWGRP_DB_AddColumn( "swgrp_players", "materials", "TEXT DEFAULT '{}'" )
	SWGRP_DB_AddColumn( "swgrp_players", "contraband", "TEXT DEFAULT '{}'" )
	SWGRP_DB_AddColumn( "swgrp_players", "wanted", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "wanted_reason", "TEXT DEFAULT ''" )
	SWGRP_DB_AddColumn( "swgrp_players", "wanted_expire", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "arrested", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "arrest_expire", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "mission_id", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "mission_progress", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "mission_deadline", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "mission_cooldown", "INTEGER DEFAULT 0" )
	SWGRP_DB_AddColumn( "swgrp_players", "job_models", "TEXT DEFAULT '{}'" )
	SWGRP_DB_AddColumn( "swgrp_players", "pocket", "TEXT DEFAULT ''" )
	SWGRP_DB_AddColumn( "swgrp_players", "vehicle_license", "INTEGER DEFAULT 0" )

	sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_doors (
		map TEXT,
		door_id INTEGER,
		owner TEXT,
		title TEXT,
		locked INTEGER DEFAULT 1,
		group_name TEXT,
		coowners TEXT DEFAULT '{}',
		owner_name TEXT,
		owner_job TEXT,
		PRIMARY KEY (map, door_id)
	)]] )

	SWGRP_DB_AddColumn( "swgrp_doors", "coowners", "TEXT DEFAULT '{}'" )
	SWGRP_DB_AddColumn( "swgrp_doors", "owner_name", "TEXT" )
	SWGRP_DB_AddColumn( "swgrp_doors", "owner_job", "TEXT" )
	SWGRP_DB_AddColumn( "swgrp_doors", "flag", "TEXT DEFAULT ''" )

	sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_world (
		key TEXT PRIMARY KEY,
		value TEXT
	)]] )

	sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_bounties (
		target_steamid TEXT PRIMARY KEY,
		customer_steamid TEXT,
		price INTEGER,
		placed_at INTEGER
	)]] )

	sql.Query( [[CREATE TABLE IF NOT EXISTS swgrp_warrants (
		target_steamid TEXT PRIMARY KEY,
		reason TEXT,
		expire_at INTEGER,
		officer_steamid TEXT
	)]] )
end

function SWGRP.DB.SetWorld( key, value )
	if not sql then return end
	sql.Query( string.format(
		"REPLACE INTO swgrp_world (key, value) VALUES (%s, %s)",
		sql.SQLStr( key ),
		sql.SQLStr( tostring( value or "" ) )
	) )
end

function SWGRP.DB.GetWorld( key, default )
	if not sql then return default end
	local row = sql.QueryRow( "SELECT value FROM swgrp_world WHERE key = " .. sql.SQLStr( key ) )
	if row and row.value ~= nil then return row.value end
	return default
end

function SWGRP.DB.SaveBounty( targetSid, customerSid, price )
	if not sql then return end
	sql.Query( string.format(
		[[REPLACE INTO swgrp_bounties (target_steamid, customer_steamid, price, placed_at)
		VALUES (%s, %s, %d, %d)]],
		sql.SQLStr( targetSid ),
		sql.SQLStr( customerSid ),
		math.floor( price or 0 ),
		os.time()
	) )
end

function SWGRP.DB.DeleteBounty( targetSid )
	if not sql or not targetSid then return end
	sql.Query( "DELETE FROM swgrp_bounties WHERE target_steamid = " .. sql.SQLStr( targetSid ) )
end

function SWGRP.DB.LoadBounties()
	if not sql then return {} end
	return sql.Query( "SELECT * FROM swgrp_bounties" ) or {}
end

function SWGRP.DB.SaveWarrant( targetSid, reason, expireAt, officerSid )
	if not sql then return end
	sql.Query( string.format(
		[[REPLACE INTO swgrp_warrants (target_steamid, reason, expire_at, officer_steamid)
		VALUES (%s, %s, %d, %s)]],
		sql.SQLStr( targetSid ),
		sql.SQLStr( reason or "" ),
		math.floor( expireAt or 0 ),
		sql.SQLStr( officerSid or "" )
	) )
end

function SWGRP.DB.DeleteWarrant( targetSid )
	if not sql or not targetSid then return end
	sql.Query( "DELETE FROM swgrp_warrants WHERE target_steamid = " .. sql.SQLStr( targetSid ) )
end

function SWGRP.DB.LoadWarrants()
	if not sql then return {} end
	return sql.Query( "SELECT * FROM swgrp_warrants" ) or {}
end

function SWGRP.DB.SaveDoor( mapDoorId, data )
	if not sql or not mapDoorId or not data then return end

	local map = sql.SQLStr( game.GetMap() )
	local coowners = sql.SQLStr( util.TableToJSON( data.coowners or {} ) )

	sql.Query( string.format(
		[[REPLACE INTO swgrp_doors
		(map, door_id, owner, title, locked, group_name, coowners, owner_name, owner_job, flag)
		VALUES (%s, %d, %s, %s, %d, %s, %s, %s, %s, %s)]],
		map,
		mapDoorId,
		sql.SQLStr( data.ownerSteamID or "" ),
		sql.SQLStr( data.title or "" ),
		data.locked and 1 or 0,
		sql.SQLStr( data.group or "" ),
		coowners,
		sql.SQLStr( data.ownerName or "" ),
		sql.SQLStr( data.ownerJob or "" ),
		sql.SQLStr( data.flag or "" )
	) )
end

function SWGRP.DB.DeleteDoor( mapDoorId )
	if not sql or not mapDoorId then return end

	sql.Query( string.format(
		"DELETE FROM swgrp_doors WHERE map = %s AND door_id = %d",
		sql.SQLStr( game.GetMap() ),
		mapDoorId
	) )
end

function SWGRP.DB.LoadDoors()
	if not sql then return {} end

	local rows = sql.Query( string.format(
		"SELECT * FROM swgrp_doors WHERE map = %s",
		sql.SQLStr( game.GetMap() )
	) )

	return rows or {}
end

function SWGRP.DB.ParseJSON( str )
	if not str or str == "" or str == "{}" then return {} end
	return util.JSONToTable( str ) or {}
end

function SWGRP.DB.LoadPlayer( ply )
	local sid = ply:SteamID()
	local row = sql.QueryRow( "SELECT * FROM swgrp_players WHERE steamid = " .. sql.SQLStr( sid ) )

	if row then
		ply:SWGRP_SetCredits( tonumber( row.credits ) or SWGRP.Config.StartCredits:GetInt() )
		ply:SWGRP_SetLicense( tonumber( row.license ) == 1 )
		ply:SWGRP_SetVehicleLicense( tonumber( row.vehicle_license ) == 1 )
		ply.SWGRP_LastTeam = tonumber( row.last_team ) or TEAM_COLONIST

		ply.SWGRP_BankBalance = tonumber( row.bank ) or 0
		ply:SetNWInt( "SWGRP_Bank", ply.SWGRP_BankBalance )

		SWGRP.Hunger.Set( ply, tonumber( row.hunger ) or SWGRP.Config.HungerMax )

		SWGRP.Factions.Set( ply, "imperial", tonumber( row.faction_imperial ) or 0 )
		SWGRP.Factions.Set( ply, "rebel", tonumber( row.faction_rebel ) or 0 )
		SWGRP.Factions.Set( ply, "underworld", tonumber( row.faction_underworld ) or 0 )

		ply.SWGRP_ProfessionXP = SWGRP.DB.ParseJSON( row.prof_xp )
		ply.SWGRP_Materials = SWGRP.DB.ParseJSON( row.materials )
		ply.SWGRP_Contraband = SWGRP.DB.ParseJSON( row.contraband )
		ply.SWGRP_JobModels = SWGRP.DB.ParseJSON( row.job_models )
		ply.SWGRP_Pocket = row.pocket or ""
		ply.SWGRP_PocketSlots = nil
		ply.SWGRP_PocketItems = nil
		ply:SetNWString( "SWGRP_Pocket", ply.SWGRP_Pocket or "" )

		SWGRP.Materials.SyncAll( ply )
		SWGRP.Profession.Sync( ply )
		ply:SetNWInt( "SWGRP_ContraCount", SWGRP.Contraband.TotalCount( ply ) )

		if SWGRP.Persistence and SWGRP.Persistence.RestorePlayer then
			SWGRP.Persistence.RestorePlayer( ply, row )
		end
	else
		ply:SWGRP_SetCredits( SWGRP.Config.StartCredits:GetInt() )
		ply:SWGRP_SetLicense( false )
		ply:SWGRP_SetVehicleLicense( false )
		ply.SWGRP_LastTeam = TEAM_COLONIST
		ply.SWGRP_BankBalance = 0
		ply:SetNWInt( "SWGRP_Bank", 0 )
		SWGRP.Hunger.Set( ply, SWGRP.Config.HungerMax )
		SWGRP.Factions.SyncAll( ply )
		ply.SWGRP_ProfessionXP = {}
		ply.SWGRP_Materials = {}
		ply.SWGRP_Contraband = {}
		ply.SWGRP_JobModels = {}
		ply.SWGRP_Pocket = ""
		ply:SetNWString( "SWGRP_Pocket", "" )
		SWGRP.Materials.SyncAll( ply )
		SWGRP.Profession.Sync( ply )

		sql.Query( string.format(
			"INSERT INTO swgrp_players (steamid, credits, license, last_team) VALUES (%s, %d, 0, %d)",
			sql.SQLStr( sid ),
			SWGRP.Config.StartCredits:GetInt(),
			TEAM_COLONIST
		) )

		if SWGRP.Persistence and SWGRP.Persistence.RestorePlayer then
			SWGRP.Persistence.RestorePlayer( ply, nil )
		end
	end
end

function SWGRP.DB.PlayerMissionFields( ply )
	local mission = ply.SWGRP_ActiveMission
	return mission and mission.id or 0,
		mission and mission.progress or 0,
		ply.SWGRP_MissionDeadline or 0,
		ply.SWGRP_MissionCooldown or 0
end

function SWGRP.DB.PlayerLawFields( ply )
	return ply:SWGRP_IsWanted() and 1 or 0,
		ply:SWGRP_GetWantedReason(),
		ply.SWGRP_WantedExpire or 0,
		ply:SWGRP_IsArrested() and 1 or 0,
		ply.SWGRP_ArrestExpire or 0
end

function SWGRP.DB.SavePlayer( ply )
	if not IsValid( ply ) then return end
	local sid = sql.SQLStr( ply:SteamID() )
	local missionId, missionProgress, missionDeadline, missionCooldown = SWGRP.DB.PlayerMissionFields( ply )
	local wanted, wantedReason, wantedExpire, arrested, arrestExpire = SWGRP.DB.PlayerLawFields( ply )

	sql.Query( string.format(
		[[REPLACE INTO swgrp_players
		(steamid, credits, license, vehicle_license, last_team, bank, hunger,
		 faction_imperial, faction_rebel, faction_underworld,
		 prof_xp, materials, contraband, job_models, pocket,
		 wanted, wanted_reason, wanted_expire, arrested, arrest_expire,
		 mission_id, mission_progress, mission_deadline, mission_cooldown)
		VALUES (%s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %s, %s, %s, %s, %s, %d, %s, %d, %d, %d, %d, %d, %d, %d)]],
		sid,
		ply:SWGRP_GetCredits(),
		ply:SWGRP_HasLicense() and 1 or 0,
		ply:SWGRP_HasVehicleLicense() and 1 or 0,
		ply:Team(),
		ply.SWGRP_BankBalance or 0,
		SWGRP.Hunger.Get( ply ),
		SWGRP.Factions.Get( ply, "imperial" ),
		SWGRP.Factions.Get( ply, "rebel" ),
		SWGRP.Factions.Get( ply, "underworld" ),
		sql.SQLStr( util.TableToJSON( ply.SWGRP_ProfessionXP or {} ) ),
		sql.SQLStr( util.TableToJSON( ply.SWGRP_Materials or {} ) ),
		sql.SQLStr( util.TableToJSON( ply.SWGRP_Contraband or {} ) ),
		sql.SQLStr( util.TableToJSON( ply.SWGRP_JobModels or {} ) ),
		sql.SQLStr( ply.SWGRP_Pocket or "" ),
		wanted,
		sql.SQLStr( wantedReason or "" ),
		wantedExpire,
		arrested,
		arrestExpire,
		missionId,
		missionProgress,
		missionDeadline,
		missionCooldown
	) )
end

function SWGRP.DB.SaveAll()
	for _, ply in ipairs( player.GetAll() ) do
		SWGRP.DB.SavePlayer( ply )
	end
end

hook.Add( "ShutDown", "SWGRP_SaveAll", function()
	SWGRP.DB.SaveAll()
	if SWGRP.Persistence and SWGRP.Persistence.SaveWorld then
		SWGRP.Persistence.SaveWorld()
	end
end )

timer.Create( "SWGRP_AutoSave", 300, 0, function()
	SWGRP.DB.SaveAll()
	if SWGRP.Persistence and SWGRP.Persistence.SaveWorld then
		SWGRP.Persistence.SaveWorld()
	end
end )

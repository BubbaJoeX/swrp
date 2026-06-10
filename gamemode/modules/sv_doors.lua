--[[---------------------------------------------------------------------------
    Door Ownership System
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Doors = SWGRP.Doors or {}
SWGRP.Doors.Data = SWGRP.Doors.Data or {}
SWGRP.Doors.LinkGroups = SWGRP.Doors.LinkGroups or {}
SWGRP.Doors.EntToGroup = SWGRP.Doors.EntToGroup or {}
SWGRP.Doors.ButtonLinks = SWGRP.Doors.ButtonLinks or {}
SWGRP.Doors.TargetIndex = SWGRP.Doors.TargetIndex or {}
SWGRP.Doors.MapDoors = SWGRP.Doors.MapDoors or {}
SWGRP.Doors.EntToMapId = SWGRP.Doors.EntToMapId or {}
SWGRP.Doors.IdToEnt = SWGRP.Doors.IdToEnt or {}

local LINK_DISTANCE = 110

function SWGRP.Doors.MakeDataFromPlayer( ply, title )
	return {
		owner = ply,
		ownerSteamID = ply:SteamID(),
		ownerName = ply:Nick(),
		ownerJob = ply:SWGRP_GetJobName(),
		title = title or ( ply:Nick() .. "'s Structure" ),
		locked = true,
		coowners = {},
	}
end

function SWGRP.Doors.GetMapDoorId( ent )
	if not IsValid( ent ) then return nil end
	return SWGRP.Doors.EntToMapId[SWGRP.Doors.GetID( ent )]
end

function SWGRP.Doors.GetSaveMapDoorId( ent )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	return SWGRP.Doors.GetMapDoorId( master )
end

function SWGRP.Doors.SaveRecord( ent )
	local mapDoorId = SWGRP.Doors.GetSaveMapDoorId( ent )
	local d = SWGRP.Doors.GetMasterData( ent )
	if not mapDoorId or not d or not d.ownerSteamID then return end
	SWGRP.DB.SaveDoor( mapDoorId, d )
end

function SWGRP.Doors.DeleteRecord( ent )
	local mapDoorId = SWGRP.Doors.GetSaveMapDoorId( ent )
	if mapDoorId then
		SWGRP.DB.DeleteDoor( mapDoorId )
	end
end

function SWGRP.Doors.AssignMapIds()
	SWGRP.Doors.EntToMapId = {}
	SWGRP.Doors.IdToEnt = {}

	table.sort( SWGRP.Doors.MapDoors, function( a, b )
		local pa, pb = a:GetPos(), b:GetPos()
		if pa.x ~= pb.x then return pa.x < pb.x end
		if pa.y ~= pb.y then return pa.y < pb.y end
		return pa.z < pb.z
	end )

	for i, door in ipairs( SWGRP.Doors.MapDoors ) do
		if IsValid( door ) then
			SWGRP.Doors.EntToMapId[SWGRP.Doors.GetID( door )] = i
			SWGRP.Doors.IdToEnt[i] = door
		end
	end
end

function SWGRP.Doors.RecalcDoorCount( ply )
	if not IsValid( ply ) then return end

	local seen = {}
	local count = 0

	for id, d in pairs( SWGRP.Doors.Data ) do
		if d.owner == ply or d.ownerSteamID == ply:SteamID() then
			local gid = SWGRP.Doors.GetGroupId( Entity( id ) ) or id
			if not seen[gid] then
				seen[gid] = true
				count = count + 1
			end
		end
	end

	ply.SWGRP_DoorCount = count
end

function SWGRP.Doors.ResolveOwners( ply )
	if not IsValid( ply ) then return end

	for _, door in ipairs( SWGRP.Doors.MapDoors ) do
		if IsValid( door ) then
			local d = SWGRP.Doors.GetData( door )
			if d and d.ownerSteamID == ply:SteamID() then
				d.owner = ply
				d.ownerName = ply:Nick()
				d.ownerJob = ply:SWGRP_GetJobName()
				SWGRP.Doors.Sync( door )
			end
		end
	end

	SWGRP.Doors.RecalcDoorCount( ply )
end

function SWGRP.Doors.LoadFromDatabase()
	local loaded = {}

	for _, row in ipairs( SWGRP.DB.LoadDoors() ) do
		local mapDoorId = tonumber( row.door_id )
		local door = mapDoorId and SWGRP.Doors.IdToEnt[mapDoorId]
		if IsValid( door ) then
			local groupKey = SWGRP.Doors.GetGroupId( door ) or mapDoorId
			if not loaded[groupKey] then
				loaded[groupKey] = true

				local owner = player.GetBySteamID( row.owner or "" )
				local data = {
					owner = owner,
					ownerSteamID = row.owner or "",
					ownerName = row.owner_name or ( IsValid( owner ) and owner:Nick() or "Unknown" ),
					ownerJob = row.owner_job or ( IsValid( owner ) and owner:SWGRP_GetJobName() or "Colonist" ),
					title = row.title or "Structure",
					locked = tonumber( row.locked ) == 1,
					coowners = SWGRP.DB.ParseJSON( row.coowners ),
					group = row.group_name ~= "" and row.group_name or nil,
					flag = row.flag or "",
				}

				SWGRP.Doors.ApplyOwnership( door, data, true )

				SWGRP.Doors.ForEachLinked( door, function( linked )
					SWGRP.Doors.RefreshEngineLock( linked, data.locked )
				end )
			end
		end
	end

	for _, ply in ipairs( player.GetAll() ) do
		SWGRP.Doors.RecalcDoorCount( ply )
	end
end

function SWGRP.Doors.GetID( ent )
	return ent:EntIndex()
end

function SWGRP.Doors.GetData( ent )
	return SWGRP.Doors.Data[SWGRP.Doors.GetID( ent )]
end

function SWGRP.Doors.SetData( ent, data )
	SWGRP.Doors.Data[SWGRP.Doors.GetID( ent )] = data
end

function SWGRP.Doors.GetGroupId( ent )
	return SWGRP.Doors.EntToGroup[SWGRP.Doors.GetID( ent )]
end

function SWGRP.Doors.GetLinkedDoors( ent )
	if not IsValid( ent ) then return {} end

	local gid = SWGRP.Doors.GetGroupId( ent )
	if gid and SWGRP.Doors.LinkGroups[gid] then
		return SWGRP.Doors.LinkGroups[gid]
	end

	return { ent }
end

function SWGRP.Doors.GetMasterDoor( ent )
	local doors = SWGRP.Doors.GetLinkedDoors( ent )
	for _, door in ipairs( doors ) do
		if SWGRP.Doors.GetData( door ) then
			return door
		end
	end
	return doors[1] or ent
end

function SWGRP.Doors.GetMasterData( ent )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	return SWGRP.Doors.GetData( master ), master
end

function SWGRP.Doors.ForEachLinked( ent, fn )
	for _, door in ipairs( SWGRP.Doors.GetLinkedDoors( ent ) ) do
		if IsValid( door ) then
			fn( door )
		end
	end
end

function SWGRP.Doors.RegisterLinkGroup( doors )
	local valid = {}
	for _, door in ipairs( doors ) do
		if IsValid( door ) and door:isDoor() then
			table.insert( valid, door )
		end
	end

	if #valid < 2 then return end

	table.insert( SWGRP.Doors.LinkGroups, valid )
	local gid = #SWGRP.Doors.LinkGroups
	for _, door in ipairs( valid ) do
		SWGRP.Doors.EntToGroup[SWGRP.Doors.GetID( door )] = gid
	end
end

function SWGRP.Doors.MergeGroups( doorA, doorB )
	if not IsValid( doorA ) or not IsValid( doorB ) then return end

	local gidA = SWGRP.Doors.GetGroupId( doorA )
	local gidB = SWGRP.Doors.GetGroupId( doorB )

	if gidA and gidB then
		if gidA == gidB then return end
		local groupA = SWGRP.Doors.LinkGroups[gidA]
		local groupB = SWGRP.Doors.LinkGroups[gidB]
		for _, door in ipairs( groupB ) do
			table.insert( groupA, door )
			SWGRP.Doors.EntToGroup[SWGRP.Doors.GetID( door )] = gidA
		end
		SWGRP.Doors.LinkGroups[gidB] = nil
		return
	end

	if gidA then
		table.insert( SWGRP.Doors.LinkGroups[gidA], doorB )
		SWGRP.Doors.EntToGroup[SWGRP.Doors.GetID( doorB )] = gidA
	elseif gidB then
		table.insert( SWGRP.Doors.LinkGroups[gidB], doorA )
		SWGRP.Doors.EntToGroup[SWGRP.Doors.GetID( doorA )] = gidB
	else
		SWGRP.Doors.RegisterLinkGroup( { doorA, doorB } )
	end
end

function SWGRP.Doors.FindByTargetName( targetName )
	if not targetName or targetName == "" then return {} end
	return SWGRP.Doors.TargetIndex[targetName] or {}
end

function SWGRP.Doors.LinkByTargetName()
	for targetName, doors in pairs( SWGRP.Doors.TargetIndex ) do
		if targetName ~= "" and #doors > 1 then
			for i = 2, #doors do
				SWGRP.Doors.MergeGroups( doors[1], doors[i] )
			end
		end
	end
end

function SWGRP.Doors.LinkByProximity()
	local unlinked = {}
	for _, door in ipairs( SWGRP.Doors.MapDoors ) do
		if IsValid( door ) and not SWGRP.Doors.GetGroupId( door ) then
			table.insert( unlinked, door )
		end
	end

	for i = 1, #unlinked do
		local d1 = unlinked[i]
		if IsValid( d1 ) then
			for j = i + 1, #unlinked do
				local d2 = unlinked[j]
				if IsValid( d2 ) and d1:GetPos():DistToSqr( d2:GetPos() ) <= LINK_DISTANCE * LINK_DISTANCE then
					SWGRP.Doors.MergeGroups( d1, d2 )
				end
			end
		end
	end
end

function SWGRP.Doors.IndexButtons()
	SWGRP.Doors.ButtonLinks = {}

	for cls in pairs( SWGRP.Doors.ButtonClasses ) do
		for _, btn in ipairs( ents.FindByClass( cls ) ) do
			local targetName = SWGRP.Doors.GetHammerTarget( btn )
			local linkedDoors = SWGRP.Doors.FindByTargetName( targetName )

			if #linkedDoors > 0 then
				local ids = {}
				for _, door in ipairs( linkedDoors ) do
					table.insert( ids, SWGRP.Doors.GetID( door ) )
				end
				SWGRP.Doors.ButtonLinks[SWGRP.Doors.GetID( btn )] = ids
			end
		end
	end
end

function SWGRP.Doors.InitializeMap()
	SWGRP.Doors.Data = {}
	SWGRP.Doors.LinkGroups = {}
	SWGRP.Doors.EntToGroup = {}
	SWGRP.Doors.TargetIndex = {}
	SWGRP.Doors.MapDoors = {}

	for class in pairs( SWGRP.Doors.Classes ) do
		for _, ent in ipairs( ents.FindByClass( class ) ) do
			table.insert( SWGRP.Doors.MapDoors, ent )

			local targetName = SWGRP.Doors.GetTargetName( ent )
			if targetName ~= "" then
				SWGRP.Doors.TargetIndex[targetName] = SWGRP.Doors.TargetIndex[targetName] or {}
				table.insert( SWGRP.Doors.TargetIndex[targetName], ent )
			end
		end
	end

	SWGRP.Doors.AssignMapIds()
	SWGRP.Doors.LinkByTargetName()
	SWGRP.Doors.LinkByProximity()
	SWGRP.Doors.IndexButtons()
	SWGRP.Doors.LoadFromDatabase()

	print( string.format( "[SWGRP] Door map init: %d doors, %d link groups, %d buttons indexed.",
		#SWGRP.Doors.MapDoors,
		#SWGRP.Doors.LinkGroups,
		table.Count( SWGRP.Doors.ButtonLinks )
	) )

	-- Let the admin tooling assign stable button ids and load persisted
	-- button ownership / door map configuration after the base map is indexed.
	hook.Run( "SWGRP_DoorsInitialized" )
end

function SWGRP.Doors.IsOwned( ent )
	local d = SWGRP.Doors.GetMasterData( ent )
	if not d then return false end
	if d.groupOnly then return true end
	return d.ownerSteamID ~= nil and d.ownerSteamID ~= ""
end

-- Admin-configured map state (whether players may purchase a given door).
-- Defaults to ownable; the door tool can flag doors as non-purchasable.
SWGRP.Doors.MapConfig = SWGRP.Doors.MapConfig or {}

function SWGRP.Doors.IsOwnable( ent )
	local mapId = SWGRP.Doors.GetSaveMapDoorId( ent )
	if not mapId then return true end
	local cfg = SWGRP.Doors.MapConfig[mapId]
	if cfg and cfg.ownable == false then return false end
	return true
end

function SWGRP.Doors.GetOwner( ent )
	local d = SWGRP.Doors.GetMasterData( ent )
	return d and d.owner
end

function SWGRP.Doors.GetFlag( ent )
	local d = SWGRP.Doors.GetMasterData( ent )
	return d and d.flag or ""
end

function SWGRP.Doors.CanAccess( ply, ent )
	local d = SWGRP.Doors.GetMasterData( ent )
	if not d then return true end

	if IsValid( d.owner ) and d.owner == ply then return true end
	if d.ownerSteamID and d.ownerSteamID == ply:SteamID() then return true end
	if d.coowners and d.coowners[ply:SteamID()] then return true end

	if d.group and d.group ~= "" and SWGRP.Doors.PlayerInGroup( ply, d.group ) then
		return true
	end

	if ply:SWGRP_IsGovernment() and d.allowGovernment ~= false then return true end

	return false
end

function SWGRP.Doors.CanUseButton( ply, btn )
	local links = SWGRP.Doors.ButtonLinks[SWGRP.Doors.GetID( btn )]
	if not links or #links == 0 then return true end

	for _, doorId in ipairs( links ) do
		local door = Entity( doorId )
		if IsValid( door ) then
			local d = SWGRP.Doors.GetMasterData( door )
			if d and d.locked and not SWGRP.Doors.CanAccess( ply, door ) then
				return false
			end
		end
	end

	return true
end

function SWGRP.Doors.ApplyOwnership( ent, data, skipSave )
	SWGRP.Doors.ForEachLinked( ent, function( door )
		SWGRP.Doors.SetData( door, data )
		SWGRP.Doors.Sync( door )
	end )

	if not skipSave then
		SWGRP.Doors.SaveRecord( ent )
	end
end

function SWGRP.Doors.ClearOwnership( ent )
	SWGRP.Doors.DeleteRecord( ent )

	SWGRP.Doors.ForEachLinked( ent, function( door )
		SWGRP.Doors.SetData( door, nil )
		door:Fire( "Unlock" )
		SWGRP.Doors.Sync( door )
	end )
end

-- Managed doors are never given a hard engine lock. The +USE path is handled
-- internally by the engine and bypasses our access hook, so a Fire( "Lock" )
-- would refuse the door for *everyone* - including the owner. Instead we keep
-- the engine door unlocked and enforce access entirely through PlayerUse, which
-- lets owners / co-owners / group members / government open a "locked" door
-- while blocking everyone else. We only Close the door so it visually shuts when
-- it is secured.
function SWGRP.Doors.RefreshEngineLock( door, locked )
	if not IsValid( door ) then return end
	if locked then door:Fire( "Close" ) end
	door:Fire( "UnLock" )
	door:Fire( "Unlock" )
end

function SWGRP.Doors.SetLockState( ent, locked, ply )
	local masterData = SWGRP.Doors.GetMasterData( ent )
	if not masterData then return end

	SWGRP.Doors.ForEachLinked( ent, function( door )
		local d = SWGRP.Doors.GetData( door ) or masterData
		d.locked = locked
		SWGRP.Doors.RefreshEngineLock( door, locked )
		SWGRP.Doors.Sync( door )
	end )

	if IsValid( ply ) then
		SWGRP.Notify( ply, locked and SWGRP.Lang.door_locked or SWGRP.Lang.door_unlocked )
	end

	SWGRP.Doors.SaveRecord( ent )
end

function SWGRP.Doors.Buy( ply, ent )
	if not ent:isDoor() then return end

	local master = SWGRP.Doors.GetMasterDoor( ent )
	if SWGRP.Doors.IsOwned( master ) then
		SWGRP.Notify( ply, "This structure is already owned." )
		return
	end
	if not SWGRP.Doors.IsOwnable( master ) then
		SWGRP.Notify( ply, "This structure cannot be purchased." )
		return
	end
	if ply:SWGRP_GetDoorCount() >= SWGRP.Config.MaxDoors:GetInt() then
		SWGRP.Notify( ply, "Maximum structure limit reached." )
		return
	end

	local cost = SWGRP.Config.DoorCost
	if not ply:SWGRP_TakeCredits( cost ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	local data = SWGRP.Doors.MakeDataFromPlayer( ply )

	SWGRP.Doors.ApplyOwnership( master, data )

	SWGRP.Doors.ForEachLinked( master, function( door )
		SWGRP.Doors.RefreshEngineLock( door, true )
	end )

	SWGRP.Doors.RecalcDoorCount( ply )
	SWGRP.Notify( ply, string.format( SWGRP.Lang.door_bought, SWGRP.FormatCredits( cost ) ) )
	SWGRP.Hooks.Call( "SWGRPPlayerBoughtDoor", ply, master, cost )
end

function SWGRP.Doors.Sell( ply, ent )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d or ( d.owner ~= ply and d.ownerSteamID ~= ply:SteamID() ) then return end

	local refund = math.floor( SWGRP.Config.DoorCost * 0.5 )
	ply:SWGRP_AddCredits( refund )
	SWGRP.Doors.ClearOwnership( master )
	SWGRP.Doors.RecalcDoorCount( ply )
	SWGRP.Notify( ply, string.format( SWGRP.Lang.door_sold, SWGRP.FormatCredits( refund ) ) )
	SWGRP.Hooks.Call( "SWGRPPlayerSoldDoor", ply, master, refund )
end

function SWGRP.Doors.SellAll( ply )
	if not IsValid( ply ) then return 0 end

	-- Collect unique owned structures first; ClearOwnership mutates Doors.Data.
	local masters = {}
	local seen = {}
	for id, d in pairs( SWGRP.Doors.Data ) do
		if d.owner == ply or d.ownerSteamID == ply:SteamID() then
			local ent = Entity( id )
			if IsValid( ent ) then
				local master = SWGRP.Doors.GetMasterDoor( ent )
				local gid = SWGRP.Doors.GetGroupId( master ) or master:EntIndex()
				if not seen[gid] then
					seen[gid] = true
					masters[#masters + 1] = master
				end
			end
		end
	end

	local refundEach = math.floor( SWGRP.Config.DoorCost * 0.5 )
	local sold = 0
	for _, master in ipairs( masters ) do
		if IsValid( master ) then
			ply:SWGRP_AddCredits( refundEach )
			SWGRP.Doors.ClearOwnership( master )
			sold = sold + 1
			SWGRP.Hooks.Call( "SWGRPPlayerSoldDoor", ply, master, refundEach )
		end
	end

	if sold > 0 then
		SWGRP.Doors.RecalcDoorCount( ply )
		SWGRP.Notify( ply, string.format( "Sold %d structure%s for %s.",
			sold, sold == 1 and "" or "s", SWGRP.FormatCredits( refundEach * sold ) ) )
	else
		SWGRP.Notify( ply, "You do not own any structures." )
	end

	return sold
end

function SWGRP.Doors.ToggleLock( ply, ent )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d then return end
	if not SWGRP.Doors.CanAccess( ply, master ) then return end

	SWGRP.Doors.SetLockState( master, not d.locked, ply )
end

function SWGRP.Doors.SetTitle( ply, ent, title )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d or ( d.owner ~= ply and d.ownerSteamID ~= ply:SteamID() ) then return end

	d.title = string.sub( title, 1, 32 )
	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then
			dd.title = d.title
			SWGRP.Doors.Sync( door )
		end
	end )
	SWGRP.Doors.SaveRecord( master )
end

function SWGRP.Doors.SetFlag( ply, ent, flag )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d or ( d.owner ~= ply and d.ownerSteamID ~= ply:SteamID() ) then return end
	if not SWGRP.Doors.IsValidFlag( flag ) then return end

	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then
			dd.flag = flag
			SWGRP.Doors.Sync( door )
		end
	end )
	SWGRP.Doors.SaveRecord( master )

	if IsValid( ply ) then
		SWGRP.Notify( ply, "Structure flag set to: " .. SWGRP.Doors.GetFlagInfo( flag ).label )
	end
end

function SWGRP.Doors.AddCoOwner( ply, ent, target )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d or ( d.owner ~= ply and d.ownerSteamID ~= ply:SteamID() ) then return end
	if not IsValid( target ) then return end

	d.coowners = d.coowners or {}
	d.coowners[target:SteamID()] = true

	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then
			dd.coowners = d.coowners
			SWGRP.Doors.Sync( door )
		end
	end )
	SWGRP.Doors.SaveRecord( master )
end

function SWGRP.Doors.RemoveCoOwner( ply, ent, target )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d or ( d.owner ~= ply and d.ownerSteamID ~= ply:SteamID() ) then return end
	if not IsValid( target ) then return end

	d.coowners = d.coowners or {}
	d.coowners[target:SteamID()] = nil

	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then
			dd.coowners = d.coowners
			SWGRP.Doors.Sync( door )
		end
	end )
	SWGRP.Doors.SaveRecord( master )
end

function SWGRP.Doors.Sync( ent )
	local d = SWGRP.Doors.GetData( ent ) or {}
	local ownerName = d.ownerName or ""
	local ownerJob = d.ownerJob or ""

	if IsValid( d.owner ) then
		ownerName = d.owner:Nick()
		ownerJob = d.owner:SWGRP_GetJobName()
		d.ownerName = ownerName
		d.ownerJob = ownerJob
	end

	local showLabel = SWGRP.Doors.GetMapDoorId( ent ) == SWGRP.Doors.GetSaveMapDoorId( ent )

	net.Start( "SWGRP_UpdateDoor" )
		net.WriteUInt( ent:EntIndex(), 16 )
		net.WriteBool( d.ownerSteamID ~= nil and d.ownerSteamID ~= "" )
		net.WriteString( d.title or "" )
		net.WriteBool( d.locked or false )
		net.WriteString( d.ownerSteamID or "" )
		net.WriteString( ownerName )
		net.WriteString( ownerJob )
		net.WriteBool( showLabel )
		net.WriteString( d.flag or "" )
		if IsValid( d.owner ) then
			net.WriteEntity( d.owner )
		else
			net.WriteEntity( NULL )
		end
		net.WriteBool( d.groupOnly == true )
		net.WriteString( d.groupOnly and SWGRP.Doors.GetGroupLabel( d.group ) or "" )
	net.Broadcast()
end

function SWGRP.Doors.UpdateOwnerJob( ply )
	if not IsValid( ply ) then return end

	for id, d in pairs( SWGRP.Doors.Data ) do
		if d.owner == ply or d.ownerSteamID == ply:SteamID() then
			d.ownerJob = ply:SWGRP_GetJobName()
			local ent = Entity( id )
			if IsValid( ent ) then
				SWGRP.Doors.Sync( ent )
				if SWGRP.Doors.GetMapDoorId( ent ) == SWGRP.Doors.GetSaveMapDoorId( ent ) then
					SWGRP.Doors.SaveRecord( ent )
				end
			end
		end
	end
end

function SWGRP.Doors.SyncAll( ply )
	for id in pairs( SWGRP.Doors.Data ) do
		local ent = Entity( id )
		if IsValid( ent ) then SWGRP.Doors.Sync( ent ) end
	end
end

hook.Add( "PlayerSetTeam", "SWGRP_DoorOwnerJob", function( ply )
	SWGRP.Doors.UpdateOwnerJob( ply )
end )

hook.Add( "InitPostEntity", "SWGRP_DoorMapInit", function()
	timer.Simple( 1, SWGRP.Doors.InitializeMap )
end )

hook.Add( "PostCleanupMap", "SWGRP_DoorMapInit", function()
	timer.Simple( 1, SWGRP.Doors.InitializeMap )
end )

hook.Add( "PlayerInitialSpawn", "SWGRP_DoorSync", function( ply )
	timer.Simple( 2, function()
		if IsValid( ply ) then SWGRP.Doors.SyncAll( ply ) end
	end )
end )

-- Stop doors from opening automatically (proximity triggers, NPCs, logic, etc.).
-- Direct +USE on a door is handled internally by the engine and does not pass
-- through AcceptInput, so this only suppresses scripted/automatic opens. Buttons
-- the gamemode tracks are still allowed to drive their linked doors.
SWGRP.Config.DisableDoorAutoOpen = CreateConVar( "swgrp_doors_disableautoopen", "1",
	FCVAR_ARCHIVE, "Prevent doors from opening automatically (triggers/NPCs)." )

local AUTO_OPEN_INPUTS = {
	open = true,
	toggle = true,
	openawayfrom = true,
}

hook.Add( "AcceptInput", "SWGRP_DoorNoAutoOpen", function( ent, input, activator, caller )
	if not SWGRP.Config.DisableDoorAutoOpen:GetBool() then return end
	if not SWGRP.Doors.Classes[ent:GetClass()] then return end
	if not AUTO_OPEN_INPUTS[string.lower( input )] then return end

	-- Allow opens driven by a button the door system manages.
	if IsValid( caller ) and SWGRP.Doors.IsButton( caller ) then return end

	-- Allow a player directly operating the door (no intermediary entity).
	if IsValid( activator ) and activator:IsPlayer() and not IsValid( caller ) then return end

	-- Block everything else (proximity triggers, NPCs, map logic).
	return true
end )

hook.Add( "PlayerUse", "SWGRP_DoorAccess", function( ply, ent )
	if ent:isDoor() then
		local d = SWGRP.Doors.GetMasterData( ent )
		if d and d.locked and not SWGRP.Doors.CanAccess( ply, ent ) then
			if ( ply.SWGRP_NextLockedFeedback or 0 ) <= CurTime() then
				ply.SWGRP_NextLockedFeedback = CurTime() + 1
				ent:EmitSound( "doors/default_locked.wav", 60, 100 )
			end
			return false
		end
		return
	end

	-- Owned controls (buttons or prop_dynamic): a locked control only operates
	-- for its owner / co-owners / government.
	if SWGRP.Doors.IsButtonOwned and SWGRP.Doors.IsButtonOwned( ent ) then
		local cd = SWGRP.Doors.GetButtonData( ent )
		if cd and cd.locked and not SWGRP.Doors.CanAccessButton( ply, ent ) then
			SWGRP.Notify( ply, "You do not have authority to operate this control." )
			return false
		end
	end

	if SWGRP.Doors.IsButton( ent ) then
		if not SWGRP.Doors.CanUseButton( ply, ent ) then
			SWGRP.Notify( ply, "You do not have authority to operate this control." )
			return false
		end
	end
end )

local KNOCK_SOUNDS = {
	"physics/wood/wood_crate_impact_hard2.wav",
	"physics/wood/wood_crate_impact_hard3.wav",
}

function SWGRP.Doors.Knock( ply, ent )
	if not IsValid( ply ) or not IsValid( ent ) or not ent:isDoor() then return end
	if ( ply.SWGRP_NextKnock or 0 ) > CurTime() then return end
	ply.SWGRP_NextKnock = CurTime() + 1

	local snd = KNOCK_SOUNDS[math.random( #KNOCK_SOUNDS )]
	ent:EmitSound( snd, 90, math.random( 95, 105 ) )

	local d = SWGRP.Doors.GetMasterData( ent )
	if d and IsValid( d.owner ) and d.owner ~= ply then
		SWGRP.Notify( d.owner, "Someone is knocking on your structure." )
	end
end

-- F2: manage the door you are looking at. Unowned -> buy, owned -> open menu.
function GM:ShowTeam( ply )
	if not IsValid( ply ) then return end

	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if not IsValid( ent ) then return end
	if tr.HitPos:DistToSqr( ply:GetShootPos() ) > 150 * 150 then return end

	-- Controls (buttons / prop_dynamic) an admin marked ownable are managed
	-- through the same key.
	if SWGRP.Doors.IsControl( ent ) then
		if SWGRP.Doors.ButtonShowTeam then
			SWGRP.Doors.ButtonShowTeam( ply, ent )
		end
		return
	end

	if not ent:isDoor() then return end

	if not SWGRP.Doors.IsOwned( ent ) then
		SWGRP.Doors.Buy( ply, ent )
		return
	end

	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetMasterData( ent ) or {}
	local isOwner = d.owner == ply or d.ownerSteamID == ply:SteamID()

	net.Start( "SWGRP_DoorMenu" )
		net.WriteEntity( master )
		net.WriteBool( isOwner )
		net.WriteString( d.title or "Structure" )
		net.WriteString( d.ownerName or "Unknown" )
		net.WriteBool( d.locked or false )
		net.WriteString( d.flag or "" )
	net.Send( ply )
end

net.Receive( "SWGRP_DoorAction", function( _, ply )
	local action = net.ReadString()
	local door = net.ReadEntity()
	if not IsValid( ply ) or not IsValid( door ) or not door:isDoor() then return end
	if ply:GetPos():DistToSqr( door:GetPos() ) > 300 * 300 then return end

	if action == "toggle" then
		SWGRP.Doors.ToggleLock( ply, door )
	elseif action == "sell" then
		SWGRP.Doors.Sell( ply, door )
	elseif action == "title" then
		SWGRP.Doors.SetTitle( ply, door, net.ReadString() )
	elseif action == "flag" then
		SWGRP.Doors.SetFlag( ply, door, net.ReadString() )
	elseif action == "addcoowner" then
		local target = net.ReadEntity()
		if IsValid( target ) and target:IsPlayer() then
			SWGRP.Doors.AddCoOwner( ply, door, target )
		end
	elseif action == "removecoowner" then
		local target = net.ReadEntity()
		if IsValid( target ) and target:IsPlayer() then
			SWGRP.Doors.RemoveCoOwner( ply, door, target )
		end
	end
end )

concommand.Add( "swgrp_buydoor", function( ply )
	if not IsValid( ply ) then return end
	local tr = ply:GetEyeTrace()
	if IsValid( tr.Entity ) then SWGRP.Doors.Buy( ply, tr.Entity ) end
end )

concommand.Add( "swgrp_selldoor", function( ply )
	if not IsValid( ply ) then return end
	local tr = ply:GetEyeTrace()
	if IsValid( tr.Entity ) then SWGRP.Doors.Sell( ply, tr.Entity ) end
end )

concommand.Add( "swgrp_sellalldoors", function( ply )
	if not IsValid( ply ) then return end
	SWGRP.Doors.SellAll( ply )
end )

concommand.Add( "swgrp_toggledoor", function( ply )
	if not IsValid( ply ) then return end
	local tr = ply:GetEyeTrace()
	if IsValid( tr.Entity ) then SWGRP.Doors.ToggleLock( ply, tr.Entity ) end
end )

concommand.Add( "swgrp_doormap", function( ply )
	if IsValid( ply ) and not ply:IsAdmin() then return end
	SWGRP.Doors.InitializeMap()
	if IsValid( ply ) then
		ply:ChatPrint( "[SWGRP] Door map re-indexed." )
	end
end )

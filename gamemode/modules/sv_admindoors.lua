--[[---------------------------------------------------------------------------
    Admin Door Tooling & Button Ownership

    Adds two admin in-world configuration tools:
      * swgrp_admin_doortool   - full control of a door map entity
      * swgrp_admin_buttontool - configure / grant ownership of map buttons

    Door map configuration (ownable flag, access group on unowned doors) and
    button ownership are persisted per-map in the swgrp_world key/value table so
    no existing schema is touched.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Doors = SWGRP.Doors or {}

SWGRP.Doors.MapConfig = SWGRP.Doors.MapConfig or {}
SWGRP.Doors.ButtonData = SWGRP.Doors.ButtonData or {}
SWGRP.Doors.ButtonEntToId = SWGRP.Doors.ButtonEntToId or {}
SWGRP.Doors.ButtonIdToEnt = SWGRP.Doors.ButtonIdToEnt or {}

local USE_DISTANCE_SQR = 300 * 300

local function AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

--[[---------------------------------------------------------------------------
    Persistence (per-map, stored as JSON in swgrp_world)
---------------------------------------------------------------------------]]

local function DoorCfgKey()
	return "swgrp_doorcfg_" .. game.GetMap()
end

local function ButtonCfgKey()
	return "swgrp_buttoncfg_" .. game.GetMap()
end

function SWGRP.Doors.SaveMapConfig()
	if not SWGRP.DB or not SWGRP.DB.SetWorld then return end
	local out = {}
	for id, cfg in pairs( SWGRP.Doors.MapConfig ) do
		out[tostring( id )] = {
			ownable = cfg.ownable,
			group = cfg.group,
		}
	end
	SWGRP.DB.SetWorld( DoorCfgKey(), util.TableToJSON( out ) )
end

function SWGRP.Doors.SaveButtonConfig()
	if not SWGRP.DB or not SWGRP.DB.SetWorld then return end
	local out = {}
	for entId, data in pairs( SWGRP.Doors.ButtonData ) do
		local btn = Entity( entId )
		local bid = IsValid( btn ) and SWGRP.Doors.ButtonEntToId[entId]
		if bid then
			out[tostring( bid )] = {
				ownable = data.ownable and true or false,
				owner = data.ownerSteamID or "",
				ownerName = data.ownerName or "",
				ownerJob = data.ownerJob or "",
				coowners = data.coowners or {},
				locked = data.locked and true or false,
			}
		end
	end
	SWGRP.DB.SetWorld( ButtonCfgKey(), util.TableToJSON( out ) )
end

--[[---------------------------------------------------------------------------
    Stable button ids (sorted by position, mirrors door map ids)
---------------------------------------------------------------------------]]

function SWGRP.Doors.AssignButtonIds()
	SWGRP.Doors.ButtonEntToId = {}
	SWGRP.Doors.ButtonIdToEnt = {}

	local buttons = {}
	local function collect( cls )
		for _, btn in ipairs( ents.FindByClass( cls ) ) do
			if IsValid( btn ) then table.insert( buttons, btn ) end
		end
	end
	for cls in pairs( SWGRP.Doors.ButtonClasses ) do collect( cls ) end
	for cls in pairs( SWGRP.Doors.ControlClasses ) do collect( cls ) end

	table.sort( buttons, function( a, b )
		local pa, pb = a:GetPos(), b:GetPos()
		if pa.x ~= pb.x then return pa.x < pb.x end
		if pa.y ~= pb.y then return pa.y < pb.y end
		return pa.z < pb.z
	end )

	for i, btn in ipairs( buttons ) do
		SWGRP.Doors.ButtonEntToId[btn:EntIndex()] = i
		SWGRP.Doors.ButtonIdToEnt[i] = btn
	end
end

--[[---------------------------------------------------------------------------
    Button ownership helpers
---------------------------------------------------------------------------]]

function SWGRP.Doors.GetButtonData( btn )
	if not IsValid( btn ) then return nil end
	return SWGRP.Doors.ButtonData[btn:EntIndex()]
end

function SWGRP.Doors.IsButtonOwned( btn )
	local d = SWGRP.Doors.GetButtonData( btn )
	return d ~= nil and d.ownerSteamID ~= nil and d.ownerSteamID ~= ""
end

function SWGRP.Doors.IsButtonOwnable( btn )
	local d = SWGRP.Doors.GetButtonData( btn )
	return d ~= nil and d.ownable == true
end

function SWGRP.Doors.CanAccessButton( ply, btn )
	local d = SWGRP.Doors.GetButtonData( btn )
	if not d or not d.ownerSteamID or d.ownerSteamID == "" then return true end
	if not IsValid( ply ) then return false end

	if d.ownerSteamID == ply:SteamID() then return true end
	if d.coowners and d.coowners[ply:SteamID()] then return true end
	if ply.SWGRP_IsGovernment and ply:SWGRP_IsGovernment() then return true end

	return false
end

function SWGRP.Doors.SetButtonOwner( btn, ply )
	if not IsValid( btn ) then return end
	local d = SWGRP.Doors.GetButtonData( btn ) or { ownable = true, coowners = {} }

	if IsValid( ply ) then
		d.owner = ply
		d.ownerSteamID = ply:SteamID()
		d.ownerName = ply:Nick()
		d.ownerJob = ply.SWGRP_GetJobName and ply:SWGRP_GetJobName() or ""
		if d.locked == nil then d.locked = true end
	else
		d.owner = nil
		d.ownerSteamID = ""
		d.ownerName = ""
		d.ownerJob = ""
		d.coowners = {}
	end

	d.coowners = d.coowners or {}
	SWGRP.Doors.ButtonData[btn:EntIndex()] = d
	SWGRP.Doors.SaveButtonConfig()
end

function SWGRP.Doors.SetButtonOwnable( btn, ownable )
	if not IsValid( btn ) then return end
	local d = SWGRP.Doors.GetButtonData( btn ) or { coowners = {} }
	d.ownable = ownable and true or false
	d.coowners = d.coowners or {}

	-- Marking a button as non-ownable also relinquishes any current owner.
	if not d.ownable then
		d.owner = nil
		d.ownerSteamID = ""
		d.ownerName = ""
		d.ownerJob = ""
	end

	SWGRP.Doors.ButtonData[btn:EntIndex()] = d
	SWGRP.Doors.SaveButtonConfig()
end

-- Owner / co-owner toggles whether the owned control is locked (restricted).
function SWGRP.Doors.ToggleControlLock( ply, ent )
	if not IsValid( ent ) then return end
	local d = SWGRP.Doors.GetButtonData( ent )
	if not d or not d.ownerSteamID or d.ownerSteamID == "" then return end
	if not SWGRP.Doors.CanAccessButton( ply, ent ) then return end

	d.locked = not d.locked
	SWGRP.Doors.SaveButtonConfig()
	SWGRP.Notify( ply, d.locked and "Control locked." or "Control unlocked." )
end

--[[---------------------------------------------------------------------------
    Player-facing button purchase / management (F2 on an ownable button)
---------------------------------------------------------------------------]]

function SWGRP.Doors.BuyButton( ply, btn )
	if not IsValid( ply ) or not IsValid( btn ) then return end
	if not SWGRP.Doors.IsButtonOwnable( btn ) then
		SWGRP.Notify( ply, "This control cannot be owned." )
		return
	end
	if SWGRP.Doors.IsButtonOwned( btn ) then
		SWGRP.Notify( ply, "This control is already owned." )
		return
	end

	local cost = SWGRP.Config.DoorCost
	if not ply:SWGRP_TakeCredits( cost ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end

	SWGRP.Doors.SetButtonOwner( btn, ply )
	SWGRP.Notify( ply, "Control claimed for " .. SWGRP.FormatCredits( cost ) .. "." )
end

function SWGRP.Doors.SellButton( ply, btn )
	if not IsValid( ply ) or not IsValid( btn ) then return end
	local d = SWGRP.Doors.GetButtonData( btn )
	if not d or d.ownerSteamID ~= ply:SteamID() then return end

	local refund = math.floor( SWGRP.Config.DoorCost * 0.5 )
	ply:SWGRP_AddCredits( refund )
	SWGRP.Doors.SetButtonOwner( btn, nil )
	SWGRP.Notify( ply, "Control released for " .. SWGRP.FormatCredits( refund ) .. "." )
end

function SWGRP.Doors.ButtonShowTeam( ply, btn )
	if not IsValid( ply ) or not IsValid( btn ) then return end

	-- Only ownable buttons engage the ownership flow; everything else is inert.
	if not SWGRP.Doors.IsButtonOwnable( btn ) and not SWGRP.Doors.IsButtonOwned( btn ) then
		return
	end

	if not SWGRP.Doors.IsButtonOwned( btn ) then
		SWGRP.Doors.BuyButton( ply, btn )
		return
	end

	local d = SWGRP.Doors.GetButtonData( btn )
	if d and d.ownerSteamID == ply:SteamID() then
		SWGRP.Doors.SellButton( ply, btn )
	else
		SWGRP.Notify( ply, "This control is owned by " .. ( ( d and d.ownerName ) or "another colonist" ) .. "." )
	end
end

--[[---------------------------------------------------------------------------
    Admin door control
---------------------------------------------------------------------------]]

function SWGRP.Doors.AdminSetOwnable( ent, ownable )
	local mapId = SWGRP.Doors.GetSaveMapDoorId( ent )
	if not mapId then return end

	local cfg = SWGRP.Doors.MapConfig[mapId] or {}
	cfg.ownable = ownable and true or false
	SWGRP.Doors.MapConfig[mapId] = cfg
	SWGRP.Doors.SaveMapConfig()
end

function SWGRP.Doors.AdminForceOwner( ent, target )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	if not IsValid( master ) then return end

	if IsValid( target ) then
		local data = SWGRP.Doors.MakeDataFromPlayer( target )
		SWGRP.Doors.ApplyOwnership( master, data )
		SWGRP.Doors.ForEachLinked( master, function( door )
			SWGRP.Doors.RefreshEngineLock( door, true )
		end )
		SWGRP.Doors.RecalcDoorCount( target )
	else
		SWGRP.Doors.AdminClearOwner( master )
	end
end

function SWGRP.Doors.AdminClearOwner( ent )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	if not IsValid( master ) then return end

	local prevOwner = SWGRP.Doors.GetOwner( master )

	-- Drop any persisted access-group configuration for this door as well.
	local mapId = SWGRP.Doors.GetSaveMapDoorId( master )
	if mapId and SWGRP.Doors.MapConfig[mapId] then
		SWGRP.Doors.MapConfig[mapId].group = nil
		SWGRP.Doors.SaveMapConfig()
	end

	SWGRP.Doors.ClearOwnership( master )

	if IsValid( prevOwner ) then
		SWGRP.Doors.RecalcDoorCount( prevOwner )
	end
end

function SWGRP.Doors.AdminSetGroup( ent, group )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	if not IsValid( master ) then return end

	group = group or ""
	local mapId = SWGRP.Doors.GetSaveMapDoorId( master )
	local d = SWGRP.Doors.GetData( master )

	if group == "" then
		-- Clearing a group: remove a group-only record entirely, otherwise just
		-- strip the group assignment from a player-owned door.
		if d and d.groupOnly then
			SWGRP.Doors.AdminClearOwner( master )
		elseif d then
			SWGRP.Doors.ForEachLinked( master, function( door )
				local dd = SWGRP.Doors.GetData( door )
				if dd then dd.group = nil SWGRP.Doors.Sync( door ) end
			end )
			SWGRP.Doors.SaveRecord( master )
		end
		if mapId and SWGRP.Doors.MapConfig[mapId] then
			SWGRP.Doors.MapConfig[mapId].group = nil
			SWGRP.Doors.SaveMapConfig()
		end
		return
	end

	if d and not d.groupOnly then
		-- Player-owned door: assign the group on top of player ownership.
		SWGRP.Doors.ForEachLinked( master, function( door )
			local dd = SWGRP.Doors.GetData( door )
			if dd then dd.group = group SWGRP.Doors.Sync( door ) end
		end )
		SWGRP.Doors.SaveRecord( master )
		return
	end

	-- No player owner: create / update a group-controlled record.
	local label = SWGRP.Doors.GetGroupLabel( group )
	local data = {
		owner = nil,
		ownerSteamID = "",
		ownerName = label,
		ownerJob = "Faction Access",
		title = label,
		locked = true,
		coowners = {},
		group = group,
		groupOnly = true,
	}
	SWGRP.Doors.ApplyOwnership( master, data, true )
	SWGRP.Doors.ForEachLinked( master, function( door )
		SWGRP.Doors.RefreshEngineLock( door, true )
	end )

	if mapId then
		local cfg = SWGRP.Doors.MapConfig[mapId] or {}
		cfg.group = group
		SWGRP.Doors.MapConfig[mapId] = cfg
		SWGRP.Doors.SaveMapConfig()
	end
end

function SWGRP.Doors.AdminSetLock( ent, locked )
	local d = SWGRP.Doors.GetMasterData( ent )
	if not d then return end
	SWGRP.Doors.SetLockState( SWGRP.Doors.GetMasterDoor( ent ), locked )
end

function SWGRP.Doors.AdminSetTitle( ent, title )
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d then return end

	d.title = string.sub( title or "", 1, 32 )
	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then dd.title = d.title SWGRP.Doors.Sync( door ) end
	end )
	SWGRP.Doors.SaveRecord( master )
end

function SWGRP.Doors.AdminSetFlag( ent, flag )
	if not SWGRP.Doors.IsValidFlag( flag ) then return end
	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetData( master )
	if not d then return end

	SWGRP.Doors.ForEachLinked( master, function( door )
		local dd = SWGRP.Doors.GetData( door )
		if dd then dd.flag = flag SWGRP.Doors.Sync( door ) end
	end )
	SWGRP.Doors.SaveRecord( master )
end

--[[---------------------------------------------------------------------------
    Load persisted configuration after the door map is indexed
---------------------------------------------------------------------------]]

local function LoadMapConfig()
	SWGRP.Doors.MapConfig = {}
	if not SWGRP.DB or not SWGRP.DB.GetWorld then return end

	local raw = SWGRP.DB.GetWorld( DoorCfgKey(), "" )
	local tbl = ( raw and raw ~= "" ) and util.JSONToTable( raw ) or nil
	if not tbl then return end

	for idStr, cfg in pairs( tbl ) do
		local id = tonumber( idStr )
		if id then
			SWGRP.Doors.MapConfig[id] = {
				ownable = cfg.ownable,
				group = cfg.group,
			}

			-- Recreate group-controlled doors that have no player owner.
			if cfg.group and cfg.group ~= "" then
				local door = SWGRP.Doors.IdToEnt[id]
				if IsValid( door ) and not SWGRP.Doors.GetMasterData( door ) then
					SWGRP.Doors.AdminSetGroup( door, cfg.group )
				end
			end
		end
	end
end

local function LoadButtonConfig()
	SWGRP.Doors.ButtonData = {}
	if not SWGRP.DB or not SWGRP.DB.GetWorld then return end

	local raw = SWGRP.DB.GetWorld( ButtonCfgKey(), "" )
	local tbl = ( raw and raw ~= "" ) and util.JSONToTable( raw ) or nil
	if not tbl then return end

	for idStr, data in pairs( tbl ) do
		local id = tonumber( idStr )
		local btn = id and SWGRP.Doors.ButtonIdToEnt[id]
		if IsValid( btn ) then
			local owner = player.GetBySteamID( data.owner or "" )
			SWGRP.Doors.ButtonData[btn:EntIndex()] = {
				ownable = data.ownable and true or false,
				owner = IsValid( owner ) and owner or nil,
				ownerSteamID = data.owner or "",
				ownerName = data.ownerName or "",
				ownerJob = data.ownerJob or "",
				coowners = data.coowners or {},
				locked = data.locked and true or false,
			}
		end
	end
end

-- Broadcast which doors players cannot purchase so the client suppresses the
-- "purchasable" overlay on them. Group-controlled doors already arrive via the
-- door sync (groupOnly) and don't need to be listed here.
function SWGRP.Doors.SyncNoBuy( ply )
	local ids = {}
	for mapId, cfg in pairs( SWGRP.Doors.MapConfig ) do
		if cfg.ownable == false then
			local master = SWGRP.Doors.IdToEnt[mapId]
			if IsValid( master ) then
				SWGRP.Doors.ForEachLinked( master, function( door )
					ids[#ids + 1] = door:EntIndex()
				end )
			end
		end
	end

	net.Start( "SWGRP_DoorNoBuy" )
		net.WriteUInt( #ids, 16 )
		for _, id in ipairs( ids ) do
			net.WriteUInt( id, 16 )
		end
	if IsValid( ply ) then net.Send( ply ) else net.Broadcast() end
end

hook.Add( "SWGRP_DoorsInitialized", "SWGRP_AdminDoorsLoad", function()
	SWGRP.Doors.AssignButtonIds()
	LoadMapConfig()
	LoadButtonConfig()
	timer.Simple( 0, function() SWGRP.Doors.SyncNoBuy() end )
end )

-- Re-resolve button owner entities when a previously-owning player connects.
hook.Add( "PlayerInitialSpawn", "SWGRP_ButtonOwnerResolve", function( ply )
	timer.Simple( 2, function()
		if not IsValid( ply ) then return end
		local sid = ply:SteamID()
		for _, data in pairs( SWGRP.Doors.ButtonData ) do
			if data.ownerSteamID == sid then
				data.owner = ply
				data.ownerName = ply:Nick()
			end
		end
		SWGRP.Doors.SyncNoBuy( ply )
	end )
end )

--[[---------------------------------------------------------------------------
    Networking: open menus (triggered by the SWEPs) and apply actions
---------------------------------------------------------------------------]]

function SWGRP.Doors.SendAdminDoorMenu( ply, ent )
	if not AdminAllowed( ply ) or not IsValid( ent ) or not ent:isDoor() then return end

	local master = SWGRP.Doors.GetMasterDoor( ent )
	local d = SWGRP.Doors.GetMasterData( master ) or {}
	local mapId = SWGRP.Doors.GetSaveMapDoorId( master )
	local cfg = mapId and SWGRP.Doors.MapConfig[mapId] or {}

	net.Start( "SWGRP_AdminDoorMenu" )
		net.WriteEntity( master )
		net.WriteString( d.title or "" )
		net.WriteString( d.groupOnly and "" or ( d.ownerName or "" ) )
		net.WriteBool( d.locked or false )
		net.WriteBool( cfg.ownable ~= false )
		net.WriteString( d.group or "" )
		net.WriteString( d.flag or "" )
	net.Send( ply )
end

function SWGRP.Doors.SendAdminButtonMenu( ply, btn )
	if not AdminAllowed( ply ) or not IsValid( btn ) or not SWGRP.Doors.IsControl( btn ) then return end

	local d = SWGRP.Doors.GetButtonData( btn ) or {}

	net.Start( "SWGRP_AdminButtonMenu" )
		net.WriteEntity( btn )
		net.WriteString( btn:GetClass() )
		net.WriteBool( d.ownable == true )
		net.WriteString( d.ownerName or "" )
		net.WriteBool( d.locked == true )
	net.Send( ply )
end

net.Receive( "SWGRP_AdminDoorAction", function( _, ply )
	if not AdminAllowed( ply ) then return end

	local door = net.ReadEntity()
	local action = net.ReadString()
	if not IsValid( door ) or not door:isDoor() then return end
	if ply:GetPos():DistToSqr( door:GetPos() ) > USE_DISTANCE_SQR then return end

	if action == "lock" then
		SWGRP.Doors.AdminSetLock( door, true )
	elseif action == "unlock" then
		SWGRP.Doors.AdminSetLock( door, false )
	elseif action == "title" then
		SWGRP.Doors.AdminSetTitle( door, net.ReadString() )
	elseif action == "flag" then
		SWGRP.Doors.AdminSetFlag( door, net.ReadString() )
	elseif action == "group" then
		SWGRP.Doors.AdminSetGroup( door, net.ReadString() )
	elseif action == "ownable" then
		SWGRP.Doors.AdminSetOwnable( door, net.ReadBool() )
	elseif action == "setowner" then
		local target = net.ReadEntity()
		if IsValid( target ) and target:IsPlayer() then
			SWGRP.Doors.AdminForceOwner( door, target )
		end
	elseif action == "clearowner" then
		SWGRP.Doors.AdminClearOwner( door )
	end

	-- Echo the refreshed state so the open menu reflects the change.
	SWGRP.Doors.SendAdminDoorMenu( ply, door )
	SWGRP.Doors.SyncNoBuy()
end )

net.Receive( "SWGRP_AdminButtonAction", function( _, ply )
	if not AdminAllowed( ply ) then return end

	local btn = net.ReadEntity()
	local action = net.ReadString()
	if not IsValid( btn ) or not SWGRP.Doors.IsControl( btn ) then return end
	if ply:GetPos():DistToSqr( btn:GetPos() ) > USE_DISTANCE_SQR then return end

	if action == "ownable" then
		SWGRP.Doors.SetButtonOwnable( btn, net.ReadBool() )
	elseif action == "setowner" then
		local target = net.ReadEntity()
		if IsValid( target ) and target:IsPlayer() then
			SWGRP.Doors.SetButtonOwner( btn, target )
		end
	elseif action == "clearowner" then
		SWGRP.Doors.SetButtonOwner( btn, nil )
	elseif action == "togglelock" then
		local d = SWGRP.Doors.GetButtonData( btn )
		if d then
			d.locked = not d.locked
			SWGRP.Doors.ButtonData[btn:EntIndex()] = d
			SWGRP.Doors.SaveButtonConfig()
		end
	end

	SWGRP.Doors.SendAdminButtonMenu( ply, btn )
end )

--[[---------------------------------------------------------------------------
    SWEP entry points (called server-side from the tools' PrimaryAttack)
---------------------------------------------------------------------------]]

local TOOL_REACH = 256

-- A focused trace from the player's eyes. GetEyeTrace can be stale between
-- ticks for fast inputs, so we run a fresh ray each time.
local function ToolTrace( ply )
	return util.TraceLine( {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * TOOL_REACH,
		filter = ply,
	} )
end

function SWGRP.Doors.AdminDoorToolUse( ply )
	if not IsValid( ply ) then return end
	if not AdminAllowed( ply ) then
		SWGRP.Notify( ply, "Door tool: admins only." )
		return
	end

	local tr = ToolTrace( ply )
	local ent = tr.Entity
	if not IsValid( ent ) then
		SWGRP.Notify( ply, "Door tool: aim closer at a door." )
		return
	end
	if not ent:isDoor() then
		SWGRP.Notify( ply, "Door tool: '" .. ent:GetClass() .. "' is not a door." )
		return
	end

	SWGRP.Doors.SendAdminDoorMenu( ply, ent )
end

function SWGRP.Doors.AdminButtonToolUse( ply )
	if not IsValid( ply ) then return end
	if not AdminAllowed( ply ) then
		SWGRP.Notify( ply, "Button tool: admins only." )
		return
	end

	local tr = ToolTrace( ply )
	local ent = tr.Entity
	if not IsValid( ent ) then
		SWGRP.Notify( ply, "Control tool: aim closer at a button or prop." )
		return
	end
	if not SWGRP.Doors.IsControl( ent ) then
		SWGRP.Notify( ply, "Control tool: '" .. ent:GetClass() .. "' cannot be made an ownable control." )
		return
	end

	SWGRP.Doors.SendAdminButtonMenu( ply, ent )
end

-- Console fallbacks so the tools can be tested / bound even if the SWEP
-- input is being swallowed. Aim at the target and run the command.
concommand.Add( "swgrp_doortool", function( ply )
	SWGRP.Doors.AdminDoorToolUse( ply )
end )

concommand.Add( "swgrp_buttontool", function( ply )
	SWGRP.Doors.AdminButtonToolUse( ply )
end )

print( "[SWGRP] Admin door/button tools loaded." )

--[[---------------------------------------------------------------------------
    Client Door Data Sync & 3D2D Structure Labels
---------------------------------------------------------------------------]]

SWGRP.Doors = SWGRP.Doors or {}
SWGRP.Doors.ClientData = SWGRP.Doors.ClientData or {}
SWGRP.Doors.NoBuy = SWGRP.Doors.NoBuy or {}

local UI = SWGRP.UI or {}

local function DoorColors()
	if UI.SyncColors then UI.SyncColors() end
	return {
		primary   = UI.Colors and UI.Colors.primary or SWGRP.Config.HUDColorPrimary,
		secondary = UI.Colors and UI.Colors.secondary or SWGRP.Config.HUDColorSecondary,
		accent    = UI.Colors and UI.Colors.accent or SWGRP.Config.HUDColorAccent,
		danger    = UI.Colors and UI.Colors.danger or SWGRP.Config.HUDColorDanger,
		bg        = UI.Colors and UI.Colors.bg or Color( 10, 15, 25 ),
		border    = UI.Colors and UI.Colors.border or Color( 255, 180, 50, 200 ),
	}
end

function SWGRP.Doors.GetClientData( ent )
	if not IsValid( ent ) then return end
	return SWGRP.Doors.ClientData[ent:EntIndex()]
end

net.Receive( "SWGRP_UpdateDoor", function()
	local id = net.ReadUInt( 16 )
	local owned = net.ReadBool()
	local title = net.ReadString()
	local locked = net.ReadBool()
	local ownerSteamID = net.ReadString()
	local ownerName = net.ReadString()
	local ownerJob = net.ReadString()
	local showLabel = net.ReadBool()
	local flag = net.ReadString()
	local owner = net.ReadEntity()
	local groupControlled = net.ReadBool()
	local groupLabel = net.ReadString()

	if owned or groupControlled then
		SWGRP.Doors.ClientData[id] = {
			owned = owned,
			groupControlled = groupControlled,
			group = groupLabel,
			title = title,
			locked = locked,
			ownerSteamID = ownerSteamID,
			ownerName = ownerName,
			ownerJob = ownerJob,
			owner = owner,
			showLabel = showLabel,
			flag = flag,
		}
	else
		SWGRP.Doors.ClientData[id] = nil
	end
end )

net.Receive( "SWGRP_DoorNoBuy", function()
	local set = {}
	local count = net.ReadUInt( 16 )
	for _ = 1, count do
		set[net.ReadUInt( 16 )] = true
	end
	SWGRP.Doors.NoBuy = set
end )

-- Draw a plate that is fitted to the door's face and sits flush on both sides
-- so it never gets buried inside the door mesh. The plate content is authored in
-- a virtual w x h canvas; this function scales it to the door's extents.
--
-- The door's facing direction is derived from its actual oriented bounding box
-- (the thinnest axis is the face normal), so the plate orients correctly
-- regardless of how the door entity itself is rotated.
local function DrawDoorPlate( door, w, h, paint )
	local mins, maxs = door:OBBMins(), door:OBBMaxs()
	local size = maxs - mins
	local center = door:LocalToWorld( ( mins + maxs ) * 0.5 )

	local function worldAxis( v )
		return ( door:LocalToWorld( v ) - door:GetPos() ):GetNormalized()
	end

	local axes = {
		{ len = math.abs( size.x ), dir = worldAxis( Vector( 1, 0, 0 ) ) },
		{ len = math.abs( size.y ), dir = worldAxis( Vector( 0, 1, 0 ) ) },
		{ len = math.abs( size.z ), dir = worldAxis( Vector( 0, 0, 1 ) ) },
	}

	-- Thinnest axis = the face normal; the other two are the visible face.
	table.sort( axes, function( a, b ) return a.len < b.len end )
	local normalAxis, faceA, faceB = axes[1], axes[2], axes[3]

	-- Of the two face axes, the one most aligned with world up is the height.
	local up = Vector( 0, 0, 1 )
	local heightAxis, widthAxis
	if math.abs( faceA.dir:Dot( up ) ) >= math.abs( faceB.dir:Dot( up ) ) then
		heightAxis, widthAxis = faceA, faceB
	else
		heightAxis, widthAxis = faceB, faceA
	end

	local halfThick  = normalAxis.len * 0.5
	local doorWidth  = widthAxis.len
	local doorHeight = heightAxis.len

	-- Facing direction comes from the real (thin-axis) normal rather than the
	-- entity yaw, so doors whose thin axis isn't local-X still sit on the face
	-- instead of bleeding onto the inner frame.
	local yaw = normalAxis.dir:Angle().y

	-- Fit the canvas inside the face with a margin, preserving aspect ratio.
	local scale = math.min( ( doorWidth * 0.9 ) / w, ( doorHeight * 0.8 ) / h )
	scale = math.Clamp( scale, 0.005, 0.12 )

	-- Render on both faces. This angle construction keeps the text upright; only
	-- the yaw/thickness inputs are derived from the OBB.
	for _, side in ipairs( { 0, 180 } ) do
		local drawAng = Angle( 0, yaw + side, 90 )
		drawAng:RotateAroundAxis( drawAng:Right(), 90 )

		local pos = center + drawAng:Up() * ( halfThick + 0.5 )

		cam.Start3D2D( pos, drawAng, scale )
			paint( w, h )
		cam.End3D2D()
	end
end

local function DrawDoorSign( door, data )
	local colors = DoorColors()
	local hasFlag = data.flag and data.flag ~= "" and SWGRP.Doors.IsValidFlag( data.flag )
	local flagInfo = hasFlag and SWGRP.Doors.GetFlagInfo( data.flag ) or nil
	local w, h = 260, hasFlag and 144 or 118

	DrawDoorPlate( door, w, h, function()
		surface.SetDrawColor( colors.bg.r, colors.bg.g, colors.bg.b, 220 )
		surface.DrawRect( -w / 2, -h / 2, w, h )

		surface.SetDrawColor( colors.border )
		surface.DrawOutlinedRect( -w / 2, -h / 2, w, h, 2 )

		surface.SetDrawColor( colors.primary.r, colors.primary.g, colors.primary.b, 40 )
		surface.DrawRect( -w / 2, -h / 2, w, 24 )

		local title = UI.TruncateText and UI.TruncateText( data.title or "Property", "DermaDefaultBold", w - 24 ) or ( data.title or "Structure" )
		local owner = UI.TruncateText and UI.TruncateText( data.ownerName or "Unknown", "DermaDefault", w - 24 ) or ( data.ownerName or "Unknown" )
		local job = UI.TruncateText and UI.TruncateText( data.ownerJob or "Colonist", "DermaDefault", w - 24 ) or ( data.ownerJob or "Colonist" )

		draw.SimpleText( title, "DermaDefaultBold", 0, -42, colors.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( owner, "DermaDefault", 0, -14, colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( job, "DermaDefault", 0, 10, colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		if data.locked then
			draw.SimpleText( "LOCKED", "DermaDefaultBold", 0, 38, colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end

		if hasFlag then
			local bw, bh, by = 150, 20, 75
			surface.SetDrawColor( flagInfo.color.r, flagInfo.color.g, flagInfo.color.b, 55 )
			surface.DrawRect( -bw / 2, by, bw, bh )
			surface.SetDrawColor( flagInfo.color )
			surface.DrawOutlinedRect( -bw / 2, by, bw, bh, 1 )
			draw.SimpleText( "[ " .. flagInfo.label .. " ]", "DermaDefaultBold", 0, by + bh / 2, flagInfo.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end )
end

local function DrawUnownedSign( door )
	local colors = DoorColors()
	local w, h = 260, 78
	local cost = SWGRP.Config and SWGRP.Config.DoorCost or 100

	DrawDoorPlate( door, w, h, function()
		surface.SetDrawColor( colors.bg.r, colors.bg.g, colors.bg.b, 200 )
		surface.DrawRect( -w / 2, -h / 2, w, h )

		surface.SetDrawColor( colors.borderDim or colors.border )
		surface.DrawOutlinedRect( -w / 2, -h / 2, w, h, 2 )

		draw.SimpleText( "Unowned Property", "DermaDefaultBold", 0, -18, colors.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Purchasable - " .. SWGRP.FormatCredits( cost ), "DermaDefault", 0, 6, colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Press [F2] to purchase/manage", "DermaDefault", 0, 26, colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end )
end

local function DrawGroupSign( door, data )
	local colors = DoorColors()
	local w, h = 260, 96

	DrawDoorPlate( door, w, h, function()
		surface.SetDrawColor( colors.bg.r, colors.bg.g, colors.bg.b, 220 )
		surface.DrawRect( -w / 2, -h / 2, w, h )

		surface.SetDrawColor( colors.border )
		surface.DrawOutlinedRect( -w / 2, -h / 2, w, h, 2 )

		surface.SetDrawColor( colors.accent.r, colors.accent.g, colors.accent.b, 40 )
		surface.DrawRect( -w / 2, -h / 2, w, 24 )

		local group = UI.TruncateText and UI.TruncateText( data.group or "Faction", "DermaDefaultBold", w - 24 ) or ( data.group or "Faction" )

		draw.SimpleText( group, "DermaDefaultBold", 0, -26, colors.primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Faction Access Only", "DermaDefault", 0, 2, colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		if data.locked then
			draw.SimpleText( "LOCKED", "DermaDefaultBold", 0, 28, colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end )
end

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_DoorLabels", function( depth, skybox )
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local eyePos = ply:EyePos()
	local drawDist = 900 * 900

	-- Owned / faction structures: persistent plate on the master door.
	for id, data in pairs( SWGRP.Doors.ClientData ) do
		if data.showLabel then
			local door = Entity( id )
			if IsValid( door ) and door:isDoor() then
				if door:GetPos():DistToSqr( eyePos ) <= drawDist then
					if data.owned then
						DrawDoorSign( door, data )
					elseif data.groupControlled then
						DrawGroupSign( door, data )
					end
				end
			end
		end
	end

	-- Unowned door the player is currently looking at gets a purchasable plate,
	-- unless the door is owned, faction-controlled, or flagged non-purchasable.
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if IsValid( ent ) and ent:isDoor() and tr.HitPos:DistToSqr( eyePos ) < 40000 then
		local data = SWGRP.Doors.ClientData[ent:EntIndex()]
		local restricted = SWGRP.Doors.NoBuy[ent:EntIndex()]
		if not ( data and ( data.owned or data.groupControlled ) ) and not restricted then
			DrawUnownedSign( ent )
		end
	end
end )

--[[---------------------------------------------------------------------------
    F2 structure management menu
---------------------------------------------------------------------------]]

local function SendDoorAction( door, action, extra )
	if not IsValid( door ) then return end
	net.Start( "SWGRP_DoorAction" )
		net.WriteString( action )
		net.WriteEntity( door )
		if action == "title" or action == "flag" then
			net.WriteString( extra or "" )
		elseif action == "addcoowner" or action == "removecoowner" then
			net.WriteEntity( extra )
		end
	net.SendToServer()
end

function SWGRP.Doors.OpenManageMenu( door, isOwner, title, ownerName, locked, flag )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end
	if not IsValid( door ) then return end

	if IsValid( SWGRP.Doors.Menu ) then
		SWGRP.Doors.Menu:Remove()
	end

	local height = isOwner and 460 or 190
	local frame = UI.CreateTerminalFrame( "STRUCTURE", 320, height )
	SWGRP.Doors.Menu = frame

	-- Scroll the contents so the lower owner actions can never clip off-frame.
	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	local function label( text, font, color )
		local l = UI.CreateLabel( body, text, font, color, TOP )
		if IsValid( l ) then l:DockMargin( 0, 0, 0, UI.Spacing.gap ) end
		return l
	end

	local flagInfo = SWGRP.Doors.GetFlagInfo( flag or "" )

	label( title or "Property", "DermaDefaultBold", UI.Colors.primary )
	label( "Owner: " .. ( ownerName or "Unknown" ), "DermaDefault", UI.Colors.secondary )
	label( "Status: " .. ( locked and "Locked" or "Unlocked" ), "DermaDefault", locked and UI.Colors.danger or UI.Colors.accent )
	label( "Flag: " .. flagInfo.label, "DermaDefault", flagInfo.color )

	local function actionButton( text, onClick )
		local btn = UI.CreateButton( body, text, onClick )
		if not IsValid( btn ) then return end
		btn:Dock( TOP )
		btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		return btn
	end

	actionButton( locked and "Unlock" or "Lock", function()
		SendDoorAction( door, "toggle" )
		frame:Close()
	end )

	if not isOwner then return end

	local entry = vgui.Create( "DTextEntry", body )
	entry:Dock( TOP )
	entry:DockMargin( 0, 0, 0, UI.Spacing.gap )
	entry:SetText( title or "" )
	UI.StyleTextEntry( entry )

	actionButton( "Set Title", function()
		SendDoorAction( door, "title", entry:GetValue() )
		frame:Close()
	end )

	actionButton( "Add Co-Owner", function()
		local menu = DermaMenu()
		for _, p in ipairs( player.GetAll() ) do
			if p ~= LocalPlayer() then
				menu:AddOption( p:Nick(), function()
					SendDoorAction( door, "addcoowner", p )
				end )
			end
		end
		menu:Open()
	end )

	actionButton( "Remove Co-Owner", function()
		local menu = DermaMenu()
		for _, p in ipairs( player.GetAll() ) do
			if p ~= LocalPlayer() then
				menu:AddOption( p:Nick(), function()
					SendDoorAction( door, "removecoowner", p )
				end )
			end
		end
		menu:Open()
	end )

	actionButton( "Property Flag: " .. flagInfo.label, function()
		local menu = DermaMenu()
		for _, f in ipairs( SWGRP.Doors.Flags ) do
			menu:AddOption( f.label, function()
				SendDoorAction( door, "flag", f.id )
				frame:Close()
			end )
		end
		menu:Open()
	end )

	actionButton( "Sell Property", function()
		SendDoorAction( door, "sell" )
		frame:Close()
	end )
end

net.Receive( "SWGRP_DoorMenu", function()
	local door = net.ReadEntity()
	local isOwner = net.ReadBool()
	local title = net.ReadString()
	local ownerName = net.ReadString()
	local locked = net.ReadBool()
	local flag = net.ReadString()

	SWGRP.Doors.OpenManageMenu( door, isOwner, title, ownerName, locked, flag )
end )

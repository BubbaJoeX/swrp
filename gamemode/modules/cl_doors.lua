--[[---------------------------------------------------------------------------
    Client Door Data Sync & 3D2D Structure Labels
---------------------------------------------------------------------------]]

SWGRP.Doors = SWGRP.Doors or {}
SWGRP.Doors.ClientData = SWGRP.Doors.ClientData or {}

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

	if owned then
		SWGRP.Doors.ClientData[id] = {
			owned = true,
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

-- Draw a plate that is fitted to the door's face and sits flush on both sides
-- so it never gets buried inside the door mesh. The plate content is authored in
-- a virtual w x h canvas; this function scales it to the door's extents.
local function DrawDoorPlate( door, w, h, paint )
	local mins, maxs = door:OBBMins(), door:OBBMaxs()
	local size = maxs - mins
	local center = door:LocalToWorld( ( mins + maxs ) * 0.5 )
	local yaw = door:GetAngles().y

	-- Door local axes: x = facing/thickness, y = width, z = height.
	local doorWidth  = math.abs( size.y )
	local doorHeight = math.abs( size.z )
	local halfThick  = math.abs( size.x ) * 0.5

	-- Fit the canvas inside the face with a margin, preserving aspect ratio.
	local scale = math.min( ( doorWidth * 0.9 ) / w, ( doorHeight * 0.8 ) / h )
	scale = math.Clamp( scale, 0.005, 0.12 )

	-- Render on both faces, each pushed just clear of the mesh along its own normal.
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

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_DoorLabels", function( depth, skybox )
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local eyePos = ply:EyePos()
	local drawDist = 900 * 900

	-- Owned structures: persistent plate on the master door.
	for id, data in pairs( SWGRP.Doors.ClientData ) do
		if data.owned and data.showLabel then
			local door = Entity( id )
			if IsValid( door ) and door:isDoor() then
				if door:GetPos():DistToSqr( eyePos ) <= drawDist then
					DrawDoorSign( door, data )
				end
			end
		end
	end

	-- Unowned door the player is currently looking at gets a purchasable plate.
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if IsValid( ent ) and ent:isDoor() and tr.HitPos:DistToSqr( eyePos ) < 40000 then
		local data = SWGRP.Doors.ClientData[ent:EntIndex()]
		if not ( data and data.owned ) then
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

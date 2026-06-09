--[[---------------------------------------------------------------------------
    Admin Door / Button Tool - client configuration menus
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Doors = SWGRP.Doors or {}

local function SendDoorAdmin( door, action, writer )
	if not IsValid( door ) then return end
	net.Start( "SWGRP_AdminDoorAction" )
		net.WriteEntity( door )
		net.WriteString( action )
		if writer then writer() end
	net.SendToServer()
end

local function SendButtonAdmin( btn, action, writer )
	if not IsValid( btn ) then return end
	net.Start( "SWGRP_AdminButtonAction" )
		net.WriteEntity( btn )
		net.WriteString( action )
		if writer then writer() end
	net.SendToServer()
end


--[[---------------------------------------------------------------------------
    Door configuration menu
---------------------------------------------------------------------------]]

local function OpenAdminDoorMenu( door, title, ownerName, locked, ownable, group, flag )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame or not IsValid( door ) then return end

	if IsValid( SWGRP.Doors.AdminMenu ) then SWGRP.Doors.AdminMenu:Remove() end

	local frame = UI.CreateTerminalFrame( "DOOR ADMIN", 340, 520 )
	SWGRP.Doors.AdminMenu = frame

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

	local function actionButton( text, onClick )
		local btn = UI.CreateButton( body, text, onClick )
		if not IsValid( btn ) then return end
		btn:Dock( TOP )
		btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		return btn
	end

	local flagInfo = SWGRP.Doors.GetFlagInfo( flag or "" )
	local groupLabel = SWGRP.Doors.GetGroupLabel( group or "" )
	local hasGroup = group and group ~= ""
	local ownerLabel = ( ownerName and ownerName ~= "" ) and ownerName or ( hasGroup and ( "Group: " .. groupLabel ) or "Unowned" )

	label( title ~= "" and title or "Door", "DermaDefaultBold", UI.Colors.primary )
	label( "Owner: " .. ownerLabel, "DermaDefault", UI.Colors.secondary )
	label( "Status: " .. ( locked and "Locked" or "Unlocked" ), "DermaDefault", locked and UI.Colors.danger or UI.Colors.accent )
	label( "Group: " .. ( hasGroup and groupLabel or "None" ), "DermaDefault", UI.Colors.secondary )
	label( "Flag: " .. flagInfo.label, "DermaDefault", flagInfo.color )
	label( "Purchasable: " .. ( ownable and "Yes" or "No" ), "DermaDefault", ownable and UI.Colors.accent or UI.Colors.danger )

	actionButton( locked and "Force Unlock" or "Force Lock", function()
		SendDoorAdmin( door, locked and "unlock" or "lock" )
	end )

	local entry = vgui.Create( "DTextEntry", body )
	entry:Dock( TOP )
	entry:DockMargin( 0, 0, 0, UI.Spacing.gap )
	entry:SetText( title or "" )
	UI.StyleTextEntry( entry )

	actionButton( "Set Title", function()
		SendDoorAdmin( door, "title", function() net.WriteString( entry:GetValue() ) end )
	end )

	actionButton( "Access Group: " .. ( hasGroup and groupLabel or "None" ), function()
		local menu = DermaMenu()
		menu:AddOption( "None", function()
			SendDoorAdmin( door, "group", function() net.WriteString( "" ) end )
		end )
		for _, g in ipairs( SWGRP.Doors.GetGroupList() ) do
			menu:AddOption( g.label, function()
				SendDoorAdmin( door, "group", function() net.WriteString( g.key ) end )
			end )
		end
		menu:Open()
	end )

	actionButton( "Property Flag: " .. flagInfo.label, function()
		local menu = DermaMenu()
		for _, f in ipairs( SWGRP.Doors.Flags ) do
			menu:AddOption( f.label, function()
				SendDoorAdmin( door, "flag", function() net.WriteString( f.id ) end )
			end )
		end
		menu:Open()
	end )

	actionButton( ownable and "Make Non-Purchasable" or "Make Purchasable", function()
		SendDoorAdmin( door, "ownable", function() net.WriteBool( not ownable ) end )
	end )

	actionButton( "Set Owner", function()
		local menu = DermaMenu()
		for _, p in ipairs( player.GetAll() ) do
			menu:AddOption( p:Nick(), function()
				SendDoorAdmin( door, "setowner", function() net.WriteEntity( p ) end )
			end )
		end
		menu:Open()
	end )

	actionButton( "Clear Owner", function()
		SendDoorAdmin( door, "clearowner" )
	end )
end

net.Receive( "SWGRP_AdminDoorMenu", function()
	local door = net.ReadEntity()
	local title = net.ReadString()
	local ownerName = net.ReadString()
	local locked = net.ReadBool()
	local ownable = net.ReadBool()
	local group = net.ReadString()
	local flag = net.ReadString()

	OpenAdminDoorMenu( door, title, ownerName, locked, ownable, group, flag )
end )

--[[---------------------------------------------------------------------------
    Button configuration menu
---------------------------------------------------------------------------]]

local function OpenAdminButtonMenu( btn, class, ownable, ownerName, locked )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame or not IsValid( btn ) then return end

	if IsValid( SWGRP.Doors.AdminMenu ) then SWGRP.Doors.AdminMenu:Remove() end

	local frame = UI.CreateTerminalFrame( "CONTROL ADMIN", 340, 340 )
	SWGRP.Doors.AdminMenu = frame

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

	local function actionButton( text, onClick )
		local b = UI.CreateButton( body, text, onClick )
		if not IsValid( b ) then return end
		b:Dock( TOP )
		b:DockMargin( 0, 0, 0, UI.Spacing.gap )
		return b
	end

	local isOwned = ownerName and ownerName ~= ""

	label( "Map Control", "DermaDefaultBold", UI.Colors.primary )
	label( "Class: " .. ( class or "?" ), "DermaDefault", UI.Colors.secondary )
	label( "Owner: " .. ( isOwned and ownerName or "Unowned" ), "DermaDefault", UI.Colors.secondary )
	label( "Ownable: " .. ( ownable and "Yes" or "No" ), "DermaDefault", ownable and UI.Colors.accent or UI.Colors.danger )
	if isOwned then
		label( "Status: " .. ( locked and "Locked" or "Unlocked" ), "DermaDefault", locked and UI.Colors.danger or UI.Colors.accent )
	end

	actionButton( ownable and "Disable Ownership" or "Enable Ownership", function()
		SendButtonAdmin( btn, "ownable", function() net.WriteBool( not ownable ) end )
	end )

	if isOwned then
		actionButton( locked and "Force Unlock" or "Force Lock", function()
			SendButtonAdmin( btn, "togglelock" )
		end )
	end

	actionButton( "Set Owner", function()
		local menu = DermaMenu()
		for _, p in ipairs( player.GetAll() ) do
			menu:AddOption( p:Nick(), function()
				SendButtonAdmin( btn, "setowner", function() net.WriteEntity( p ) end )
			end )
		end
		menu:Open()
	end )

	actionButton( "Clear Owner", function()
		SendButtonAdmin( btn, "clearowner" )
	end )
end

net.Receive( "SWGRP_AdminButtonMenu", function()
	local btn = net.ReadEntity()
	local class = net.ReadString()
	local ownable = net.ReadBool()
	local ownerName = net.ReadString()
	local locked = net.ReadBool()

	OpenAdminButtonMenu( btn, class, ownable, ownerName, locked )
end )

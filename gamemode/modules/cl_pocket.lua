--[[---------------------------------------------------------------------------
    Pocket - client item list + retrieval menu
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Pocket = SWGRP.Pocket or {}
SWGRP.Pocket.Items = SWGRP.Pocket.Items or {}

net.Receive( "SWGRP_PocketSync", function()
	local count = net.ReadUInt( 8 )
	SWGRP.Pocket.Items = {}
	for i = 1, count do
		SWGRP.Pocket.Items[i] = net.ReadString()
	end

	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.RebuildMenu()
	end
end )

local function prettyName( class )
	local wep = weapons.Get( class )
	if wep and wep.PrintName and wep.PrintName ~= "" then
		return wep.PrintName
	end
	return class
end

function SWGRP.Pocket.RebuildMenu()
	local list = SWGRP.Pocket.MenuList
	if not IsValid( list ) then return end
	list:Clear()

	if #SWGRP.Pocket.Items == 0 then
		if IsValid( SWGRP.Pocket.Menu ) then SWGRP.Pocket.Menu:Close() end
		return
	end

	for i, class in ipairs( SWGRP.Pocket.Items ) do
		local btn = SWGRP.UI.AddListButton( list, prettyName( class ), class, function()
			net.Start( "SWGRP_PocketDrop" )
				net.WriteUInt( i, 8 )
			net.SendToServer()
			if IsValid( SWGRP.Pocket.Menu ) then SWGRP.Pocket.Menu:Close() end
		end )
	end
end

function SWGRP.Pocket.OpenMenu()
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.Menu:Remove()
	end

	local frame = UI.CreateTerminalFrame( "POCKET", 320, 360 )
	SWGRP.Pocket.Menu = frame

	local scroll = vgui.Create( "DScrollPanel", frame )
	scroll:Dock( FILL )
	scroll:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	UI.StyleScrollPanel( scroll )

	SWGRP.Pocket.MenuList = scroll
	SWGRP.Pocket.RebuildMenu()
end

net.Receive( "SWGRP_PocketOpen", function()
	SWGRP.Pocket.OpenMenu()
end )

concommand.Add( "swgrp_pocket_menu", SWGRP.Pocket.OpenMenu )

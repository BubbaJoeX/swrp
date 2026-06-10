--[[---------------------------------------------------------------------------
    Mount Offset Tool - client menu and ENT.MountOffsets export
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MountOffset = SWGRP.MountOffset or {}

local MO = SWGRP.MountOffset
MO.Client = MO.Client or { offsets = {}, mainName = "none", parentFrozen = false }

local menuKeyFrame = -1
local clearKeyFrame = -1

local function fmtNum( n )
	n = tonumber( n ) or 0
	if math.abs( n - math.Round( n ) ) < 0.0005 then
		return string.format( "%d", math.Round( n ) )
	end
	return string.format( "%.4f", n ):gsub( "%.?0+$", "" )
end

function MO.FormatVector( pos )
	return string.format( "Vector( %s, %s, %s )", fmtNum( pos.x ), fmtNum( pos.y ), fmtNum( pos.z ) )
end

function MO.FormatAngle( ang )
	return string.format( "Angle( %s, %s, %s )", fmtNum( ang.p ), fmtNum( ang.y ), fmtNum( ang.r ) )
end

function MO.BuildMountOffsetsLua( offsets )
	offsets = offsets or MO.Client.offsets or {}

	local lines = { "ENT.MountOffsets = {" }
	for _, entry in ipairs( offsets ) do
		local pos = entry.pos or entry
		local ang = entry.ang or Angle( 0, 0, 0 )
		table.insert( lines, string.format(
			"\t{ pos = %s, ang = %s },",
			MO.FormatVector( pos ),
			MO.FormatAngle( ang )
		) )
	end
	table.insert( lines, "}" )
	return table.concat( lines, "\n" )
end

local function HasMountTool()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return false end
	local wep = ply:GetActiveWeapon()
	return IsValid( wep ) and wep:GetClass() == "swgrp_admin_mountoffset"
end

local function ToolInputBlocked()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return true end
	if gui.IsConsoleVisible() or gui.IsGameUIVisible() or ply:IsTyping() then return true end
	if IsValid( g_SpawnMenu ) and g_SpawnMenu:IsVisible() then return true end
	if IsValid( g_ContextMenu ) and g_ContextMenu:IsVisible() then return true end
	return false
end

local function SendAction( action )
	net.Start( "SWGRP_MountOffsetAction" )
		net.WriteString( action )
	net.SendToServer()
end

local function refreshOutput( output )
	if not IsValid( output ) then return end
	output:SetText( MO.BuildMountOffsetsLua( MO.Client.offsets ) )
end

function MO.CloseMenu()
	if IsValid( MO.Menu ) then
		MO.Menu:Remove()
	end
	MO.Menu = nil
end

function MO.OpenMenu()
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then
		chat.AddText( Color( 255, 180, 50 ), "[SWGRP] ", color_white, "Mount offset UI failed to load. Reconnect or reload the gamemode." )
		return
	end

	if IsValid( MO.Menu ) then
		MO.Menu:MakePopup()
		MO.Menu:Center()
		MO.RefreshSlotFields()
		return
	end

	UI.SyncColors()

	local frame = UI.CreateTerminalFrame( "MOUNT OFFSETS", 420, 640 )
	MO.Menu = frame

	frame.OnRemove = function()
		if MO.Menu == frame then
			MO.Menu = nil
		end
	end

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
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

	MO.ParentLabel = label(
		"Parent: " .. ( MO.Client.mainName or "none" ),
		"DermaDefaultBold",
		UI.Colors.primary
	)

	MO.FrozenLabel = label(
		MO.Client.parentFrozen and "Parent: frozen north (+X)" or "Parent: not frozen — Reload to lock north",
		"DermaDefault",
		UI.Colors.secondary
	)

	label(
		"M — toggle this menu · Del — clear all offsets",
		"DermaDefaultBold",
		UI.Colors.accent
	)

	label(
		"RMB parent · Reload freeze north · LMB capture face (model sits on surface)",
		"DermaDefault",
		UI.Colors.secondary
	)

	actionButton( "Set parent (trace)", function() SendAction( "setmain" ) end )
	actionButton( "Freeze parent north (+X)", function() SendAction( "freezenorth" ) end )
	actionButton( "Capture click point (trace)", function() SendAction( "capture" ) end )
	actionButton( "Remove last offset", function() SendAction( "remove" ) end )
	actionButton( "Clear all offsets", function() SendAction( "clear" ) end )

	label( "Captured slots (local pos / ang)", "DermaDefaultBold", UI.Colors.accent )

	MO.SlotHost = vgui.Create( "DPanel", body )
	MO.SlotHost:Dock( TOP )
	MO.SlotHost:DockMargin( 0, 0, 0, UI.Spacing.gap )
	MO.SlotHost.Paint = function() end

	label( "ENT.MountOffsets export", "DermaDefaultBold", UI.Colors.primary )

	local output = vgui.Create( "DTextEntry", body )
	output:Dock( TOP )
	output:SetMultiline( true )
	output:SetTall( 140 )
	output:DockMargin( 0, 0, 0, UI.Spacing.gap )
	output:SetFont( "DermaDefault" )
	if UI.StyleTextEntry then UI.StyleTextEntry( output ) end
	MO.OutputEntry = output
	refreshOutput( output )

	actionButton( "Copy to clipboard", function()
		SetClipboardText( output:GetText() )
		if SWGRP.Notify then
			SWGRP.Notify( nil, "MountOffsets copied to clipboard." )
		end
	end )

	MO.RefreshSlotFields()
end

function MO.ToggleMenu()
	if IsValid( MO.Menu ) then
		MO.CloseMenu()
	else
		MO.OpenMenu()
	end
end

function MO.RefreshSlotFields()
	if not IsValid( MO.SlotHost ) then return end

	for _, child in ipairs( MO.SlotHost:GetChildren() ) do
		child:Remove()
	end

	local UI = SWGRP.UI
	local offsets = MO.Client.offsets or {}

	for i, entry in ipairs( offsets ) do
		local row = vgui.Create( "DPanel", MO.SlotHost )
		row:Dock( TOP )
		row:DockMargin( 0, 0, 0, UI.Spacing.gap )
		row:SetTall( 52 )
		row.Paint = function( self, w, h )
			surface.SetDrawColor( UI.Colors.bgLight )
			surface.DrawRect( 0, 0, w, h )
		end

		local title = UI.CreateLabel( row, "Slot " .. i, "DermaDefaultBold", UI.Colors.secondary, LEFT )
		if IsValid( title ) then
			title:Dock( LEFT )
			title:SetWide( 48 )
			title:DockMargin( 6, 0, 0, 0 )
		end

		local pos = entry.pos or {}
		local ang = entry.ang or {}
		local text = string.format(
			"pos %s, %s, %s  ·  ang %s, %s, %s",
			fmtNum( pos.x ), fmtNum( pos.y ), fmtNum( pos.z ),
			fmtNum( ang.p ), fmtNum( ang.y ), fmtNum( ang.r )
		)

		local detail = UI.CreateLabel( row, text, "DermaDefault", UI.Colors.primary, LEFT )
		if IsValid( detail ) then
			detail:Dock( FILL )
			detail:DockMargin( 4, 0, 6, 0 )
		end
	end

	if IsValid( MO.OutputEntry ) then
		refreshOutput( MO.OutputEntry )
	end

	if IsValid( MO.ParentLabel ) then
		MO.ParentLabel:SetText( "Parent: " .. ( MO.Client.mainName or "none" ) )
	end

	if IsValid( MO.FrozenLabel ) then
		MO.FrozenLabel:SetText(
			MO.Client.parentFrozen and "Parent: frozen north (+X)" or "Parent: not frozen — Reload to lock north"
		)
	end
end

net.Receive( "SWGRP_MountOffsetSync", function()
	local mainId = net.ReadUInt( 16 )
	local mainClass = net.ReadString()
	local parentFrozen = net.ReadBool()
	local count = net.ReadUInt( 8 )

	MO.Client.offsets = {}
	for _ = 1, count do
		table.insert( MO.Client.offsets, {
			pos = Vector( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ),
			ang = Angle( net.ReadFloat(), net.ReadFloat(), net.ReadFloat() ),
		} )
	end

	MO.Client.parentFrozen = parentFrozen

	if mainId > 0 then
		MO.Client.mainName = mainClass .. " #" .. mainId
	else
		MO.Client.mainName = "none"
	end

	MO.RefreshSlotFields()
end )

net.Receive( "SWGRP_MountOffsetMenu", function()
	MO.OpenMenu()
end )

hook.Add( "Think", "SWGRP_MountOffsetKeys", function()
	if not HasMountTool() or ToolInputBlocked() then return end

	local frame = FrameNumber()

	if input.WasKeyPressed( KEY_M ) and menuKeyFrame ~= frame then
		menuKeyFrame = frame
		MO.ToggleMenu()
	end

	if input.WasKeyPressed( KEY_DELETE ) and clearKeyFrame ~= frame then
		clearKeyFrame = frame
		SendAction( "clear" )
	end
end )

concommand.Add( "swgrp_mountoffset_menu", function()
	MO.ToggleMenu()
end )

concommand.Add( "swgrp_mountoffset_clear", function()
	if not HasMountTool() then return end
	SendAction( "clear" )
end )

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_MountOffsetPreview", function( _, skybox )
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid( wep ) or wep:GetClass() ~= "swgrp_admin_mountoffset" then return end

	local mainId = tonumber( string.match( MO.Client.mainName or "", "#(%d+)$" ) )
	if not mainId then return end

	local main = Entity( mainId )
	if not IsValid( main ) then return end

	local origin = main:GetPos()
	local ax = main:GetForward() * 48
	local ay = main:GetRight() * 48
	local az = main:GetUp() * 48

	local northCol = MO.Client.parentFrozen and Color( 255, 180, 50 ) or Color( 255, 80, 80 )
	render.DrawLine( origin, origin + ax, northCol, true )
	render.DrawLine( origin, origin + ay, Color( 80, 255, 80 ), true )
	render.DrawLine( origin, origin + az, Color( 80, 160, 255 ), true )

	if MO.Client.parentFrozen then
		render.DrawLine( origin, origin + Vector( 64, 0, 0 ), Color( 255, 220, 100, 180 ), true )
	end

	for _, entry in ipairs( MO.Client.offsets or {} ) do
		local pos = main:LocalToWorld( entry.pos )
		local ang = main:LocalToWorldAngles( entry.ang )
		render.DrawWireframeBox( pos, ang, Vector( -6, -6, 0 ), Vector( 6, 6, 10 ), Color( 255, 180, 50 ), true )
		render.DrawLine( pos, pos + ang:Up() * 20, Color( 120, 255, 160 ), true )
	end

	local tr = util.TraceLine( {
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 2048,
		filter = ply,
	} )

	if tr.Hit then
		local previewAng = MO.WorldAnglesOnSurface( tr.HitNormal )
		render.DrawWireframeBox( tr.HitPos, previewAng, Vector( -6, -6, 0 ), Vector( 6, 6, 10 ), Color( 80, 255, 120, 180 ), true )
		render.DrawLine( tr.HitPos, tr.HitPos + tr.HitNormal * 28, Color( 255, 255, 120 ), true )
		render.DrawLine( tr.HitPos, tr.HitPos + previewAng:Up() * 22, Color( 120, 255, 160 ), true )
	end
end )

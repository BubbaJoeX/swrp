--[[---------------------------------------------------------------------------
    Map Atmosphere Adjuster - client menu and fog rendering
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MapAdjust = SWGRP.MapAdjust or {}

local MA = SWGRP.MapAdjust
MA.Client = MA.Client or {}

local function SendSet( field, value )
	net.Start( "SWGRP_MapAdjustAction" )
		net.WriteString( "set" )
		net.WriteString( field )
		net.WriteString( tostring( value ) )
	net.SendToServer()
end

function MA.ApplyClient()
	local s = MA.Client
	if not s then return end

	if s.fogEnabled then
		render.FogMode( MATERIAL_FOG_LINEAR )
		render.FogStart( s.fogStart or 0 )
		render.FogEnd( s.fogEnd or 8000 )
		render.FogColor( s.fogR or 180, s.fogG or 200, s.fogB or 220 )
		render.FogMaxDensity( 1 )
	else
		render.FogMode( MATERIAL_FOG_NONE )
	end
end

function MA.OpenMenu()
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( MA.Menu ) then MA.Menu:Remove() end

	local s = MA.Client or {}

	local frame = UI.CreateTerminalFrame( "MAP ATMOSPHERE", 360, 520 )
	MA.Menu = frame

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	local function slider( label, min, max, val, onChange )
		local row = vgui.Create( "DPanel", body )
		row:Dock( TOP )
		row:DockMargin( 0, 0, 0, UI.Spacing.gap )
		row:SetTall( 44 )
		row.Paint = function() end

		local lbl = UI.CreateLabel( row, label, "DermaDefault", UI.Colors.secondary, LEFT )
		if IsValid( lbl ) then
			lbl:Dock( LEFT )
			lbl:SetWide( 120 )
		end

		local sl = vgui.Create( "DNumSlider", row )
		sl:Dock( FILL )
		sl:SetMin( min )
		sl:SetMax( max )
		sl:SetDecimals( 0 )
		sl:SetValue( val )
		sl.OnValueChanged = function( _, v )
			onChange( math.Round( v ) )
		end
	end

	local fogToggle = vgui.Create( "DCheckBoxLabel", body )
	fogToggle:Dock( TOP )
	fogToggle:DockMargin( 0, 0, 0, UI.Spacing.gap )
	fogToggle:SetText( "Fog enabled" )
	fogToggle:SetValue( s.fogEnabled and 1 or 0 )
	fogToggle.OnChange = function( _, val )
		SendSet( "fogEnabled", val and "1" or "0" )
	end

	slider( "Fog start", 0, 10000, s.fogStart or 0, function( v ) SendSet( "fogStart", v ) end )
	slider( "Fog end", 500, 20000, s.fogEnd or 8000, function( v ) SendSet( "fogEnd", v ) end )
	slider( "Fog R", 0, 255, s.fogR or 180, function( v ) SendSet( "fogR", v ) end )
	slider( "Fog G", 0, 255, s.fogG or 200, function( v ) SendSet( "fogG", v ) end )
	slider( "Fog B", 0, 255, s.fogB or 220, function( v ) SendSet( "fogB", v ) end )
	slider( "Ambient R", 0, 255, s.ambientR or 40, function( v ) SendSet( "ambientR", v ) end )
	slider( "Ambient G", 0, 255, s.ambientG or 40, function( v ) SendSet( "ambientG", v ) end )
	slider( "Ambient B", 0, 255, s.ambientB or 50, function( v ) SendSet( "ambientB", v ) end )

	local resetBtn = UI.CreateButton( body, "Reset Defaults", function()
		SendSet( "reset", "1" )
	end )
	if IsValid( resetBtn ) then
		resetBtn:Dock( TOP )
		resetBtn:DockMargin( 0, UI.Spacing.gap, 0, 0 )
	end
end

net.Receive( "SWGRP_MapAdjustMenu", function()
	MA.OpenMenu()
end )

net.Receive( "SWGRP_MapAdjustSync", function()
	MA.Client = {
		fogEnabled = net.ReadBool(),
		fogStart = net.ReadFloat(),
		fogEnd = net.ReadFloat(),
		fogR = net.ReadUInt( 8 ),
		fogG = net.ReadUInt( 8 ),
		fogB = net.ReadUInt( 8 ),
		ambientR = net.ReadUInt( 8 ),
		ambientG = net.ReadUInt( 8 ),
		ambientB = net.ReadUInt( 8 ),
	}
end )

hook.Add( "SetupWorldFog", "SWGRP_MapAdjustFogClient", function()
	if MA.Client then
		MA.ApplyClient()
		return true
	end
end )

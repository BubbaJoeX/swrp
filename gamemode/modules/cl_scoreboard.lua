--[[---------------------------------------------------------------------------
    Custom Scoreboard (disabled when bundled FAdmin scoreboard is active)
---------------------------------------------------------------------------]]

if FAdmin and FAdmin.ScoreBoard then return end

local UI = SWGRP.UI

local function PaintPlayerRow( ply, w, h )
	if not IsValid( ply ) then return end

	UI.SyncColors()

	local col = team.GetColor( ply:Team() )
	if ply:SWGRP_IsWanted() then
		col = UI.Colors.danger
	elseif ply:SWGRP_IsAFK() then
		col = Color( 100, 100, 100 )
	end

	surface.SetDrawColor( UI.Colors.bgLight )
	surface.DrawRect( 2, 2, w - 4, h - 4 )

	surface.SetDrawColor( col.r, col.g, col.b, 50 )
	surface.DrawRect( w - 8, 2, 6, h - 4 )

	draw.SimpleText( ply:Nick(), "DermaDefaultBold", 14, 18, UI.Colors.primary, TEXT_ALIGN_LEFT )
	draw.SimpleText( ply:SWGRP_GetJobName(), "DermaDefault", 14, 40, UI.Colors.accent, TEXT_ALIGN_LEFT )
	draw.SimpleText( SWGRP.FormatCredits( ply:SWGRP_GetCredits() ), "DermaDefault", 220, 28, UI.Colors.secondary, TEXT_ALIGN_LEFT )

	if ply:SWGRP_IsWanted() then
		draw.SimpleText( "WANTED", "DermaDefaultBold", w - 90, 28, UI.Colors.danger, TEXT_ALIGN_LEFT )
	end
	draw.SimpleText( ply:Ping() .. "ms", "DermaDefault", w - 14, 28, Color( 150, 150, 150 ), TEXT_ALIGN_RIGHT )
end

hook.Add( "ScoreboardShow", "SWGRP_Scoreboard", function()
	if IsValid( SWGRP.Scoreboard ) then return end

	local scrW, scrH = ScrW(), ScrH()
	local frame = UI.CreateTerminalFrame( "GALACTIC CENSUS", scrW * 0.5, scrH * 0.6 )
	frame:SetDraggable( false )
	frame:ShowCloseButton( false )
	SWGRP.Scoreboard = frame

	if IsValid( frame.btnClose ) then
		frame.btnClose:SetVisible( false )
	end

	local scroll = vgui.Create( "DScrollPanel", frame )
	scroll:Dock( FILL )
	scroll:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	UI.StyleScrollPanel( scroll )

	for _, ply in ipairs( player.GetAll() ) do
		local row = vgui.Create( "DPanel", scroll )
		row:SetTall( UI.Spacing.listItem )
		row:Dock( TOP )
		row:DockMargin( 0, 0, 0, UI.Spacing.gap )
		row.Paint = function( self, w, h )
			PaintPlayerRow( ply, w, h )
		end
	end
end )

hook.Add( "ScoreboardHide", "SWGRP_Scoreboard", function()
	if IsValid( SWGRP.Scoreboard ) then
		SWGRP.Scoreboard:Remove()
	end
end )

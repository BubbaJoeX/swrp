--[[---------------------------------------------------------------------------
    Energy panel — bottom-right HUD to load purchased cells into your blaster
    Buy cells from F4 → Ammunition tab.
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.AmmoHUD = SWGRP.AmmoHUD or {}

local AH = SWGRP.AmmoHUD
local BTN_H = 22
local PANEL_PAD = 12
local BAR_H = 8

hook.Add( "InitPostEntity", "SWGRP_ClientPatchWeaponAmmo", function()
	SWGRP.Ammo.PatchWeaponTables()
	timer.Simple( 5, function()
		SWGRP.Ammo.PatchWeaponTables()
	end )
end )

hook.Add( "WeaponEquip", "SWGRP_ClientRegisterEnergyWeapon", function( wep )
	SWGRP.Ammo.RegisterEnergyWeapon( wep )
end )

local function hudBlocked()
	if SWGRP.UI and SWGRP.UI.IsTerminalOpen and SWGRP.UI.IsTerminalOpen() then return true end
	return false
end

local function pointInRect( mx, my, rect )
	return mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h
end

local function drawButton( HUD, rect, text, enabled, hovered, accent, secondary )
	local bg = enabled and ( hovered and Color( accent.r, accent.g, accent.b, 90 ) or Color( 0, 0, 0, 170 ) )
		or Color( 0, 0, 0, 110 )
	draw.RoundedBox( 4, rect.x, rect.y, rect.w, rect.h, bg )
	surface.SetDrawColor( enabled and accent or secondary )
	surface.DrawOutlinedRect( rect.x, rect.y, rect.w, rect.h, 1 )
	local col = enabled and Color( 245, 245, 245 ) or Color( 140, 140, 140 )
	HUD.TextShadow( text, "SWGRP_HUD_Small", rect.x + rect.w / 2, rect.y + rect.h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

hook.Add( "HUDPaint", "SWGRP_AmmoHUD", function()
	if hudBlocked() then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then
		AH.Layout = nil
		return
	end

	local state = SWGRP.Ammo.GetHUDState( ply )
	if not state then
		AH.Layout = nil
		return
	end

	local UI = SWGRP.UI
	if not UI or not UI.HUD then return end

	local HUD = UI.HUD
	HUD.Sync()

	local scrW, scrH = ScrW(), ScrH()
	local pw = 220
	local ph = state.weapon and ( 130 + PANEL_PAD ) or ( 98 + PANEL_PAD )
	local px = scrW - pw - 18
	local py = scrH - ph - 18
	local mx, my = gui.MousePos()

	local primary = UI.Colors.primary
	local secondary = UI.Colors.secondary
	local accent = UI.Colors.accent
	local danger = UI.Colors.danger or Color( 255, 60, 60 )
	local perCell = state.roundsPerCell

	AH.Layout = {
		x = px,
		y = py,
		w = pw,
		h = ph,
		loadBtn = nil,
	}

	HUD.DrawPanel( px, py, pw, ph, 215 )
	HUD.DrawHeader( px, py, pw, "ENERGY" )

	local cy = py + 30

	if state.weapon then
		local w = state.weapon
		local clipText = w.maxClip > 0
			and string.format( "CLIP  %d / %d", w.clip, w.maxClip )
			or string.format( "CLIP  %d", w.clip )
		HUD.TextShadow( clipText, "SWGRP_HUD_Body", px + 12, cy, primary, TEXT_ALIGN_LEFT )
		cy = cy + 16

		HUD.TextShadow(
			string.format( "RESERVE  %d", w.reserve ),
			"SWGRP_HUD_Small",
			px + 12,
			cy,
			secondary,
			TEXT_ALIGN_LEFT
		)
		cy = cy + 14

		local meterLabel = string.format( "AMMO  %d rnd", w.totalAvailable )
		local meterCol = w.outOfAmmo and danger or accent
		if w.outOfAmmo then
			meterLabel = "AMMO  OUT"
		end
		HUD.TextShadow( meterLabel, "SWGRP_HUD_Small", px + 12, cy, meterCol, TEXT_ALIGN_LEFT )
		cy = cy + 12

		local barW = pw - 24
		local barFill = w.outOfAmmo and danger or meterCol
		HUD.DrawStatBar( px + 12, cy, barW, BAR_H, w.meterFrac, barFill, "" )
		cy = cy + BAR_H + 10
	else
		HUD.TextShadow( "Equip a blaster to load cells.", "SWGRP_HUD_Small", px + 12, cy, secondary, TEXT_ALIGN_LEFT )
		cy = cy + 28
	end

	local cellRounds = state.cells * perCell
	HUD.TextShadow(
		string.format( "CELLS  %d  (%d rnd)", state.cells, cellRounds ),
		"SWGRP_HUD_Small",
		px + 12,
		cy,
		accent,
		TEXT_ALIGN_LEFT
	)
	cy = cy + 16

	local loadRect = { x = px + 12, y = cy, w = pw - 24, h = BTN_H }
	local loadHovered = pointInRect( mx, my, loadRect )
	local loadLabel = state.canLoad
		and string.format( "LOAD CELL  (+%d rnd)", perCell )
		or ( state.cells > 0 and "LOAD CELL" or "NO CELLS — BUY IN F4" )

	drawButton( HUD, loadRect, loadLabel, state.canLoad, loadHovered, accent, secondary )
	AH.Layout.loadBtn = loadRect
end )

hook.Add( "PlayerButtonDown", "SWGRP_AmmoHUDClick", function( ply, button )
	if button ~= MOUSE_LEFT or ply ~= LocalPlayer() then return end
	if hudBlocked() or gui.IsConsoleVisible() or gui.IsGameUIVisible() then return end

	local layout = AH.Layout
	if not layout or not layout.loadBtn then return end

	local mx, my = gui.MousePos()
	if not pointInRect( mx, my, layout ) then return end

	if pointInRect( mx, my, layout.loadBtn ) then
		net.Start( "SWGRP_UseEnergyCell" )
		net.SendToServer()
	end
end )

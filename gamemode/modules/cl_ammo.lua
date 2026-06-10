--[[---------------------------------------------------------------------------
    Energy panel — bottom-right HUD (buy cells in F4, press R to load)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.AmmoHUD = SWGRP.AmmoHUD or {}

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

hook.Add( "HUDPaint", "SWGRP_AmmoHUD", function()
	if hudBlocked() then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then return end

	local state = SWGRP.Ammo.GetHUDState( ply )
	if not state then return end

	local UI = SWGRP.UI
	if not UI or not UI.HUD then return end

	local HUD = UI.HUD
	HUD.Sync()

	local scrW, scrH = ScrW(), ScrH()
	local pw = 220
	local ph = state.weapon and 118 or 88
	local px = scrW - pw - 18
	local py = scrH - ph - 18

	local primary = UI.Colors.primary
	local secondary = UI.Colors.secondary
	local accent = UI.Colors.accent
	local danger = UI.Colors.danger or Color( 255, 60, 60 )
	local perCell = state.roundsPerCell

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
		HUD.DrawStatBar( px + 12, cy, barW, 8, w.meterFrac, barFill, "" )
		cy = cy + 18
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
	cy = cy + 14

	local hintCol = state.canLoad and secondary or Color( 140, 140, 140 )
	local hint = state.canLoad
		and string.format( "R — load cell (+%d rnd)", perCell )
		or ( state.cells > 0 and "R — load cell" or "NO CELLS — BUY IN F4" )
	HUD.TextShadow( hint, "SWGRP_HUD_Small", px + 12, cy, hintCol, TEXT_ALIGN_LEFT )
end )

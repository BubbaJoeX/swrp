--[[---------------------------------------------------------------------------
    SWGRP HUD - SWG Terminal Aesthetic
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.HUD = SWGRP.HUD or {}

local hideHUD = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
}

hook.Add( "HUDShouldDraw", "SWGRP_HideDefaultHUD", function( name )
	if hideHUD[name] then return false end
end )

local function DrawBox( x, y, w, h, col, alpha )
	surface.SetDrawColor( col.r, col.g, col.b, alpha or 180 )
	surface.DrawRect( x, y, w, h )
	surface.SetDrawColor( SWGRP.Config.HUDColorPrimary.r, SWGRP.Config.HUDColorPrimary.g, SWGRP.Config.HUDColorPrimary.b, 200 )
	surface.DrawOutlinedRect( x, y, w, h )
end

local function DrawTextShadow( text, font, x, y, col, ax, ay )
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 150 ), ax, ay )
	draw.SimpleText( text, font, x, y, col, ax, ay )
end

-- Labelled status bar (health/armor/hunger). frac is 0..1.
local function DrawStatBar( x, y, w, h, frac, fillCol, label )
	frac = math.Clamp( frac, 0, 1 )

	surface.SetDrawColor( 0, 0, 0, 180 )
	surface.DrawRect( x, y, w, h )

	surface.SetDrawColor( fillCol.r, fillCol.g, fillCol.b, 220 )
	surface.DrawRect( x + 1, y + 1, math.floor( ( w - 2 ) * frac ), h - 2 )

	surface.SetDrawColor( SWGRP.Config.HUDColorPrimary.r, SWGRP.Config.HUDColorPrimary.g, SWGRP.Config.HUDColorPrimary.b, 120 )
	surface.DrawOutlinedRect( x, y, w, h )

	DrawTextShadow( label, "DermaDefault", x + 6, y + h / 2, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end

hook.Add( "HUDPaint", "SWGRP_MainHUD", function()
	if SWGRP.UI and SWGRP.UI.IsTerminalOpen and SWGRP.UI.IsTerminalOpen() then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then return end

	local scrW, scrH = ScrW(), ScrH()
	local primary = SWGRP.Config.HUDColorPrimary
	local secondary = SWGRP.Config.HUDColorSecondary

	-- Bottom-left info panel
	local pw, ph = 300, 196
	local px, py = 20, scrH - ph - 20
	DrawBox( px, py, pw, ph, Color( 10, 15, 25 ), 200 )

	local barW, barH = pw - 20, 16
	local cy = py + 8

	DrawTextShadow( ply:SWGRP_GetJobName() .. " Lv." .. ply:SWGRP_GetProfLevel(), "DermaDefaultBold", px + 10, cy, primary, TEXT_ALIGN_LEFT )
	cy = cy + 18
	DrawTextShadow( "Wallet: " .. SWGRP.FormatCredits( ply:SWGRP_GetCredits() ) .. "  Bank: " .. SWGRP.FormatCredits( ply:SWGRP_GetBank() ), "DermaDefault", px + 10, cy, secondary, TEXT_ALIGN_LEFT )
	cy = cy + 16
	DrawTextShadow( "Salary: " .. SWGRP.FormatCredits( ply:SWGRP_GetSalary() ), "DermaDefault", px + 10, cy, secondary, TEXT_ALIGN_LEFT )
	cy = cy + 20

	-- Vitals: health and armor, above hunger.
	local maxHealth = math.max( ply:GetMaxHealth(), 1 )
	local health = math.max( ply:Health(), 0 )
	DrawStatBar( px + 10, cy, barW, barH, health / maxHealth, Color( 200, 60, 60 ), "Health  " .. health .. " / " .. maxHealth )
	cy = cy + barH + 4

	local armor = math.Clamp( ply:Armor(), 0, 100 )
	DrawStatBar( px + 10, cy, barW, barH, armor / 100, SWGRP.Config.HUDColorAccent, "Armor  " .. armor )
	cy = cy + barH + 4

	if SWGRP.Config.HungerEnabled and SWGRP.Config.HungerEnabled:GetBool() then
		local hunger = ply:SWGRP_GetHunger()
		local hungerMax = math.max( SWGRP.Config.HungerMax or 100, 1 )
		local hCol = hunger < 20 and SWGRP.Config.HUDColorDanger or Color( 120, 180, 80 )
		DrawStatBar( px + 10, cy, barW, barH, hunger / hungerMax, hCol, "Hunger  " .. hunger .. "%" )
		cy = cy + barH + 4
	end

	local mission = ply:SWGRP_GetMissionName()
	if mission ~= "" then
		DrawTextShadow( "Mission: " .. mission, "DermaDefault", px + 10, cy, SWGRP.Config.HUDColorAccent, TEXT_ALIGN_LEFT )
		cy = cy + 16
	end

	if ply:SWGRP_GetContrabandCount() > 0 then
		DrawTextShadow( "Contraband: " .. ply:SWGRP_GetContrabandCount(), "DermaDefault", px + 10, cy, SWGRP.Config.HUDColorDanger, TEXT_ALIGN_LEFT )
		cy = cy + 16
	end

	local status = ""
	if ply:SWGRP_IsWanted() then
		status = "WANTED: " .. ply:SWGRP_GetWantedReason()
	elseif ply:SWGRP_IsArrested() then
		status = "DETAINED"
	elseif ply:SWGRP_IsAFK() then
		status = "AFK"
	elseif ply:SWGRP_HasLicense() then
		status = "Permit: Active"
	end

	if status ~= "" then
		local col = ply:SWGRP_IsWanted() and SWGRP.Config.HUDColorDanger or SWGRP.Config.HUDColorAccent
		DrawTextShadow( status, "DermaDefault", px + 10, cy, col, TEXT_ALIGN_LEFT )
	end

	-- Faction standing (compact, right of panel)
	local fx = px + pw + 10
	DrawBox( fx, py, 140, 60, Color( 10, 15, 25 ), 180 )
	DrawTextShadow( "Imperial: " .. ply:SWGRP_GetFaction( "imperial" ), "DermaDefault", fx + 8, py + 8, Color( 180, 180, 220 ), TEXT_ALIGN_LEFT )
	DrawTextShadow( "Rebel: " .. ply:SWGRP_GetFaction( "rebel" ), "DermaDefault", fx + 8, py + 24, Color( 255, 100, 80 ), TEXT_ALIGN_LEFT )
	DrawTextShadow( "Underworld: " .. ply:SWGRP_GetFaction( "underworld" ), "DermaDefault", fx + 8, py + 40, Color( 150, 50, 200 ), TEXT_ALIGN_LEFT )

	-- Lockdown banner
	if SWGRP.Government and SWGRP.Government.Lockdown then
		DrawBox( scrW / 2 - 200, 10, 400, 30, Color( 80, 0, 0 ), 220 )
		DrawTextShadow( "IMPERIAL LOCKDOWN IN EFFECT", "DermaDefaultBold", scrW / 2, 25, Color( 255, 80, 80 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	-- Door information is rendered as a 3D2D plate on the door itself (see cl_doors.lua).
end )

-- Agenda / Laws panel (top right)
SWGRP.LawsClient = SWGRP.LawsClient or {}

net.Receive( "SWGRP_SyncLaws", function()
	SWGRP.LawsClient = {}
	local count = net.ReadUInt( 8 )
	for i = 1, count do
		table.insert( SWGRP.LawsClient, net.ReadString() )
	end
end )

SWGRP.Government = SWGRP.Government or {}
net.Receive( "SWGRP_SyncLockdown", function()
	SWGRP.Government.Lockdown = net.ReadBool()
	SWGRP.Government.LockdownEnd = net.ReadFloat()
end )

hook.Add( "HUDPaint", "SWGRP_AgendaHUD", function()
	if SWGRP.UI and SWGRP.UI.IsTerminalOpen and SWGRP.UI.IsTerminalOpen() then return end

	local agenda = GetGlobalString( "SWGRP_Agenda", "" )
	if agenda == "" then return end
	if not LocalPlayer():SWGRP_IsGovernor() and not LocalPlayer():SWGRP_IsGovernment() then return end

	local scrW = ScrW()
	DrawBox( 20, 80, 240, 40, Color( 10, 15, 25 ), 180 )
	DrawTextShadow( "Governor Agenda", "DermaDefaultBold", 30, 86, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_LEFT )
	DrawTextShadow( agenda, "DermaDefault", 30, 102, SWGRP.Config.HUDColorSecondary, TEXT_ALIGN_LEFT )
end )

hook.Add( "HUDPaint", "SWGRP_LawsHUD", function()
	if SWGRP.UI and SWGRP.UI.IsTerminalOpen and SWGRP.UI.IsTerminalOpen() then return end
	if #SWGRP.LawsClient == 0 then return end

	local scrW = ScrW()
	local x, y = scrW - 260, 80
	DrawBox( x, y, 240, 20 + #SWGRP.LawsClient * 16, Color( 10, 15, 25 ), 180 )
	DrawTextShadow( "Planetary Laws", "DermaDefaultBold", x + 10, y + 6, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_LEFT )

	for i, law in ipairs( SWGRP.LawsClient ) do
		DrawTextShadow( i .. ". " .. law, "DermaDefault", x + 10, y + 20 + ( i - 1 ) * 16, SWGRP.Config.HUDColorSecondary, TEXT_ALIGN_LEFT )
	end
end )

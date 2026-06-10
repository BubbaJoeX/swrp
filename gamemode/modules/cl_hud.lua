--[[---------------------------------------------------------------------------
    SWGRP HUD — personnel terminal overlay
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

local function hudBlocked()
	if SWGRP.UI and SWGRP.UI.IsTerminalOpen and SWGRP.UI.IsTerminalOpen() then return true end
	return false
end

hook.Add( "HUDPaint", "SWGRP_MainHUD", function()
	if hudBlocked() then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then return end

	local UI = SWGRP.UI
	if not UI or not UI.HUD then return end

	local HUD = UI.HUD
	HUD.Sync()

	local scrW, scrH = ScrW(), ScrH()
	local primary = UI.Colors.primary
	local secondary = UI.Colors.secondary
	local accent = UI.Colors.accent
	local danger = UI.Colors.danger

	local pw, ph = 300, 200
	local px, py = 18, scrH - ph - 18
	HUD.DrawPanel( px, py, pw, ph, 215 )

	local jobName = ply:SWGRP_GetJobName()
	if jobName == "" or jobName == "Unassigned" then
		jobName = team.GetName( ply:Team() ) or "Colonist"
	end
	HUD.DrawHeader( px, py, pw, string.upper( jobName ) .. "  ·  LVL " .. ply:SWGRP_GetProfLevel() )

	local cy = py + 30
	HUD.TextShadow( "WALLET  " .. SWGRP.FormatCredits( ply:SWGRP_GetCredits() ), "SWGRP_HUD_Body", px + 12, cy, primary, TEXT_ALIGN_LEFT )
	cy = cy + 16
	HUD.TextShadow( "BANK  " .. SWGRP.FormatCredits( ply:SWGRP_GetBank() ), "SWGRP_HUD_Body", px + 12, cy, secondary, TEXT_ALIGN_LEFT )
	cy = cy + 16
	HUD.TextShadow( "SALARY  " .. SWGRP.FormatCredits( ply:SWGRP_GetSalary() ), "SWGRP_HUD_Small", px + 12, cy, Color( 170, 180, 195 ), TEXT_ALIGN_LEFT )
	cy = cy + 18

	local barW, barH = pw - 24, 15
	local maxHealth = math.max( ply:GetMaxHealth(), 1 )
	local health = math.max( ply:Health(), 0 )
	HUD.DrawStatBar( px + 12, cy, barW, barH, health / maxHealth, Color( 200, 60, 60 ), "HEALTH  " .. health .. "/" .. maxHealth )
	cy = cy + barH + 5

	local armor = math.Clamp( ply:Armor(), 0, 100 )
	HUD.DrawStatBar( px + 12, cy, barW, barH, armor / 100, accent, "ARMOR  " .. armor )
	cy = cy + barH + 5

	if SWGRP.Config.HungerEnabled and SWGRP.Config.HungerEnabled:GetBool() then
		local hunger = ply:SWGRP_GetHunger()
		local hungerMax = math.max( SWGRP.Config.HungerMax or 100, 1 )
		local hCol = hunger < 20 and danger or Color( 120, 180, 80 )
		HUD.DrawStatBar( px + 12, cy, barW, barH, hunger / hungerMax, hCol, "HUNGER  " .. hunger .. "%" )
		cy = cy + barH + 5
	end

	local mission = ply:SWGRP_GetMissionName()
	if mission ~= "" then
		HUD.TextShadow( "MISSION  " .. mission, "SWGRP_HUD_Small", px + 12, cy, accent, TEXT_ALIGN_LEFT )
		cy = cy + 14
	end

	if ply:SWGRP_GetContrabandCount() > 0 then
		HUD.TextShadow( "CONTRABAND  " .. ply:SWGRP_GetContrabandCount(), "SWGRP_HUD_Small", px + 12, cy, danger, TEXT_ALIGN_LEFT )
		cy = cy + 14
	end

	local status, statusCol
	if ply:SWGRP_IsWanted() then
		status = "WANTED — " .. ply:SWGRP_GetWantedReason()
		statusCol = danger
	elseif ply:SWGRP_IsArrested() then
		status = "DETAINED"
		statusCol = danger
	elseif ply:SWGRP_IsAFK() then
		status = "AFK"
		statusCol = secondary
	elseif ply:SWGRP_HasLicense() then
		status = "WEAPON PERMIT ACTIVE"
		statusCol = accent
	end

	if status then
		HUD.TextShadow( status, "SWGRP_HUD_Small", px + 12, cy, statusCol, TEXT_ALIGN_LEFT )
	end

	-- Faction standing
	local fx, fy = px + pw + 10, py
	local fh = 92
	HUD.DrawPanel( fx, fy, 148, fh, 200 )
	HUD.DrawHeader( fx, fy, 148, "STANDING" )
	HUD.TextShadow( "Imperial  " .. ply:SWGRP_GetFaction( "imperial" ), "SWGRP_HUD_Small", fx + 10, fy + 34, Color( 180, 190, 220 ), TEXT_ALIGN_LEFT )
	HUD.TextShadow( "Rebel  " .. ply:SWGRP_GetFaction( "rebel" ), "SWGRP_HUD_Small", fx + 10, fy + 50, Color( 255, 110, 90 ), TEXT_ALIGN_LEFT )
	HUD.TextShadow( "Underworld  " .. ply:SWGRP_GetFaction( "underworld" ), "SWGRP_HUD_Small", fx + 10, fy + 66, Color( 170, 90, 210 ), TEXT_ALIGN_LEFT )

	if SWGRP.Government and SWGRP.Government.Lockdown then
		local bw, bh = 420, 32
		local bx = scrW * 0.5 - bw * 0.5
		local by = 118
		draw.RoundedBox( 6, bx, by, bw, bh, Color( 90, 10, 10, 230 ) )
		surface.SetDrawColor( 255, 80, 80, 200 )
		surface.DrawOutlinedRect( bx, by, bw, bh, 1 )
		HUD.TextShadow( "IMPERIAL LOCKDOWN IN EFFECT", "SWGRP_HUD_Subtitle", scrW * 0.5, by + bh / 2, Color( 255, 120, 120 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end )

-- Draw after VGUI (F4/F3 terminals) so purchase and notify toasts stay visible.
hook.Add( "DrawOverlay", "SWGRP_Toasts", function()
	local UI = SWGRP.UI
	if not UI or not UI.HUD or not UI.HUD.DrawToasts then return end
	UI.HUD.DrawToasts()
end )

net.Receive( "SWGRP_Notify", function()
	local msg, msgType = SWGRP.NetReadNotify()
	local col = SWGRP.Config.HUDColorAccent
	if msgType == 1 then
		col = SWGRP.Config.HUDColorDanger
	end
	if SWGRP.UI and SWGRP.UI.HUD and SWGRP.UI.HUD.Toast then
		SWGRP.UI.HUD.Toast( msg, 3.5, col )
	end
end )

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
	if hudBlocked() then return end

	local agenda = GetGlobalString( "SWGRP_Agenda", "" )
	if agenda == "" then return end
	if not LocalPlayer():SWGRP_IsGovernor() and not LocalPlayer():SWGRP_IsGovernment() then return end

	local UI = SWGRP.UI
	if not UI or not UI.HUD then return end
	local HUD = UI.HUD
	HUD.Sync()

	local w, h = 280, 52
	HUD.DrawPanel( 18, 88, w, h, 200 )
	HUD.DrawHeader( 18, 88, w, "GOVERNOR AGENDA" )
	HUD.TextShadow( agenda, "SWGRP_HUD_Small", 28, 118, UI.Colors.secondary, TEXT_ALIGN_LEFT )
end )

hook.Add( "HUDPaint", "SWGRP_LawsHUD", function()
	if hudBlocked() then return end
	if #SWGRP.LawsClient == 0 then return end

	local UI = SWGRP.UI
	if not UI or not UI.HUD then return end
	local HUD = UI.HUD
	HUD.Sync()

	local scrW = ScrW()
	local x, y = scrW - 278, 88
	local lineH = 15
	local maxLines = math.min( #SWGRP.LawsClient, 6 )
	local h = 26 + maxLines * lineH + 6

	HUD.DrawPanel( x, y, 260, h, 200 )
	HUD.DrawHeader( x, y, 260, "PLANETARY LAW" )

	for i = 1, maxLines do
		local law = SWGRP.LawsClient[i]
		if #law > 42 then law = string.sub( law, 1, 41 ) .. "…" end
		HUD.TextShadow( i .. ".  " .. law, "SWGRP_HUD_Small", x + 10, y + 24 + ( i - 1 ) * lineH, UI.Colors.secondary, TEXT_ALIGN_LEFT )
	end

	if #SWGRP.LawsClient > maxLines then
		HUD.TextShadow( "+" .. ( #SWGRP.LawsClient - maxLines ) .. " more…", "SWGRP_HUD_Micro", x + 10, y + h - 10, UI.Colors.borderDim, TEXT_ALIGN_LEFT )
	end
end )

--[[---------------------------------------------------------------------------
    Weapon strip + client weapon switching
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.WeaponHUD = SWGRP.WeaponHUD or {}

local WH = SWGRP.WeaponHUD
local UI = SWGRP.UI

WH.StripShowUntil = 0
WH.StripShowStart = 0
WH.STRIP_DURATION = 3
WH.LastWeaponIndex = 1
WH.ScrollFrac = WH.ScrollFrac or {}

local CELL_W, CELL_H = 58, 50
local CELL_GAP = 5
local SUB_CELL_H = 18
local STRIP_Y = 14
local MAX_VISIBLE = 9
local SCROLL_LERP = 16
local FADE_IN_TIME = 0.12
local FADE_OUT_TIME = 0.45

WH.ShortLabels = {
	weapon_physgun = "PHYS",
	weapon_physcannon = "GRAV",
	gmod_tool = "TOOL",
	gmod_camera = "CAM",
	swgrp_keys = "KEYS",
	swgrp_admin_doortool = "DOOR",
	swgrp_admin_buttontool = "CTRL",
	swgrp_admin_jobspawntool = "JOB",
	swgrp_admin_jailtool = "JAIL",
	swgrp_admin_mapadjuster = "MAP",
	swgrp_entity_spawner = "SPAWN",
	swgrp_admin_ownershipchanger = "OWN",
	swgrp_climb = "CLIMB",
	swgrp_grappler = "GRPL",
	swgrp_lockpick = "LOCK",
	swgrp_arrest_baton = "ARREST",
	swgrp_unarrest_baton = "FREE",
}

WH.ToolHints = {
	swgrp_admin_doortool = "Door tool — left-click a door",
	swgrp_admin_buttontool = "Control tool — left-click a button or prop",
	swgrp_admin_jobspawntool = "Job spawns — LMB add, RMB menu, R reload remove",
	swgrp_admin_jailtool = "Jail points — LMB add, RMB menu, R reload remove",
	swgrp_admin_mapadjuster = "Map atmosphere — left-click to open settings",
	swgrp_entity_spawner = "Entity spawner — left-click to open catalog",
	swgrp_admin_ownershipchanger = "Ownership — left-click an entity",
	swgrp_climb = "Climb — hold right-click against a wall",
	swgrp_grappler = "Grappler — LMB attach/reel, RMB detach",
}

local function weaponSwitchBlocked()
	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then return true end
	if vgui.CursorVisible() then return true end
	if UI and UI.IsTerminalOpen and UI.IsTerminalOpen() then return true end
	return false
end

local function getWeaponSlotInfo( wep )
	local class = wep:GetClass()
	local stored = weapons.Get( class )

	local slot = wep.Slot
	if slot == nil and stored then slot = stored.Slot end
	slot = slot or 0

	local slotPos = wep.SlotPos
	if slotPos == nil and stored then slotPos = stored.SlotPos end
	slotPos = slotPos or 0

	return slot, slotPos
end

local function sortWeapons( weps )
	table.sort( weps, function( a, b )
		local as, ap = getWeaponSlotInfo( a )
		local bs, bp = getWeaponSlotInfo( b )
		if as == bs then return ap < bp end
		return as < bs
	end )
	return weps
end

function WH.GetSortedWeapons( ply )
	ply = ply or LocalPlayer()
	if not IsValid( ply ) then return {} end

	local list = {}
	for _, wep in ipairs( ply:GetWeapons() ) do
		if IsValid( wep ) then
			table.insert( list, wep )
		end
	end

	return sortWeapons( list )
end

local function buildSlotGroups( weps )
	local bySlot = {}

	for _, wep in ipairs( weps ) do
		local slot = getWeaponSlotInfo( wep )
		bySlot[slot] = bySlot[slot] or {}
		table.insert( bySlot[slot], wep )
	end

	local groups = {}
	for slot, list in pairs( bySlot ) do
		table.sort( list, function( a, b )
			local _, ap = getWeaponSlotInfo( a )
			local _, bp = getWeaponSlotInfo( b )
			return ap < bp
		end )
		table.insert( groups, { slot = slot, weapons = list } )
	end

	table.sort( groups, function( a, b )
		return a.slot < b.slot
	end )

	return groups
end

function WH.GetActiveIndex( weps, active )
	if not IsValid( active ) then return 1 end
	for i, wep in ipairs( weps ) do
		if wep == active then return i end
	end
	return 1
end

function WH.CycleWeapon( direction )
	local ply = LocalPlayer()
	local weps = WH.GetSortedWeapons( ply )
	local count = #weps
	if count == 0 then return false end

	local active = ply:GetActiveWeapon()
	local idx = WH.GetActiveIndex( weps, active )
	idx = idx + direction

	if idx > count then idx = 1 end
	if idx < 1 then idx = count end

	local nextWep = weps[idx]
	if IsValid( nextWep ) then
		input.SelectWeapon( nextWep )
		return true
	end

	return false
end

function WH.SelectSlot( keyNum )
	local ply = LocalPlayer()
	local targetSlot = keyNum - 1
	local weps = WH.GetSortedWeapons( ply )

	local slotWeps = {}
	for _, wep in ipairs( weps ) do
		if getWeaponSlotInfo( wep ) == targetSlot then
			table.insert( slotWeps, wep )
		end
	end

	if #slotWeps == 0 then return false end

	local active = ply:GetActiveWeapon()
	local activeIdx = WH.GetActiveIndex( slotWeps, active )
	local activeInSlot = IsValid( active ) and getWeaponSlotInfo( active ) == targetSlot

	local pick = slotWeps[1]
	if activeInSlot then
		local nextIdx = activeIdx + 1
		if nextIdx > #slotWeps then nextIdx = 1 end
		pick = slotWeps[nextIdx]
	end

	if IsValid( pick ) then
		input.SelectWeapon( pick )
		return true
	end

	return false
end

function WH.ShowStrip()
	local now = CurTime()
	if now > WH.StripShowUntil then
		WH.StripShowStart = now
	end
	WH.StripShowUntil = now + WH.STRIP_DURATION
end

function WH.GetStripFade()
	if CurTime() > WH.StripShowUntil then return 0 end

	local fadeIn = math.Clamp( ( CurTime() - WH.StripShowStart ) / FADE_IN_TIME, 0, 1 )
	local fadeOut = math.Clamp( ( WH.StripShowUntil - CurTime() ) / FADE_OUT_TIME, 0, 1 )
	return math.min( fadeIn, fadeOut )
end

function WH.GetLabel( wep )
	if not IsValid( wep ) then return "?" end
	local class = wep:GetClass()
	local stored = weapons.Get( class )
	if stored and stored.PrintName and stored.PrintName ~= "" then
		return stored.PrintName
	end
	if wep.PrintName and wep.PrintName ~= "" then
		return wep.PrintName
	end
	return WH.ShortLabels[class] or class
end

function WH.GetShortLabel( wep )
	if not IsValid( wep ) then return "?" end
	local class = wep:GetClass()
	if WH.ShortLabels[class] then return WH.ShortLabels[class] end

	local label = WH.GetLabel( wep )
	label = string.gsub( label, "^%s+", "" )
	local word = string.match( label, "^(%S+)" ) or label
	if #word > 6 then
		word = string.sub( word, 1, 5 ) .. "…"
	end
	return string.upper( word )
end

local function defaultDrawWeaponSelection( self, x, y, wide, tall, alpha )
	alpha = alpha or 255
	local hudUI = SWGRP.UI
	if hudUI and hudUI.HUD then
		hudUI.HUD.DrawPanel( x, y, wide, tall, alpha * 0.9 )
	else
		surface.SetDrawColor( 10, 15, 25, alpha )
		surface.DrawRect( x, y, wide, tall )
	end

	local text = WH.GetShortLabel( self )
	draw.SimpleText( text, "SWGRP_HUD_Small", x + wide / 2, y + tall / 2, Color( 255, 255, 255, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

local function patchSwepTables()
	for _, class in ipairs( weapons.GetList() ) do
		local swep = weapons.Get( class )
		if not swep then continue end

		if not swep.DrawWeaponSelection then
			swep.DrawWeaponSelection = defaultDrawWeaponSelection
		end

		if not swep.DrawWeaponInfoBox then
			swep.DrawWeaponInfoBox = false
		end
	end
end

hook.Add( "InitPostEntity", "SWGRP_PatchSWEPDraw", patchSwepTables )
hook.Add( "OnGamemodeLoaded", "SWGRP_PatchSWEPDraw", patchSwepTables )
timer.Simple( 0, patchSwepTables )

hook.Add( "PlayerBindPress", "SWGRP_WeaponSwitch", function( ply, bind, pressed )
	if ply ~= LocalPlayer() or not pressed then return end
	if weaponSwitchBlocked() then return end

	bind = string.lower( bind )
	local handled = false
	local showStrip = false

	if bind == "invnext" then
		handled = WH.CycleWeapon( 1 )
		showStrip = handled
	elseif bind == "invprev" then
		handled = WH.CycleWeapon( -1 )
		showStrip = handled
	elseif bind == "lastinv" then
		local weps = WH.GetSortedWeapons( ply )
		if #weps > 1 then
			local active = ply:GetActiveWeapon()
			local idx = WH.GetActiveIndex( weps, active )
			local lastIdx = WH.LastWeaponIndex or idx
			if lastIdx >= 1 and lastIdx <= #weps and weps[lastIdx] ~= active then
				input.SelectWeapon( weps[lastIdx] )
				handled = true
			end
		end
	else
		local keyNum = string.match( bind, "^slot(%d+)$" )
		if keyNum then
			keyNum = tonumber( keyNum )
			if keyNum == 0 then keyNum = 10 end
			handled = WH.SelectSlot( keyNum )
		end
	end

	if handled then
		if showStrip then
			WH.ShowStrip()
		end
		return true
	end
end )

hook.Add( "PlayerSwitchWeapon", "SWGRP_WeaponHUDHint", function( ply, old, new )
	if ply ~= LocalPlayer() then return end
	if not IsValid( new ) then return end

	local weps = WH.GetSortedWeapons( ply )
	WH.LastWeaponIndex = WH.GetActiveIndex( weps, old )

	if CurTime() > WH.StripShowUntil then return end

	local hint = WH.ToolHints[new:GetClass()]
	if hint and UI and UI.HUD then
		UI.HUD.Toast( hint, 4, UI.Colors.accent )
	end
end )

hook.Add( "HUDShouldDraw", "SWGRP_HideWeaponSelection", function( name )
	if name == "CHudWeaponSelection" then return false end
end )

local function updateStripAnimations( ply )
	if not IsValid( ply ) then return end

	local active = ply:GetActiveWeapon()
	local frameTime = FrameTime()
	local groups = buildSlotGroups( WH.GetSortedWeapons( ply ) )

	for _, group in ipairs( groups ) do
		local n = #group.weapons
		if n <= 1 then continue end

		local groupHasActive = false
		local activeIdx = 1
		for wi, wep in ipairs( group.weapons ) do
			if wep == active then
				groupHasActive = true
				activeIdx = wi
				break
			end
		end

		local scrollKey = group.slot
		local scrollTarget = groupHasActive and activeIdx or 1
		if not WH.ScrollFrac[scrollKey] then
			WH.ScrollFrac[scrollKey] = scrollTarget
		end
		WH.ScrollFrac[scrollKey] = Lerp( frameTime * SCROLL_LERP, WH.ScrollFrac[scrollKey], scrollTarget )
	end
end

hook.Add( "Think", "SWGRP_WeaponStripAnim", function()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return end
	updateStripAnimations( ply )
end )

hook.Add( "HUDPaint", "SWGRP_WeaponStrip", function()
	if UI and UI.IsTerminalOpen and UI.IsTerminalOpen() then return end

	local fade = WH.GetStripFade()
	if fade <= 0 then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) or not ply:Alive() then return end
	if not UI or not UI.HUD then return end

	local HUD = UI.HUD
	HUD.Sync()
	surface.SetAlphaMultiplier( fade )

	local groups = buildSlotGroups( WH.GetSortedWeapons( ply ) )
	local groupCount = #groups
	if groupCount == 0 then
		surface.SetAlphaMultiplier( 1 )
		return
	end

	local active = ply:GetActiveWeapon()
	local activeGroupIdx = 1
	for gi, group in ipairs( groups ) do
		for _, wep in ipairs( group.weapons ) do
			if wep == active then
				activeGroupIdx = gi
				break
			end
		end
	end

	local visible = math.min( groupCount, MAX_VISIBLE )
	local half = math.floor( visible / 2 )
	local startIdx = math.Clamp( activeGroupIdx - half, 1, math.max( 1, groupCount - visible + 1 ) )
	local endIdx = math.min( groupCount, startIdx + visible - 1 )

	local totalW = visible * CELL_W + ( visible - 1 ) * CELL_GAP
	local scrW = ScrW()
	local startX = scrW * 0.5 - totalW * 0.5
	local centerY = STRIP_Y + CELL_H / 2

	local arrowY = centerY
	if startIdx > 1 then
		HUD.TextShadow( "◀", "SWGRP_HUD_Small", startX - 14, arrowY, UI.Colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	if endIdx < groupCount then
		HUD.TextShadow( "▶", "SWGRP_HUD_Small", startX + totalW + 14, arrowY, UI.Colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local colNum = 0
	for gi = startIdx, endIdx do
		colNum = colNum + 1
		local group = groups[gi]
		local x = startX + ( colNum - 1 ) * ( CELL_W + CELL_GAP )
		local n = #group.weapons
		local displaySlot = group.slot + 1
		local groupHasActive = false
		local activeIdx = 1

		for wi, wep in ipairs( group.weapons ) do
			if wep == active then
				groupHasActive = true
				activeIdx = wi
				break
			end
		end

		local scrollKey = group.slot
		local scrollFrac = WH.ScrollFrac[scrollKey] or activeIdx

		local alpha = groupHasActive and 235 or 185
		HUD.DrawPanel( x, STRIP_Y, CELL_W, CELL_H, alpha )

		HUD.TextShadow( tostring( displaySlot ), "SWGRP_HUD_Micro", x + 8, STRIP_Y + 10, UI.Colors.borderDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		if n == 1 then
			local wep = group.weapons[1]
			local selected = wep == active

			if selected then
				surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 70 )
				surface.DrawRect( x + 2, STRIP_Y + 2, CELL_W - 4, CELL_H - 4 )
				surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 240 )
				surface.DrawOutlinedRect( x, STRIP_Y, CELL_W, CELL_H, 2 )
			end

			HUD.TextShadow( WH.GetShortLabel( wep ), "SWGRP_HUD_Small", x + CELL_W / 2, centerY + 2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			if groupHasActive then
				surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 70 )
				surface.DrawRect( x + 3, centerY - SUB_CELL_H / 2, CELL_W - 6, SUB_CELL_H )
				surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 240 )
				surface.DrawOutlinedRect( x + 3, centerY - SUB_CELL_H / 2, CELL_W - 6, SUB_CELL_H, 1 )
			end

			for wi, wep in ipairs( group.weapons ) do
				local offset = ( wi - scrollFrac ) * SUB_CELL_H
				local labelY = centerY + offset
				if labelY < STRIP_Y + 6 or labelY > STRIP_Y + CELL_H - 6 then continue end

				local dist = math.abs( wi - scrollFrac )
				local labelAlpha = math.Clamp( 255 - dist * 90, 80, 255 )
				local font = dist < 0.35 and "SWGRP_HUD_Small" or "SWGRP_HUD_Micro"

				HUD.TextShadow( WH.GetShortLabel( wep ), font, x + CELL_W / 2, labelY, Color( 255, 255, 255, labelAlpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end
	end

	if IsValid( active ) then
		surface.SetFont( "SWGRP_HUD_Micro" )
		local activeLabel = WH.GetLabel( active )
		local tw = surface.GetTextSize( activeLabel )
		local bw = math.min( scrW * 0.45, tw + 24 )
		local bx = scrW * 0.5 - bw / 2
		local by = STRIP_Y + CELL_H + 6
		draw.RoundedBox( 4, bx, by, bw, 18, Color( 10, 15, 25, 200 ) )
		HUD.TextShadow( activeLabel, "SWGRP_HUD_Micro", scrW * 0.5, by + 9, UI.Colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	surface.SetAlphaMultiplier( 1 )
end )

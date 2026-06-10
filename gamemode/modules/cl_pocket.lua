--[[---------------------------------------------------------------------------
    Pocket - 8-slot drag-and-drop inventory GUI
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Pocket = SWGRP.Pocket or {}
SWGRP.Pocket.Slots = SWGRP.Pocket.Slots or {}

local POCKET_MAX = 8
local DRAG_TYPES = { "SWGRP_PocketItem", "SWGRP_InvWeapon" }

local BLOCKED = {
	swgrp_keys = true,
	weapon_physgun = true,
	weapon_physcannon = true,
	gmod_tool = true,
	gmod_camera = true,
}

local function initSlots()
	for i = 1, POCKET_MAX do
		if SWGRP.Pocket.Slots[i] == nil then
			SWGRP.Pocket.Slots[i] = false
		end
	end
end

local function readItem()
	if not net.ReadBool() then return false end

	local item = {
		kind  = net.ReadString(),
		class = net.ReadString(),
		state = util.JSONToTable( net.ReadString() ) or {},
	}

	-- Legacy rows may still arrive without a state blob on very old saves; the
	-- server normalizes on load but keep the client tolerant.
	if item.kind == "shipment" then
		item.kind  = "entity"
		item.class = item.class ~= "" and item.class or "swgrp_shipment"
	end

	return item
end

local function slotHasItem( item )
	return item and item ~= false and istable( item ) and item.class and item.class ~= ""
end

local function requestSync()
	net.Start( "SWGRP_PocketRequestSync" )
	net.SendToServer()
end

local function storeWeapon( slot, class )
	if not class or class == "" then return end
	net.Start( "SWGRP_PocketStore" )
		net.WriteUInt( slot or 0, 4 )
		net.WriteString( class )
	net.SendToServer()
end

local function dropSlot( slot )
	if not slot or slot < 1 then return end
	net.Start( "SWGRP_PocketDrop" )
		net.WriteUInt( slot, 4 )
	net.SendToServer()
end

local function swapSlots( a, b )
	net.Start( "SWGRP_PocketSwap" )
		net.WriteUInt( a, 4 )
		net.WriteUInt( b, 4 )
	net.SendToServer()
end

net.Receive( "SWGRP_PocketSync", function()
	SWGRP.Pocket.Slots = {}
	for i = 1, POCKET_MAX do
		SWGRP.Pocket.Slots[i] = readItem()
	end

	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.RebuildMenu()
	end
end )

function SWGRP.Pocket.ItemLabel( item )
	if not slotHasItem( item ) then return "" end

	local state = item.state or {}

	if item.class == "swgrp_shipment" and state.name and state.name ~= "" then
		if state.remaining and state.remaining > 0 then
			return state.name .. " (" .. state.remaining .. ")"
		end
		return state.name
	end

	if item.class == "swgrp_spice" and state.spiceID and SWGRP.Spices and SWGRP.Spices[state.spiceID] then
		return SWGRP.Spices[state.spiceID].name
	end

	if item.kind == "weapon" or weapons.GetStored( item.class ) then
		local swep = weapons.Get( item.class )
		if swep and swep.PrintName and swep.PrintName ~= "" then return swep.PrintName end
	end

	if SWGRP.Entities and SWGRP.Entities[item.class] and SWGRP.Entities[item.class].name then
		return SWGRP.Entities[item.class].name
	end

	return item.class or "Item"
end

function SWGRP.Pocket.ItemModel( item )
	if not slotHasItem( item ) then return nil end

	local state = item.state or {}

	if state.model and state.model ~= "" then return state.model end

	if item.class == "swgrp_shipment" and state.weapon and state.weapon ~= "" then
		local swep = weapons.Get( state.weapon )
		if swep and swep.WorldModel and swep.WorldModel ~= "" then return swep.WorldModel end
	end

	if item.class == "swgrp_spice" and state.spiceID and SWGRP.Spices and SWGRP.Spices[state.spiceID] then
		local spice = SWGRP.Spices[state.spiceID]
		if spice.model and spice.model ~= "" then return spice.model end
	end

	if item.kind == "weapon" or weapons.GetStored( item.class ) then
		local swep = weapons.Get( item.class )
		if swep and swep.WorldModel and swep.WorldModel ~= "" then return swep.WorldModel end
	end

	if SWGRP.Entities and SWGRP.Entities[item.class] and SWGRP.Entities[item.class].model then
		return SWGRP.Entities[item.class].model
	end

	if item.class == "swgrp_shipment" then
		return "models/Items/item_item_crate.mdl"
	end

	return "models/props_junk/cardboard_box004a.mdl"
end

function SWGRP.Pocket.ItemColor( item )
	if not slotHasItem( item ) then return SWGRP.UI and SWGRP.UI.Colors.secondary or color_white end
	if item.class == "swgrp_shipment" then return Color( 255, 160, 60 ) end
	if item.kind == "entity" then return SWGRP.UI and SWGRP.UI.Colors.primary or Color( 255, 180, 50 ) end
	return SWGRP.UI and SWGRP.UI.Colors.accent or Color( 80, 200, 255 )
end

local function quickStore()
	net.Start( "SWGRP_PocketQuickStore" )
	net.SendToServer()
end

local function styleSlotPanel( panel, accent, selected )
	panel.Paint = function( self, w, h )
		local UI = SWGRP.UI
		if UI and UI.PaintTerminalPanel then
			UI.PaintTerminalPanel( self, w, h )
		else
			surface.SetDrawColor( 18, 24, 38, 230 )
			surface.DrawRect( 0, 0, w, h )
		end

		local col = accent or ( UI and UI.Colors.borderDim )
		if col then
			surface.SetDrawColor( col.r, col.g, col.b, selected and 255 or 180 )
			surface.DrawOutlinedRect( 0, 0, w, h, selected and 3 or 2 )
		end
	end
end

local function attachModelPreview( parent, mdl, col )
	if not mdl or mdl == "" then return end

	local preview = vgui.Create( "DModelPanel", parent )
	preview:Dock( FILL )
	preview:DockMargin( 4, 4, 4, 22 )
	preview:SetMouseInputEnabled( false )
	if SWGRP.UI and SWGRP.UI.SetupModelPreview then
		SWGRP.UI.SetupModelPreview( preview, mdl, col )
	else
		preview:SetModel( mdl )
	end
end

local function handleDropOnSlot( recv, drag )
	if not IsValid( recv ) or not IsValid( drag ) then return end

	if drag.SWGRP_PocketSlot then
		if drag.SWGRP_PocketSlot == recv.SWGRP_PocketSlot then return end
		swapSlots( drag.SWGRP_PocketSlot, recv.SWGRP_PocketSlot )
	elseif drag.SWGRP_WeaponClass then
		storeWeapon( recv.SWGRP_PocketSlot, drag.SWGRP_WeaponClass )
	end
end

local function makePocketSlot( parent, slotIndex, size )
	local slot = vgui.Create( "DPanel", parent )
	slot:SetSize( size, size )
	slot.SWGRP_PocketSlot = slotIndex
	slot:SetCursor( "hand" )

	slot:Droppable( "SWGRP_PocketItem" )
	slot:Receiver( DRAG_TYPES, function( recv, panels, dropped )
		if not dropped then return end
		handleDropOnSlot( recv, panels[1] )
	end )

	function slot:OnMousePressed( mc )
		if mc ~= MOUSE_LEFT then return end

		local now = CurTime()
		local item = SWGRP.Pocket.Slots[slotIndex]

		if self.SWGRP_LastClick and ( now - self.SWGRP_LastClick ) < 0.35 then
			if slotHasItem( item ) then
				dropSlot( slotIndex )
			end
			self.SWGRP_LastClick = nil
			return
		end
		self.SWGRP_LastClick = now

		if slotHasItem( item ) then
			SWGRP.Pocket.SelectedSlot = slotIndex
			SWGRP.Pocket.SelectedWeapon = nil
		elseif SWGRP.Pocket.SelectedWeapon then
			storeWeapon( slotIndex, SWGRP.Pocket.SelectedWeapon )
			SWGRP.Pocket.SelectedWeapon = nil
		end

		if IsValid( SWGRP.Pocket.Menu ) then
			SWGRP.Pocket.RebuildMenu()
		end
	end

	return slot
end

local function makeInventoryWeapon( parent, class, size )
	local tile = vgui.Create( "DPanel", parent )
	tile:SetSize( size, size )
	tile.SWGRP_WeaponClass = class
	tile:SetCursor( "hand" )
	styleSlotPanel( tile, SWGRP.Pocket.ItemColor( { kind = "weapon", class = class } ), SWGRP.Pocket.SelectedWeapon == class )

	tile:Droppable( "SWGRP_InvWeapon" )

	local label = vgui.Create( "DLabel", tile )
	label:Dock( BOTTOM )
	label:SetTall( 18 )
	label:SetContentAlignment( 5 )
	label:SetFont( "DermaDefault" )
	label:SetTextColor( SWGRP.UI and SWGRP.UI.Colors.secondary or color_white )
	label:SetText( SWGRP.Pocket.ItemLabel( { kind = "weapon", class = class } ) )
	label:SetMouseInputEnabled( false )

	attachModelPreview( tile, SWGRP.Pocket.ItemModel( { kind = "weapon", class = class } ), SWGRP.Pocket.ItemColor( { kind = "weapon", class = class } ) )

	function tile:OnMousePressed( mc )
		if mc ~= MOUSE_LEFT then return end
		SWGRP.Pocket.SelectedWeapon = class
		SWGRP.Pocket.SelectedSlot = nil
		if IsValid( SWGRP.Pocket.Menu ) then
			SWGRP.Pocket.RebuildMenu()
		end
	end

	return tile
end

function SWGRP.Pocket.RebuildMenu()
	local frame = SWGRP.Pocket.Menu
	if not IsValid( frame ) then return end

	initSlots()

	if IsValid( SWGRP.Pocket.PocketGrid ) then SWGRP.Pocket.PocketGrid:Remove() end
	if IsValid( SWGRP.Pocket.InvLayout ) then SWGRP.Pocket.InvLayout:Remove() end

	local UI = SWGRP.UI
	local pocketHost = frame.SWGRP_PocketHost
	local invHost = frame.SWGRP_InvHost
	if not IsValid( pocketHost ) or not IsValid( invHost ) then return end

	local slotSize = 84

	local grid = vgui.Create( "DIconLayout", pocketHost )
	grid:Dock( FILL )
	grid:SetSpaceX( UI.Spacing.gap )
	grid:SetSpaceY( UI.Spacing.gap )
	SWGRP.Pocket.PocketGrid = grid

	for i = 1, POCKET_MAX do
		local item = SWGRP.Pocket.Slots[i]
		local slot = makePocketSlot( grid, i, slotSize )

		if slotHasItem( item ) then
			local col = SWGRP.Pocket.ItemColor( item )
			styleSlotPanel( slot, col, SWGRP.Pocket.SelectedSlot == i )

			local label = vgui.Create( "DLabel", slot )
			label:Dock( BOTTOM )
			label:SetTall( 18 )
			label:SetContentAlignment( 5 )
			label:SetFont( "DermaDefault" )
			label:SetTextColor( UI.Colors.secondary )
			label:SetText( SWGRP.Pocket.ItemLabel( item ) )
			label:SetMouseInputEnabled( false )

			attachModelPreview( slot, SWGRP.Pocket.ItemModel( item ), col )
		else
			styleSlotPanel( slot, nil, false )
			local hint = vgui.Create( "DLabel", slot )
			hint:Dock( FILL )
			hint:SetContentAlignment( 5 )
			hint:SetFont( "DermaDefault" )
			hint:SetTextColor( Color( 120, 120, 120 ) )
			hint:SetText( "Empty" )
			hint:SetMouseInputEnabled( false )
		end
	end

	local invCanvas = invHost.GetCanvas and invHost:GetCanvas() or invHost
	local invLayout = vgui.Create( "DIconLayout", invCanvas )
	invLayout:Dock( TOP )
	invLayout:SetSpaceX( UI.Spacing.gap )
	invLayout:SetSpaceY( UI.Spacing.gap )
	SWGRP.Pocket.InvLayout = invLayout

	local ply = LocalPlayer()
	local hasWeapons = false
	if IsValid( ply ) then
		for _, wep in ipairs( ply:GetWeapons() ) do
			if IsValid( wep ) then
				local class = wep:GetClass()
				if not BLOCKED[class] then
					makeInventoryWeapon( invLayout, class, slotSize )
					hasWeapons = true
				end
			end
		end
	end

	if not hasWeapons then
		local empty = vgui.Create( "DLabel", invLayout )
		empty:SetSize( 320, 24 )
		empty:SetFont( "DermaDefault" )
		empty:SetTextColor( UI.Colors.secondary )
		empty:SetText( "No pocketable weapons equipped." )
	end
end

function SWGRP.Pocket.OpenMenu()
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end
	if IsValid( SWGRP.Pocket.Menu ) then return end

	initSlots()
	SWGRP.Pocket.SelectedWeapon = nil
	SWGRP.Pocket.SelectedSlot = nil

	UI.SyncColors()

	local frame = UI.CreateTerminalFrame( "POCKET", 480, 540 )
	SWGRP.Pocket.Menu = frame

	local body = vgui.Create( "DPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end

	local invTitle = UI.CreateLabel( body, "Inventory — drag or click, then click a pocket slot", "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( invTitle ) then invTitle:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local invScroll = vgui.Create( "DScrollPanel", body )
	invScroll:Dock( TOP )
	invScroll:SetTall( 110 )
	invScroll:DockMargin( 0, 0, 0, UI.Spacing.gapLarge )
	UI.StyleScrollPanel( invScroll )
	frame.SWGRP_InvHost = invScroll

	local pocketTitle = UI.CreateLabel( body, "Pocket — 8 slots (double-click slot to drop)", "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( pocketTitle ) then pocketTitle:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local pocketHost = vgui.Create( "DPanel", body )
	pocketHost:Dock( TOP )
	pocketHost:SetTall( 190 )
	pocketHost:DockMargin( 0, 0, 0, UI.Spacing.gap )
	pocketHost.Paint = function() end
	frame.SWGRP_PocketHost = pocketHost

	local dropZone = vgui.Create( "DPanel", body )
	dropZone:Dock( BOTTOM )
	dropZone:SetTall( 56 )
	dropZone:DockMargin( 0, UI.Spacing.gap, 0, 0 )
	dropZone:SetCursor( "hand" )
	dropZone.Paint = function( self, w, h )
		surface.SetDrawColor( UI.Colors.bgLight.r, UI.Colors.bgLight.g, UI.Colors.bgLight.b, 220 )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor( UI.Colors.danger.r, UI.Colors.danger.g, UI.Colors.danger.b, 160 )
		surface.DrawOutlinedRect( 0, 0, w, h, 2 )
		draw.SimpleText( "Drag here or click to drop selected item", "DermaDefaultBold", w / 2, h / 2, UI.Colors.danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	dropZone:Receiver( { "SWGRP_PocketItem" }, function( _, panels, dropped )
		if not dropped then return end
		local drag = panels[1]
		if drag and drag.SWGRP_PocketSlot then
			dropSlot( drag.SWGRP_PocketSlot )
		end
	end )

	function dropZone:OnMousePressed( mc )
		if mc ~= MOUSE_LEFT then return end
		if SWGRP.Pocket.SelectedSlot then
			dropSlot( SWGRP.Pocket.SelectedSlot )
			SWGRP.Pocket.SelectedSlot = nil
			SWGRP.Pocket.RebuildMenu()
		end
	end

	local hint = UI.CreateLabel( body, "Alt+R quick-pocket  •  /pocket while aiming at equipment", "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( hint ) then hint:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	requestSync()
	SWGRP.Pocket.RebuildMenu()
end

function SWGRP.Pocket.ToggleMenu()
	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.Menu:Remove()
		SWGRP.Pocket.Menu = nil
		SWGRP.Pocket.SelectedWeapon = nil
		SWGRP.Pocket.SelectedSlot = nil
		return
	end

	SWGRP.Pocket.OpenMenu()
end

hook.Add( "PlayerBindPress", "SWGRP_PocketKey", function( ply, bind, pressed )
	if not pressed or ply ~= LocalPlayer() then return end
	if not IsValid( ply ) or not ply:Alive() then return end
	if gui.IsConsoleVisible() or ply:IsTyping() then return end

	bind = string.lower( bind )
	if bind ~= "+reload" then return end

	local wep = ply:GetActiveWeapon()
	if IsValid( wep ) and wep:GetClass() == "swgrp_admin_jobspawntool" then
		return
	end

	if input.IsKeyDown( KEY_LALT ) or input.IsKeyDown( KEY_RALT ) then
		quickStore()
		return true
	end

	SWGRP.Pocket.ToggleMenu()
	return true
end )

net.Receive( "SWGRP_PocketOpen", function()
	SWGRP.Pocket.ToggleMenu()
end )

concommand.Add( "swgrp_pocket_menu", SWGRP.Pocket.ToggleMenu )

initSlots()

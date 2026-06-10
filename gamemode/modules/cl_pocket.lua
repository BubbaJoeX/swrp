--[[---------------------------------------------------------------------------
    Pocket - 8-slot drag-and-drop inventory GUI
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Pocket = SWGRP.Pocket or {}
SWGRP.Pocket.Slots = SWGRP.Pocket.Slots or {}
SWGRP.Pocket.SlotPanels = SWGRP.Pocket.SlotPanels or {}

local POCKET_MAX = 8
local SLOT_SIZE = 96
local INV_VISIBLE_ROWS = 2
local DRAG_TYPES = { "SWGRP_PocketItem", "SWGRP_InvWeapon" }
local NET_DEBOUNCE = 0.25

local BLOCKED = {
	swgrp_keys = true,
	weapon_physgun = true,
	weapon_physcannon = true,
	gmod_tool = true,
	gmod_camera = true,
}

local lastNetAt = {}

local function initSlots()
	for i = 1, POCKET_MAX do
		if SWGRP.Pocket.Slots[i] == nil then
			SWGRP.Pocket.Slots[i] = false
		end
	end
end

local function canSendNet( key )
	local now = CurTime()
	if ( lastNetAt[key] or 0 ) + NET_DEBOUNCE > now then return false end
	lastNetAt[key] = now
	return true
end

local function readItem()
	if not net.ReadBool() then return false end

	local item = {
		kind  = net.ReadString(),
		class = net.ReadString(),
		state = util.JSONToTable( net.ReadString() ) or {},
	}

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
	if not canSendNet( "sync" ) then return end
	net.Start( "SWGRP_PocketRequestSync" )
	net.SendToServer()
end

local function storeWeapon( slot, class )
	if not class or class == "" then return end
	slot = math.Clamp( math.floor( slot or 0 ), 0, POCKET_MAX )
	if not canSendNet( "store_" .. class ) then return end

	net.Start( "SWGRP_PocketStore" )
		net.WriteUInt( slot, 4 )
		net.WriteString( class )
	net.SendToServer()
end

local function dropSlot( slot )
	slot = math.floor( slot or 0 )
	if slot < 1 or slot > POCKET_MAX then return end
	if not canSendNet( "drop_" .. slot ) then return end

	net.Start( "SWGRP_PocketDrop" )
		net.WriteUInt( slot, 4 )
	net.SendToServer()
end

local function swapSlots( a, b )
	a, b = math.floor( a or 0 ), math.floor( b or 0 )
	if a < 1 or a > POCKET_MAX or b < 1 or b > POCKET_MAX or a == b then return end
	if not canSendNet( "swap_" .. a .. "_" .. b ) then return end

	net.Start( "SWGRP_PocketSwap" )
		net.WriteUInt( a, 4 )
		net.WriteUInt( b, 4 )
	net.SendToServer()
end

function SWGRP.Pocket.ClearSelection()
	SWGRP.Pocket.SelectedWeapon = nil
	SWGRP.Pocket.SelectedSlot = nil
	SWGRP.Pocket.UpdateStatusBar()
	SWGRP.Pocket.RefreshHighlights()
end

function SWGRP.Pocket.ValidateSelection()
	local ply = LocalPlayer()
	if not IsValid( ply ) then
		SWGRP.Pocket.ClearSelection()
		return
	end

	if SWGRP.Pocket.SelectedSlot then
		local item = SWGRP.Pocket.Slots[SWGRP.Pocket.SelectedSlot]
		if not slotHasItem( item ) then
			SWGRP.Pocket.SelectedSlot = nil
		end
	end

	if SWGRP.Pocket.SelectedWeapon then
		if BLOCKED[SWGRP.Pocket.SelectedWeapon] or not IsValid( ply:GetWeapon( SWGRP.Pocket.SelectedWeapon ) ) then
			SWGRP.Pocket.SelectedWeapon = nil
		end
	end
end

net.Receive( "SWGRP_PocketSync", function()
	SWGRP.Pocket.Slots = {}
	for i = 1, POCKET_MAX do
		SWGRP.Pocket.Slots[i] = readItem()
	end

	SWGRP.Pocket.ValidateSelection()

	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.RefreshPocket()
		SWGRP.Pocket.RefreshInventory()
		SWGRP.Pocket.UpdateStatusBar()
		SWGRP.Pocket.RefreshDropZone()
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

local function abbrevText( text, maxLen )
	text = string.Trim( text or "" )
	if text == "" then return "" end
	if #text <= maxLen then return text end
	return string.sub( text, 1, maxLen - 2 ) .. "…"
end

local function quickStore()
	if not canSendNet( "quick" ) then return end
	net.Start( "SWGRP_PocketQuickStore" )
	net.SendToServer()
end

local function styleSlotPanel( panel, accent, selected, dim )
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
			local alpha = dim and 90 or ( selected and 255 or 180 )
			surface.SetDrawColor( col.r, col.g, col.b, alpha )
			surface.DrawOutlinedRect( 0, 0, w, h, selected and 3 or 2 )
		end
	end
end

local function attachModelPreview( parent, mdl, col )
	if not mdl or mdl == "" then return end

	if IsValid( parent.SWGRP_ModelPreview ) then
		parent.SWGRP_ModelPreview:Remove()
	end

	local preview = vgui.Create( "DModelPanel", parent )
	preview:Dock( FILL )
	preview:DockMargin( 6, 6, 6, 26 )
	preview:SetMouseInputEnabled( false )
	parent.SWGRP_ModelPreview = preview

	if SWGRP.UI and SWGRP.UI.SetupModelPreview then
		SWGRP.UI.SetupModelPreview( preview, mdl, col )
	else
		preview:SetModel( mdl )
	end
end

local function setSlotLabel( slot, text, tooltip )
	if IsValid( slot.SWGRP_Label ) then
		slot.SWGRP_Label:Remove()
	end

	local label = vgui.Create( "DLabel", slot )
	label:Dock( BOTTOM )
	label:DockMargin( 4, 0, 4, 4 )
	label:SetTall( 22 )
	label:SetFont( "DermaDefault" )
	label:SetTextColor( SWGRP.UI and SWGRP.UI.Colors.secondary or color_white )
	label:SetContentAlignment( 5 )
	label:SetWrap( true )
	label:SetAutoStretchVertical( false )
	label:SetText( abbrevText( text, 16 ) )
	label:SetTooltip( tooltip or text )
	label:SetMouseInputEnabled( false )
	slot.SWGRP_Label = label
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

local function paintEmptySlot( slot, slotIndex )
	styleSlotPanel( slot, nil, false, true )

	if IsValid( slot.SWGRP_ModelPreview ) then slot.SWGRP_ModelPreview:Remove() end
	if IsValid( slot.SWGRP_Label ) then slot.SWGRP_Label:Remove() end

	slot.PaintOver = function( self, w, h )
		local UI = SWGRP.UI
		local col = UI and UI.Colors.borderDim or Color( 255, 180, 50, 60 )
		draw.SimpleText( tostring( slotIndex ), "DermaLarge", w / 2, h / 2 - 6, Color( col.r, col.g, col.b, 70 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	slot:SetTooltip( "Empty slot " .. slotIndex .. " — click a weapon below, then click here to store" )
end

local function paintFilledSlot( slot, slotIndex, item )
	local col = SWGRP.Pocket.ItemColor( item )
	local selected = SWGRP.Pocket.SelectedSlot == slotIndex
	styleSlotPanel( slot, col, selected, false )
	slot.PaintOver = nil

	local label = SWGRP.Pocket.ItemLabel( item )
	setSlotLabel( slot, label, label )
	attachModelPreview( slot, SWGRP.Pocket.ItemModel( item ), col )
	slot:SetTooltip( label .. "\nDouble-click to drop" )
end

local function makePocketSlot( parent, slotIndex )
	local slot = vgui.Create( "DPanel", parent )
	slot:SetSize( SLOT_SIZE, SLOT_SIZE )
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
				SWGRP.Pocket.ClearSelection()
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
			SWGRP.Pocket.ClearSelection()
		end

		SWGRP.Pocket.UpdateStatusBar()
		SWGRP.Pocket.RefreshHighlights()
	end

	SWGRP.Pocket.SlotPanels[slotIndex] = slot
	return slot
end

local function makeInventoryWeapon( parent, class )
	local tile = vgui.Create( "DPanel", parent )
	tile:SetSize( SLOT_SIZE, SLOT_SIZE )
	tile.SWGRP_WeaponClass = class
	tile:SetCursor( "hand" )

	local labelText = SWGRP.Pocket.ItemLabel( { kind = "weapon", class = class } )
	tile:SetTooltip( labelText .. "\nClick to select, then click a pocket slot" )

	styleSlotPanel( tile, SWGRP.Pocket.ItemColor( { kind = "weapon", class = class } ), SWGRP.Pocket.SelectedWeapon == class )
	tile:Droppable( "SWGRP_InvWeapon" )

	setSlotLabel( tile, labelText, labelText )
	attachModelPreview( tile, SWGRP.Pocket.ItemModel( { kind = "weapon", class = class } ), SWGRP.Pocket.ItemColor( { kind = "weapon", class = class } ) )

	function tile:OnMousePressed( mc )
		if mc ~= MOUSE_LEFT then return end
		SWGRP.Pocket.SelectedWeapon = class
		SWGRP.Pocket.SelectedSlot = nil
		SWGRP.Pocket.UpdateStatusBar()
		SWGRP.Pocket.RefreshHighlights()
	end

	return tile
end

function SWGRP.Pocket.RefreshHighlights()
	for i = 1, POCKET_MAX do
		local slot = SWGRP.Pocket.SlotPanels[i]
		local item = SWGRP.Pocket.Slots[i]
		if IsValid( slot ) then
			if slotHasItem( item ) then
				styleSlotPanel( slot, SWGRP.Pocket.ItemColor( item ), SWGRP.Pocket.SelectedSlot == i, false )
			else
				styleSlotPanel( slot, nil, false, true )
			end
		end
	end

	local invLayout = SWGRP.Pocket.InvLayout
	if not IsValid( invLayout ) then return end

	for _, child in ipairs( invLayout:GetChildren() ) do
		if IsValid( child ) and child.SWGRP_WeaponClass then
			styleSlotPanel(
				child,
				SWGRP.Pocket.ItemColor( { kind = "weapon", class = child.SWGRP_WeaponClass } ),
				SWGRP.Pocket.SelectedWeapon == child.SWGRP_WeaponClass
			)
		end
	end
end

function SWGRP.Pocket.UpdateStatusBar()
	local frame = SWGRP.Pocket.Menu
	if not IsValid( frame ) or not IsValid( frame.StatusLabel ) then return end

	local filled = 0
	for i = 1, POCKET_MAX do
		if slotHasItem( SWGRP.Pocket.Slots[i] ) then filled = filled + 1 end
	end

	local detail = "Nothing selected"
	if SWGRP.Pocket.SelectedSlot then
		local item = SWGRP.Pocket.Slots[SWGRP.Pocket.SelectedSlot]
		detail = "Selected slot " .. SWGRP.Pocket.SelectedSlot
		if slotHasItem( item ) then
			detail = detail .. ": " .. abbrevText( SWGRP.Pocket.ItemLabel( item ), 24 )
		end
	elseif SWGRP.Pocket.SelectedWeapon then
		detail = "Store " .. abbrevText( SWGRP.Pocket.ItemLabel( { kind = "weapon", class = SWGRP.Pocket.SelectedWeapon } ), 24 )
	end

	frame.StatusLabel:SetText( string.format( "%d / %d slots used  •  %s", filled, POCKET_MAX, detail ) )
	SWGRP.Pocket.RefreshDropZone()
end

function SWGRP.Pocket.RefreshDropZone()
	local frame = SWGRP.Pocket.Menu
	if not IsValid( frame ) or not IsValid( frame.DropZone ) then return end

	local active = SWGRP.Pocket.SelectedSlot ~= nil
	frame.DropZone.SWGRP_Active = active
	frame.DropZone:SetCursor( active and "hand" or "arrow" )
end

function SWGRP.Pocket.RefreshPocket()
	local pocketHost = SWGRP.Pocket.PocketHost
	if not IsValid( pocketHost ) then return end

	initSlots()

	if not IsValid( SWGRP.Pocket.PocketGrid ) then
		local grid = vgui.Create( "DIconLayout", pocketHost )
		grid:Dock( FILL )
		grid:SetSpaceX( SWGRP.UI.Spacing.gap )
		grid:SetSpaceY( SWGRP.UI.Spacing.gap )
		SWGRP.Pocket.PocketGrid = grid

		SWGRP.Pocket.SlotPanels = {}
		for i = 1, POCKET_MAX do
			makePocketSlot( grid, i )
		end
	end

	for i = 1, POCKET_MAX do
		local slot = SWGRP.Pocket.SlotPanels[i]
		local item = SWGRP.Pocket.Slots[i]
		if IsValid( slot ) then
			if slotHasItem( item ) then
				paintFilledSlot( slot, i, item )
			else
				paintEmptySlot( slot, i )
			end
		end
	end

	SWGRP.Pocket.RefreshHighlights()
end

local function invScrollHeight( itemCount )
	local UI = SWGRP.UI
	local gap = UI and UI.Spacing.gap or 12
	local rows = math.max( 1, math.min( INV_VISIBLE_ROWS, math.ceil( itemCount / 4 ) ) )
	return rows * SLOT_SIZE + math.max( 0, rows - 1 ) * gap + 8
end

function SWGRP.Pocket.UpdateInvScrollHeight( itemCount )
	local invHost = SWGRP.Pocket.InvHost
	if not IsValid( invHost ) then return end
	invHost:SetTall( invScrollHeight( itemCount or 1 ) )
end

function SWGRP.Pocket.RefreshInventory()
	local invHost = SWGRP.Pocket.InvHost
	if not IsValid( invHost ) then return end

	if IsValid( SWGRP.Pocket.InvLayout ) then
		SWGRP.Pocket.InvLayout:Remove()
	end

	local invCanvas = invHost.GetCanvas and invHost:GetCanvas() or invHost
	local invLayout = vgui.Create( "DIconLayout", invCanvas )
	invLayout:Dock( TOP )
	invLayout:SetSpaceX( SWGRP.UI.Spacing.gap )
	invLayout:SetSpaceY( SWGRP.UI.Spacing.gap )
	SWGRP.Pocket.InvLayout = invLayout

	local ply = LocalPlayer()
	local hasWeapons = false
	local weaponCount = 0
	if IsValid( ply ) then
		for _, wep in ipairs( ply:GetWeapons() ) do
			if IsValid( wep ) then
				local class = wep:GetClass()
				if not BLOCKED[class] then
					makeInventoryWeapon( invLayout, class )
					hasWeapons = true
					weaponCount = weaponCount + 1
				end
			end
		end
	end

	if not hasWeapons then
		local empty = vgui.Create( "DLabel", invLayout )
		empty:SetSize( 360, 28 )
		empty:SetFont( "DermaDefault" )
		empty:SetTextColor( SWGRP.UI.Colors.secondary )
		empty:SetText( "No pocketable weapons equipped." )
	end

	SWGRP.Pocket.UpdateInvScrollHeight( weaponCount > 0 and weaponCount or 1 )
	SWGRP.Pocket.RefreshHighlights()
end

function SWGRP.Pocket.RebuildMenu()
	if not IsValid( SWGRP.Pocket.Menu ) then return end
	SWGRP.Pocket.RefreshPocket()
	SWGRP.Pocket.RefreshInventory()
	SWGRP.Pocket.UpdateStatusBar()
	SWGRP.Pocket.RefreshDropZone()
end

function SWGRP.Pocket.OpenMenu()
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end
	if IsValid( SWGRP.Pocket.Menu ) then return end

	initSlots()
	SWGRP.Pocket.ClearSelection()
	SWGRP.Pocket.SlotPanels = {}

	UI.SyncColors()

	local frame = UI.CreateTerminalFrame( "POCKET", 540, 680 )
	SWGRP.Pocket.Menu = frame

	frame.OnRemove = function()
		SWGRP.Pocket.Menu = nil
		SWGRP.Pocket.PocketGrid = nil
		SWGRP.Pocket.InvLayout = nil
		SWGRP.Pocket.SlotPanels = {}
		SWGRP.Pocket.ClearSelection()
	end

	local body = vgui.Create( "DPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end

	-- Reserve bottom chrome first so TOP panels are not squeezed later.
	local bottomBar = vgui.Create( "DPanel", body )
	bottomBar:Dock( BOTTOM )
	bottomBar:SetTall( 72 )
	bottomBar:DockMargin( 0, UI.Spacing.gap, 0, 0 )
	bottomBar.Paint = function() end

	local footer = UI.CreateLabel( bottomBar, "T — toggle pocket  •  Alt+T — quick-store what you're aiming at", "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( footer ) then footer:DockMargin( 0, 0, 0, 6 ) end

	local dropZone = vgui.Create( "DPanel", bottomBar )
	dropZone:Dock( BOTTOM )
	dropZone:SetTall( 36 )
	dropZone:SetCursor( "arrow" )
	dropZone.SWGRP_Active = false
	frame.DropZone = dropZone

	dropZone.Paint = function( self, w, h )
		local active = self.SWGRP_Active
		local bg = active and UI.Colors.bgLight or Color( UI.Colors.bgLight.r, UI.Colors.bgLight.g, UI.Colors.bgLight.b, 140 )
		surface.SetDrawColor( bg )
		surface.DrawRect( 0, 0, w, h )

		local border = active and UI.Colors.danger or UI.Colors.borderDim
		surface.SetDrawColor( border.r, border.g, border.b, active and 200 or 100 )
		surface.DrawOutlinedRect( 0, 0, w, h, 1 )

		local text = active and "Click to drop selected item" or "Select a pocket slot to drop"
		local col = active and UI.Colors.danger or UI.Colors.secondary
		draw.SimpleText( text, "DermaDefault", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	dropZone:Receiver( { "SWGRP_PocketItem" }, function( _, panels, dropped )
		if not dropped then return end
		local drag = panels[1]
		if drag and drag.SWGRP_PocketSlot then
			dropSlot( drag.SWGRP_PocketSlot )
			SWGRP.Pocket.ClearSelection()
		end
	end )

	function dropZone:OnMousePressed( mc )
		if mc ~= MOUSE_LEFT or not self.SWGRP_Active then return end
		if SWGRP.Pocket.SelectedSlot then
			dropSlot( SWGRP.Pocket.SelectedSlot )
			SWGRP.Pocket.ClearSelection()
		end
	end

	local pocketTitle = UI.CreateLabel( body, "Pocket", "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( pocketTitle ) then pocketTitle:DockMargin( 0, 0, 0, 4 ) end

	local pocketHint = UI.CreateLabel( body, "Drag items between slots, or double-click a slot to drop.", "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( pocketHint ) then pocketHint:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local status = UI.CreateLabel( body, "", "DermaDefault", UI.Colors.accent, TOP )
	if IsValid( status ) then
		status:DockMargin( 0, 0, 0, UI.Spacing.gap )
		frame.StatusLabel = status
	end

	local pocketHost = vgui.Create( "DPanel", body )
	pocketHost:Dock( TOP )
	pocketHost:SetTall( SLOT_SIZE * 2 + UI.Spacing.gap + 8 )
	pocketHost:DockMargin( 0, 0, 0, UI.Spacing.gapLarge )
	pocketHost.Paint = function() end
	SWGRP.Pocket.PocketHost = pocketHost

	local invTitle = UI.CreateLabel( body, "Equipped weapons", "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( invTitle ) then invTitle:DockMargin( 0, 0, 0, 4 ) end

	local invHint = UI.CreateLabel( body, "Click a weapon, then click an empty pocket slot to store it.", "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( invHint ) then invHint:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local invScroll = vgui.Create( "DScrollPanel", body )
	invScroll:Dock( TOP )
	invScroll:SetTall( invScrollHeight( 1 ) )
	UI.StyleScrollPanel( invScroll )
	SWGRP.Pocket.InvHost = invScroll

	requestSync()
	SWGRP.Pocket.RefreshPocket()
	SWGRP.Pocket.RefreshInventory()
	SWGRP.Pocket.UpdateStatusBar()
	SWGRP.Pocket.RefreshDropZone()
end

function SWGRP.Pocket.ToggleMenu()
	if IsValid( SWGRP.Pocket.Menu ) then
		SWGRP.Pocket.Menu:Remove()
		return
	end

	SWGRP.Pocket.OpenMenu()
end

local function pocketKeyPressed( ply )
	if ply ~= LocalPlayer() then return end
	if not IsValid( ply ) or not ply:Alive() then return end
	if gui.IsConsoleVisible() or ply:IsTyping() then return end
	if IsValid( vgui.GetKeyboardFocus() ) then return end

	if input.IsKeyDown( KEY_LALT ) or input.IsKeyDown( KEY_RALT ) then
		quickStore()
	else
		SWGRP.Pocket.ToggleMenu()
	end
end

hook.Add( "PlayerButtonDown", "SWGRP_PocketKey", function( ply, btn )
	if btn ~= KEY_T then return end
	pocketKeyPressed( ply )
end )

net.Receive( "SWGRP_PocketOpen", function()
	SWGRP.Pocket.ToggleMenu()
end )

concommand.Add( "swgrp_pocket_menu", SWGRP.Pocket.ToggleMenu )

initSlots()

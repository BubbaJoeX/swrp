--[[---------------------------------------------------------------------------
    SWGRP Terminal VGUI - Unified HUD amber terminal theme
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.UI = SWGRP.UI or {}

local UI = SWGRP.UI

UI.Spacing = {
	frame      = 14,
	sheet      = 12,
	subSheet   = 14,
	panel      = 18,
	gap        = 12,
	gapLarge   = 18,
	listWidth  = 310,
	listItem   = 68,
	tabHeight  = 38,
	subTabHeight = 34,
	tabGap     = 14,
	subTabGap  = 12,
	button     = 44,
	input      = 34,
	preview    = 290,
}

UI.Colors = {
	bg         = Color( 10, 15, 25, 245 ),
	bgLight    = Color( 18, 24, 38, 230 ),
	bgHover    = Color( 28, 36, 52, 240 ),
	bgTabBar   = Color( 8, 12, 20, 255 ),
	border     = Color( 255, 180, 50, 200 ),
	borderDim  = Color( 255, 180, 50, 80 ),
	primary    = Color( 255, 180, 50 ),
	secondary  = Color( 200, 200, 200 ),
	accent     = Color( 80, 200, 255 ),
	danger     = Color( 255, 60, 60 ),
	shadow     = Color( 0, 0, 0, 150 ),
	previewBg  = Color( 5, 8, 14, 255 ),
}

-- True while any full-screen SWGRP terminal (F4 shop, F3 datapad, scoreboard)
-- is open, so the HUD can stand down and avoid bleeding text through the menu.
function UI.IsTerminalOpen()
	return IsValid( SWGRP.F4Frame ) or IsValid( SWGRP.ServicesFrame ) or IsValid( SWGRP.Scoreboard ) or IsValid( SWGRP.Pocket and SWGRP.Pocket.Menu )
end

-- Floating billboard label drawn above a world entity so SWGRP service props
-- (ATM, terminals, dispensers) stand out from ordinary map clutter. Call from
-- an entity's clientside Draw. Yaws to face the viewer while staying upright,
-- matching the 3D2D convention used by other SWGRP world entities, and fades
-- out with distance so it isn't visible across the whole map.
function UI.DrawWorldLabel( ent, title, subtitle, accent, labelPos )
	if not IsValid( ent ) then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local pos = labelPos or ( ent:GetPos() + Vector( 0, 0, ent:OBBMaxs().z + 16 ) )

	local dist = ply:EyePos():Distance( pos )
	if dist > 800 then return end
	local alpha = math.Clamp( ( 800 - dist ) / 250, 0, 1 ) * 255

	accent = accent or UI.Colors.primary

	local ang = ply:EyeAngles()
	ang:RotateAroundAxis( ang:Forward(), 90 )
	ang:RotateAroundAxis( ang:Right(), 90 )

	surface.SetFont( "DermaLarge" )
	local tw = surface.GetTextSize( title )
	local sw = 0
	local hasSub = subtitle ~= nil and subtitle ~= ""
	if hasSub then
		surface.SetFont( "DermaDefaultBold" )
		sw = surface.GetTextSize( subtitle )
	end

	local boxW = math.max( tw, sw ) + 44
	local boxH = hasSub and 60 or 42

	cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.12 )
		draw.RoundedBox( 8, -boxW / 2, -boxH / 2, boxW, boxH, Color( 10, 15, 25, alpha * 0.82 ) )
		surface.SetDrawColor( accent.r, accent.g, accent.b, alpha )
		surface.DrawOutlinedRect( -boxW / 2, -boxH / 2, boxW, boxH, 2 )

		draw.SimpleText( title, "DermaLarge", 0, hasSub and -9 or 0, Color( accent.r, accent.g, accent.b, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if hasSub then
			draw.SimpleText( subtitle, "DermaDefaultBold", 0, 16, Color( 220, 220, 220, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	cam.End3D2D()
end

function UI.SyncColors()
	if SWGRP.Config then
		UI.Colors.primary   = SWGRP.Config.HUDColorPrimary or UI.Colors.primary
		UI.Colors.secondary = SWGRP.Config.HUDColorSecondary or UI.Colors.secondary
		UI.Colors.accent    = SWGRP.Config.HUDColorAccent or UI.Colors.accent
		UI.Colors.danger    = SWGRP.Config.HUDColorDanger or UI.Colors.danger
		UI.Colors.border    = Color( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 200 )
		UI.Colors.borderDim = Color( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 80 )
	end
end

function UI.PaintTerminalPanel( self, w, h )
	UI.SyncColors()
	surface.SetDrawColor( UI.Colors.bg )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( UI.Colors.borderDim )
	surface.DrawOutlinedRect( 0, 0, w, h, 1 )
end

function UI.PaintListItem( self, w, h )
	UI.SyncColors()
	local col = self.Selected and UI.Colors.bgHover or UI.Colors.bgLight
	if self.Hovered and not self.Selected then
		col = Color( col.r + 10, col.g + 10, col.b + 14, col.a )
	end

	surface.SetDrawColor( col )
	surface.DrawRect( 2, 2, w - 4, h - 4 )

	if self.Selected then
		surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 90 )
		surface.DrawRect( 2, 2, 4, h - 4 )
		surface.SetDrawColor( UI.Colors.border )
		surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )
	end

	if self.ItemColor then
		surface.SetDrawColor( self.ItemColor.r, self.ItemColor.g, self.ItemColor.b, 50 )
		surface.DrawRect( w - 8, 2, 6, h - 4 )
	end
end

function UI.PaintTerminalButton( self, w, h )
	UI.SyncColors()
	local col = UI.Colors.bgLight
	if self:IsHovered() then col = UI.Colors.bgHover end
	if not self:IsEnabled() then col = Color( 20, 20, 20, 200 ) end

	surface.SetDrawColor( col )
	surface.DrawRect( 2, 2, w - 4, h - 4 )
	surface.SetDrawColor( UI.Colors.borderDim )
	surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )

	if self:IsHovered() and self:IsEnabled() then
		surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 40 )
		surface.DrawRect( 2, 2, w - 4, h - 4 )
	end

	local textCol = self:IsEnabled() and UI.Colors.primary or UI.Colors.secondary
	local label = UI.TruncateText( self.LabelText or "", "DermaDefaultBold", w - 16 )
	draw.SimpleText( label, "DermaDefaultBold", w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

function UI.PaintTerminalFrame( self, w, h )
	UI.SyncColors()
	surface.SetDrawColor( UI.Colors.bg )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( UI.Colors.border )
	surface.DrawOutlinedRect( 0, 0, w, h, 2 )

	surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, 35 )
	surface.DrawRect( 0, 0, w, 36 )

	surface.SetDrawColor( UI.Colors.borderDim )
	surface.DrawRect( 0, 36, w, 1 )

	draw.SimpleText( self:GetTitle() or "", "DermaDefaultBold", UI.Spacing.frame, 18, UI.Colors.primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end

function UI.PaintPreviewPanel( self, w, h )
	UI.SyncColors()
	surface.SetDrawColor( UI.Colors.previewBg )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( UI.Colors.borderDim )
	surface.DrawOutlinedRect( 0, 0, w, h, 1 )
end

function UI.PaintSectionHeader( self, w, h )
	UI.SyncColors()
	surface.SetDrawColor( UI.Colors.bg )
	surface.DrawRect( 0, h - 1, w, 1 )
	draw.SimpleText( self.HeaderText or "", "DermaDefaultBold", 4, h / 2, UI.Colors.primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end

function UI.StyleScrollPanel( scroll )
	if not IsValid( scroll ) then return end
	scroll.Paint = UI.PaintTerminalPanel

	local bar = scroll:GetVBar()
	if IsValid( bar ) then
		bar:SetWide( 10 )
		bar.Paint = function( s, w, h )
			surface.SetDrawColor( UI.Colors.bg )
			surface.DrawRect( 0, 0, w, h )
		end
		bar.btnUp.Paint = function() end
		bar.btnDown.Paint = function() end
		bar.btnGrip.Paint = function( s, w, h )
			surface.SetDrawColor( UI.Colors.bgHover )
			surface.DrawRect( 2, 2, w - 4, h - 4 )
			surface.SetDrawColor( UI.Colors.borderDim )
			surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )
		end
	end
end

function UI.TruncateText( text, font, maxWidth )
	text = text or ""
	if maxWidth <= 0 then return "" end

	surface.SetFont( font )
	if surface.GetTextSize( text ) <= maxWidth then
		return text
	end

	local ellipsis = "..."
	local ellW = surface.GetTextSize( ellipsis )
	local out = ""

	for i = 1, #text do
		local candidate = string.sub( text, 1, i )
		if surface.GetTextSize( candidate ) + ellW > maxWidth then
			return out .. ellipsis
		end
		out = candidate
	end

	return text
end

function UI.CreateLabel( parent, text, font, color, dock )
	if not IsValid( parent ) then return end

	local lbl = vgui.Create( "DLabel", parent )
	if not IsValid( lbl ) then return end

	lbl:SetText( text or "" )
	lbl:SetFont( font or "DermaDefault" )
	lbl:SetTextColor( color or UI.Colors.secondary )
	if dock then lbl:Dock( dock ) end
	lbl:SetWrap( true )
	lbl:SetAutoStretchVertical( true )
	return lbl
end

function UI.CreateSectionHeader( parent, text, opts )
	opts = opts or {}
	local hdr = vgui.Create( "DPanel", parent )
	hdr:Dock( TOP )
	hdr:SetTall( 30 )
	hdr:DockMargin( 0, opts.first and UI.Spacing.gap or UI.Spacing.gapLarge, 0, UI.Spacing.gap )
	hdr.HeaderText = text
	hdr.Paint = UI.PaintSectionHeader
	return hdr
end

function UI.CreateButton( parent, text, onClick )
	if not IsValid( parent ) then return end

	local btn = vgui.Create( "DButton", parent )
	if not IsValid( btn ) then return end

	-- Suppress the native DButton label (it renders on top of our custom Paint,
	-- which caused doubled/overlapping text) and store the caption ourselves so
	-- callers can still use :SetText() to update it.
	btn:SetText( "" )
	btn.LabelText = text or "Select"
	function btn:SetText( newText )
		self.LabelText = newText or ""
	end

	btn:SetTall( UI.Spacing.button )
	btn.Paint = UI.PaintTerminalButton
	btn.DoClick = onClick or function() end
	return btn
end

function UI.StyleTextEntry( entry )
	entry:SetTall( UI.Spacing.input )
	entry.Paint = function( self, w, h )
		UI.SyncColors()
		surface.SetDrawColor( UI.Colors.bgLight )
		surface.DrawRect( 2, 2, w - 4, h - 4 )
		surface.SetDrawColor( UI.Colors.borderDim )
		surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )
		self:DrawTextEntryText( UI.Colors.secondary, UI.Colors.accent, UI.Colors.secondary )
	end
end

function UI.SetupModelPreview( mdlPanel, modelPath, itemColor )
	if not IsValid( mdlPanel ) then return end

	if SWGRP.ModelMap and SWGRP.ModelMap.Resolve then
		modelPath = SWGRP.ModelMap.Resolve( modelPath, SWGRP.ModelMap.Defaults.player )
	else
		modelPath = modelPath or "models/player/group01/male_01.mdl"
		if CLIENT and not util.IsValidModel( modelPath ) then
			modelPath = "models/player/group01/male_01.mdl"
		end
	end

	local fov = 36
	mdlPanel:SetModel( modelPath )
	mdlPanel:SetFOV( fov )
	mdlPanel:SetAnimated( true )
	mdlPanel:SetAmbientLight( Color( 80, 90, 110 ) )
	mdlPanel:SetDirectionalLight( BOX_TOP, Color( 255, 220, 160 ) )
	mdlPanel:SetDirectionalLight( BOX_FRONT, Color( 180, 200, 255 ) )

	-- Frame the model inside LayoutEntity so the render bounds are valid (they
	-- are still zeroed immediately after SetModel, which previously zoomed the
	-- camera onto the model's feet). Recomputed each frame; bounds are in local
	-- space so this stays stable while the model spins.
	mdlPanel.LayoutEntity = function( panel, entity )
		if not IsValid( entity ) then return end
		entity:SetAngles( Angle( 0, RealTime() * 28, 0 ) )

		local mn, mx = entity:GetRenderBounds()
		local center = ( mn + mx ) * 0.5
		local radius = math.max( ( mx - mn ):Length() * 0.5, 16 )

		-- The panel is wider than it is tall, so the vertical FOV is narrower
		-- than the configured (horizontal) FOV. Fit the bounding sphere to the
		-- narrower of the two so the head/feet are never clipped.
		local pw, ph = panel:GetWide(), panel:GetTall()
		local aspect = ( pw > 0 and ph > 0 ) and ( pw / ph ) or 1
		local fovRad = math.rad( fov )
		local altFov = 2 * math.atan( math.tan( fovRad * 0.5 ) / math.max( aspect, 0.0001 ) )
		local fitFov = math.min( fovRad, altFov )
		local dist = radius / math.sin( fitFov * 0.5 ) * 1.1

		local dir = Vector( 1, 0.4, 0.05 )
		dir:Normalize()

		panel:SetCamPos( center + dir * dist )
		panel:SetLookAt( center )
	end
end

function UI.StyleSheet( sheet, opts )
	if not IsValid( sheet ) then return end
	opts = opts or {}

	UI.SyncColors()

	local tabH = opts.subTab and UI.Spacing.subTabHeight or ( opts.compact and 32 or UI.Spacing.tabHeight )
	local tabGap = opts.subTab and UI.Spacing.subTabGap or ( opts.compact and 8 or UI.Spacing.tabGap )
	local font = ( opts.compact or opts.subTab ) and "DermaDefault" or "DermaDefaultBold"
	local minTabW = opts.compact and 78 or ( opts.subTab and 92 or 108 )

	sheet.Paint = function( panel, w, h )
		surface.SetDrawColor( UI.Colors.bgLight )
		surface.DrawRect( 0, 0, w, h )
	end

	if IsValid( sheet.tabScroller ) then
		sheet.tabScroller:DockMargin( opts.subTab and UI.Spacing.subSheet or UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, 0 )
		-- Tabs are docked inside a DHorizontalScroller, so spacing is controlled
		-- by the scroller overlap (positive = gap), not by per-tab DockMargin.
		if sheet.tabScroller.SetOverlap then
			sheet.tabScroller:SetOverlap( tabGap )
		end
	end

	surface.SetFont( font )

	for _, tab in pairs( sheet.Items or {} ) do
		if IsValid( tab.Tab ) then
			local t = tab.Tab

			-- Hide the default DTab icon/label; our Paint draws the amber label.
			if IsValid( t.Image ) then t.Image:SetVisible( false ) end
			t:SetText( "" )

			local tw = surface.GetTextSize( tab.Name or "" )
			local tabW = math.max( tw + 28, minTabW )

			t:SetSize( tabW, tabH )

			-- Lock the size: DTab:ApplySchemeSettings/SizeToContents would otherwise
			-- shrink an empty-text tab down to icon width, crushing them together.
			t.ApplySchemeSettings = function() end
			t.PerformLayout = function( s )
				s:SetWide( tabW )
				s:SetTall( tabH )
			end

			t.Paint = function( tabPanel, w, h )
				local active = sheet:GetActiveTab() == tab
				local col = active and UI.Colors.bgHover or UI.Colors.bg
				surface.SetDrawColor( col )
				surface.DrawRect( 0, 2, w, h - 4 )

				if active then
					surface.SetDrawColor( UI.Colors.primary )
					surface.DrawRect( 0, h - 4, w, 2 )
					surface.SetDrawColor( UI.Colors.border )
					surface.DrawOutlinedRect( 0, 2, w, h - 4, 1 )
				else
					surface.SetDrawColor( UI.Colors.borderDim )
					surface.DrawOutlinedRect( 0, 2, w, h - 4, 1 )
				end

				local label = UI.TruncateText( tab.Name or "", font, w - 12 )
				draw.SimpleText( label, font, w / 2, h / 2, active and UI.Colors.primary or UI.Colors.secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end

		if IsValid( tab.Panel ) then
			tab.Panel:DockMargin( 0, UI.Spacing.gap, 0, 0 )
			tab.Panel:DockPadding( opts.subTab and UI.Spacing.subSheet or UI.Spacing.sheet, UI.Spacing.gap, UI.Spacing.sheet, UI.Spacing.sheet )
		end
	end

	if IsValid( sheet.tabScroller ) then
		sheet.tabScroller:InvalidateLayout( true )
	end
	sheet:InvalidateLayout( true )
end

function UI.CreateCatalog( parent )
	local container = parent or vgui.Create( "DPanel" )
	if not parent then
		container.Paint = function() end
	end

	local body = vgui.Create( "DPanel", container )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )
	body.Paint = function() end

	local list = vgui.Create( "DScrollPanel", body )
	list:Dock( LEFT )
	list:SetWide( UI.Spacing.listWidth )
	list:DockMargin( 0, 0, UI.Spacing.gapLarge, 0 )
	UI.StyleScrollPanel( list )

	local preview = vgui.Create( "DPanel", body )
	preview:Dock( FILL )
	preview.Paint = UI.PaintTerminalPanel

	local previewInner = vgui.Create( "DPanel", preview )
	previewInner:Dock( FILL )
	previewInner:DockMargin( UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel )
	previewInner.Paint = function() end

	local modelHolder = vgui.Create( "DPanel", previewInner )
	modelHolder:Dock( TOP )
	modelHolder:SetTall( UI.Spacing.preview )
	modelHolder:DockMargin( 0, 0, 0, UI.Spacing.gap )
	modelHolder.Paint = UI.PaintPreviewPanel

	local modelPreview = vgui.Create( "DModelPanel", modelHolder )
	modelPreview:Dock( FILL )
	modelPreview:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )

	local actionBtn = UI.CreateButton( previewInner, "Select" )
	actionBtn:Dock( BOTTOM )
	actionBtn:DockMargin( 0, UI.Spacing.gap, 0, 0 )
	actionBtn:SetEnabled( false )

	local detailScroll = vgui.Create( "DScrollPanel", previewInner )
	detailScroll:Dock( FILL )
	detailScroll:DockMargin( 0, 0, 0, UI.Spacing.gap )
	UI.StyleScrollPanel( detailScroll )

	local title = UI.CreateLabel( detailScroll, "Select an item", "DermaDefaultBold", UI.Colors.primary, TOP )
	title:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )

	local subtitle = UI.CreateLabel( detailScroll, "", "DermaDefault", UI.Colors.accent, TOP )
	subtitle:DockMargin( UI.Spacing.gap, 0, UI.Spacing.gap, UI.Spacing.gap )

	local price = UI.CreateLabel( detailScroll, "", "DermaDefaultBold", UI.Colors.primary, TOP )
	price:DockMargin( UI.Spacing.gap, 0, UI.Spacing.gap, UI.Spacing.gap )

	local desc = UI.CreateLabel( detailScroll, "", "DermaDefault", UI.Colors.secondary, TOP )
	desc:DockMargin( UI.Spacing.gap, 0, UI.Spacing.gap, UI.Spacing.gap )

	local catalog = {
		container = container,
		list = list,
		preview = preview,
		modelPreview = modelPreview,
		title = title,
		subtitle = subtitle,
		desc = desc,
		price = price,
		actionBtn = actionBtn,
		items = {},
		selected = nil,
	}

	function catalog:SelectItem( item, btn )
		if self.selected and self.selected.button then
			self.selected.button.Selected = false
		end

		self.selected = item
		if btn then
			btn.Selected = true
			item.button = btn
		end

		self.title:SetText( item.name or "Unknown" )
		self.subtitle:SetText( item.subtitle or "" )
		self.desc:SetText( item.description or "" )
		self.price:SetText( item.priceText or "" )

		UI.SetupModelPreview( self.modelPreview, item.model, item.color )

		if item.actionText then
			self.actionBtn:SetText( item.actionText )
		end

		self.actionBtn:SetEnabled( item.onAction ~= nil )
		self.actionBtn.DoClick = function()
			if item.onAction then item.onAction() end
		end
	end

	function catalog:AddItem( item )
		table.insert( self.items, item )

		local row = vgui.Create( "DButton", self.list )
		row:Dock( TOP )
		row:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, 0 )
		row:SetTall( UI.Spacing.listItem )
		row:SetText( "" )
		row.ItemColor = item.color
		row.Paint = UI.PaintListItem

		row.PaintOver = function( s, w, h )
			local name = UI.TruncateText( item.name or "", "DermaDefaultBold", w - 28 )
			local sub = UI.TruncateText( item.listSub or item.priceText or "", "DermaDefault", w - 28 )
			draw.SimpleText( name, "DermaDefaultBold", 14, 18, UI.Colors.primary, TEXT_ALIGN_LEFT )
			draw.SimpleText( sub, "DermaDefault", 14, 42, UI.Colors.secondary, TEXT_ALIGN_LEFT )
		end

		row.DoClick = function( s )
			self:SelectItem( item, s )
		end

		item.button = row
	end

	function catalog:AutoSelectFirst()
		if self.items[1] then
			self:SelectItem( self.items[1], self.items[1].button )
		end
	end

	return catalog, container
end

function UI.CreateCatalogTab( sheet, tabName, icon )
	local catalog, container = UI.CreateCatalog()
	container:DockPadding( 0, 0, 0, 0 )
	sheet:AddSheet( tabName, container, icon or "icon16/application.png" )
	return catalog
end

function UI.PaintFactionButton( self, w, h )
	UI.SyncColors()
	local col = self.Selected and UI.Colors.bgHover or UI.Colors.bgLight
	if self.Hovered and not self.Selected then
		col = UI.Colors.bgHover
	end

	surface.SetDrawColor( col )
	surface.DrawRect( 2, 2, w - 4, h - 4 )

	if self.FactionColor then
		surface.SetDrawColor( self.FactionColor.r, self.FactionColor.g, self.FactionColor.b, 70 )
		surface.DrawRect( 2, 2, 5, h - 4 )
	end

	if self.Selected then
		surface.SetDrawColor( UI.Colors.primary )
		surface.DrawRect( 2, h - 4, w - 4, 2 )
		surface.SetDrawColor( UI.Colors.border )
		surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )
	else
		surface.SetDrawColor( UI.Colors.borderDim )
		surface.DrawOutlinedRect( 2, 2, w - 4, h - 4, 1 )
	end

	local label = UI.TruncateText( self.FactionName or "", "DermaDefaultBold", w - 20 )
	draw.SimpleText( label, "DermaDefaultBold", 14, h / 2, self.Selected and UI.Colors.primary or UI.Colors.secondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end

function UI.CreateFactionCatalogTab( sheet, tabName, icon )
	local container = vgui.Create( "DPanel" )
	container.Paint = function() end

	local body = vgui.Create( "DPanel", container )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )
	body.Paint = function() end

	local factionRail = vgui.Create( "DPanel", body )
	factionRail:Dock( LEFT )
	factionRail:SetWide( 140 )
	factionRail:DockMargin( 0, 0, UI.Spacing.gapLarge, 0 )
	factionRail.Paint = UI.PaintTerminalPanel

	local factionScroll = vgui.Create( "DScrollPanel", factionRail )
	factionScroll:Dock( FILL )
	factionScroll:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )
	UI.StyleScrollPanel( factionScroll )

	local catalog, catalogHost = UI.CreateCatalog( body )
	catalogHost:Dock( FILL )

	sheet:AddSheet( tabName, container, icon or "icon16/group.png" )

	local factionCatalog = {
		catalog = catalog,
		factions = {},
		activeId = nil,
		buttons = {},
	}

	function factionCatalog:ClearList()
		self.catalog.list:Clear()
		self.catalog.items = {}
		self.catalog.selected = nil
		self.catalog.title:SetText( "Select an item" )
		self.catalog.subtitle:SetText( "" )
		self.catalog.desc:SetText( "" )
		self.catalog.price:SetText( "" )
		self.catalog.actionBtn:SetEnabled( false )
		UI.SetupModelPreview( self.catalog.modelPreview, SWGRP.ModelMap and SWGRP.ModelMap.Defaults.player or "models/player/group01/male_01.mdl" )
	end

	function factionCatalog:SelectFaction( id )
		local faction = self.factions[id]
		if not faction then return end

		if self.activeId and self.buttons[self.activeId] then
			self.buttons[self.activeId].Selected = false
		end

		self.activeId = id
		if self.buttons[id] then
			self.buttons[id].Selected = true
		end

		self:ClearList()

		if faction.populate then
			faction.populate( self.catalog )
		end

		self.catalog:AutoSelectFirst()
	end

	function factionCatalog:AddFaction( id, name, color, populateFn )
		self.factions[id] = {
			name = name,
			color = color,
			populate = populateFn,
		}

		local btn = vgui.Create( "DButton", factionScroll )
		btn:Dock( TOP )
		btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		btn:SetTall( UI.Spacing.button )
		btn:SetText( "" )
		btn.FactionName = name
		btn.FactionColor = color
		btn.Paint = UI.PaintFactionButton
		btn.DoClick = function()
			self:SelectFaction( id )
		end

		self.buttons[id] = btn

		if not self.activeId then
			self:SelectFaction( id )
		end
	end

	return factionCatalog
end

function UI.CreateTabPanel( sheet, tabName, icon )
	local container = vgui.Create( "DPanel" )
	container.Paint = UI.PaintTerminalPanel

	local inner = vgui.Create( "DPanel", container )
	inner:Dock( FILL )
	inner:DockMargin( UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel )
	inner.Paint = function() end

	sheet:AddSheet( tabName, container, icon or "icon16/application.png" )
	return inner
end

function UI.CreateSimpleListTab( sheet, tabName, icon )
	local container = vgui.Create( "DPanel" )
	container.Paint = UI.PaintTerminalPanel

	local scroll = vgui.Create( "DScrollPanel", container )
	scroll:Dock( FILL )
	scroll:DockMargin( UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel, UI.Spacing.panel )
	UI.StyleScrollPanel( scroll )

	sheet:AddSheet( tabName, container, icon or "icon16/application.png" )
	return scroll
end

function UI.AddListButton( scroll, text, tooltip, onClick )
	local btn = UI.CreateButton( scroll, text, onClick )
	if not IsValid( btn ) then return end
	btn:Dock( TOP )
	btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
	if tooltip then btn:SetTooltip( tooltip ) end
	return btn
end

function UI.CreateTerminalFrame( title, w, h )
	UI.SyncColors()

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( w, h )
	frame:Center()
	frame:SetTitle( title or "Terminal" )
	frame:SetDraggable( true )
	frame:ShowCloseButton( true )
	frame:MakePopup()
	frame.Paint = UI.PaintTerminalFrame

	if IsValid( frame.lblTitle ) then
		frame.lblTitle:SetVisible( false )
	end

	return frame
end

function UI.RegisterSheet( sheet, opts )
	if not IsValid( sheet ) then return end
	UI.StyleSheet( sheet, opts )
	table.insert( UI._styledSheets or {}, { sheet = sheet, opts = opts } )
end

UI._styledSheets = UI._styledSheets or {}

function UI.RefreshAllSheets()
	UI._styledSheets = UI._styledSheets or {}
	for _, entry in ipairs( UI._styledSheets ) do
		if IsValid( entry.sheet ) then
			UI.StyleSheet( entry.sheet, entry.opts )
		end
	end
end

function UI.OpenJobModelPicker( job, onConfirm )
	local models = SWGRP.GetJobModels( job )
	if #models <= 1 then
		onConfirm( 1 )
		return
	end

	local frame = UI.CreateTerminalFrame( "SELECT APPEARANCE", 520, 420 )
	local body = vgui.Create( "DPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end

	local title = UI.CreateLabel( body, "Choose a model for " .. ( job.name or "profession" ), "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( title ) then
		title:DockMargin( 0, 0, 0, UI.Spacing.gap )
	end

	local scroll = vgui.Create( "DScrollPanel", body )
	scroll:Dock( FILL )
	scroll:DockMargin( 0, 0, 0, UI.Spacing.gap )
	UI.StyleScrollPanel( scroll )

	local grid = vgui.Create( "DIconLayout", scroll )
	grid:Dock( TOP )
	grid:SetSpaceX( UI.Spacing.gap )
	grid:SetSpaceY( UI.Spacing.gap )

	for idx, mdl in ipairs( models ) do
		local tile = grid:Add( "DPanel" )
		tile:SetSize( 140, 170 )
		tile.Paint = UI.PaintTerminalPanel

		local preview = vgui.Create( "DModelPanel", tile )
		preview:Dock( FILL )
		preview:DockMargin( 4, 4, 4, 28 )
		UI.SetupModelPreview( preview, mdl, job.color )

		local pick = UI.CreateButton( tile, "Select", function()
			frame:Close()
			onConfirm( idx )
		end )
		pick:SetTall( 24 )
		pick:Dock( BOTTOM )
		pick:DockMargin( 4, 0, 4, 4 )
	end

	local cancel = UI.CreateButton( body, "Cancel", function()
		frame:Close()
	end )
	if IsValid( cancel ) then
		cancel:Dock( BOTTOM )
	end
end

--[[---------------------------------------------------------------------------
    HUD drawing helpers (client)
---------------------------------------------------------------------------]]

if CLIENT then
	UI.HUD = UI.HUD or {}

	local HUD = UI.HUD

	function HUD.EnsureFonts()
		if HUD._fontsReady then return end
		HUD._fontsReady = true

		surface.CreateFont( "SWGRP_HUD_Title", {
			font = "Tahoma", size = 18, weight = 800, antialias = true, extended = true,
		} )
		surface.CreateFont( "SWGRP_HUD_Subtitle", {
			font = "Tahoma", size = 14, weight = 700, antialias = true, extended = true,
		} )
		surface.CreateFont( "SWGRP_HUD_Body", {
			font = "Tahoma", size = 13, weight = 500, antialias = true, extended = true,
		} )
		surface.CreateFont( "SWGRP_HUD_Small", {
			font = "Tahoma", size = 11, weight = 600, antialias = true, extended = true,
		} )
		surface.CreateFont( "SWGRP_HUD_Micro", {
			font = "Tahoma", size = 10, weight = 700, antialias = true, extended = true,
		} )
	end

	function HUD.Sync()
		UI.SyncColors()
		HUD.EnsureFonts()
	end

	function HUD.TextShadow( text, font, x, y, col, ax, ay )
		draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 140 ), ax, ay )
		draw.SimpleText( text, font, x, y, col, ax, ay )
	end

	function HUD.DrawPanel( x, y, w, h, alpha )
		HUD.Sync()
		alpha = alpha or 220
		local bg = UI.Colors.bg
		draw.RoundedBox( 6, x, y, w, h, Color( bg.r, bg.g, bg.b, alpha ) )
		surface.SetDrawColor( UI.Colors.borderDim.r, UI.Colors.borderDim.g, UI.Colors.borderDim.b, math.min( alpha, 160 ) )
		surface.DrawOutlinedRect( x, y, w, h, 1 )
		surface.SetDrawColor( UI.Colors.primary.r, UI.Colors.primary.g, UI.Colors.primary.b, math.min( alpha, 90 ) )
		surface.DrawRect( x + 1, y + 1, w - 2, 2 )
	end

	function HUD.DrawHeader( x, y, w, text, alpha )
		HUD.Sync()
		alpha = alpha or 230
		surface.SetDrawColor( UI.Colors.bgLight.r, UI.Colors.bgLight.g, UI.Colors.bgLight.b, alpha )
		surface.DrawRect( x, y, w, 22 )
		surface.SetDrawColor( UI.Colors.borderDim.r, UI.Colors.borderDim.g, UI.Colors.borderDim.b, math.min( alpha, 140 ) )
		surface.DrawLine( x, y + 22, x + w, y + 22 )
		HUD.TextShadow( text, "SWGRP_HUD_Subtitle", x + 10, y + 11, UI.Colors.primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	function HUD.DrawStatBar( x, y, w, h, frac, fillCol, label )
		HUD.Sync()
		frac = math.Clamp( frac, 0, 1 )

		draw.RoundedBox( 4, x, y, w, h, Color( 0, 0, 0, 160 ) )
		if frac > 0 then
			draw.RoundedBox( 4, x + 1, y + 1, math.max( 4, math.floor( ( w - 2 ) * frac ) ), h - 2, fillCol )
		end
		surface.SetDrawColor( UI.Colors.borderDim.r, UI.Colors.borderDim.g, UI.Colors.borderDim.b, 120 )
		surface.DrawOutlinedRect( x, y, w, h, 1 )
		HUD.TextShadow( label, "SWGRP_HUD_Small", x + 8, y + h / 2, Color( 245, 245, 245 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end

	HUD.Toasts = HUD.Toasts or {}

	function HUD.Toast( msg, duration, col )
		if not msg or msg == "" then return end
		table.insert( HUD.Toasts, {
			text = msg,
			expire = CurTime() + ( duration or 3.5 ),
			color = col or UI.Colors.accent,
		} )
	end

	function HUD.DrawToasts()
		if #HUD.Toasts == 0 then return end
		HUD.Sync()

		local scrW, scrH = ScrW(), ScrH()
		local now = CurTime()
		local toastCount = #HUD.Toasts
		-- Below lockdown banner when playing; above bottom HUD when a terminal is open.
		local y = UI.IsTerminalOpen() and ( scrH - 28 - toastCount * 32 - 24 ) or 118

		for i = #HUD.Toasts, 1, -1 do
			local t = HUD.Toasts[i]
			if now >= t.expire then
				table.remove( HUD.Toasts, i )
			end
		end

		for _, t in ipairs( HUD.Toasts ) do
			surface.SetFont( "SWGRP_HUD_Body" )
			local tw = surface.GetTextSize( t.text )
			local w = math.min( scrW * 0.5, tw + 28 )
			local x = scrW * 0.5 - w * 0.5
			local life = t.expire - now
			local alpha = math.Clamp( life, 0, 1 ) * 230
			if life > 3 then alpha = 230 end

			draw.RoundedBox( 6, x, y, w, 28, Color( 10, 15, 25, alpha ) )
			surface.SetDrawColor( t.color.r, t.color.g, t.color.b, alpha )
			surface.DrawOutlinedRect( x, y, w, 28, 1 )
			HUD.TextShadow( t.text, "SWGRP_HUD_Body", x + w / 2, y + 14, Color( 255, 255, 255, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			y = y + 32
		end
	end
end

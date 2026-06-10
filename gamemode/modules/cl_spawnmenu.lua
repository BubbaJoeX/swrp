--[[---------------------------------------------------------------------------
    Q-menu (spawn menu) theme — replaces missing default Derma panel textures
    with SWGRP terminal colors. Pink/black checkerboards on the spawn menu
    usually mean base vgui materials failed to load (cache/addon/CSS), not a
    missing SWGRP skin file.
---------------------------------------------------------------------------]]

local UI = SWGRP and SWGRP.UI

local PANEL_CLASSES = {
	DPanel = true,
	DTree = true,
	DTree_Node = true,
	DCategoryList = true,
	DCategoryHeader = true,
	DPanelList = true,
	DListLayout = true,
	DScrollPanel = true,
	DIconLayout = true,
	ContentContainer = true,
	SpawnContentPanel = true,
	SpawnIcon = false, -- keep model previews
}

local function PaintTerminalBg( self, w, h )
	if UI then
		UI.SyncColors()
		surface.SetDrawColor( UI.Colors.bg.r, UI.Colors.bg.g, UI.Colors.bg.b, 245 )
	else
		surface.SetDrawColor( 10, 15, 25, 245 )
	end
	surface.DrawRect( 0, 0, w, h )
end

local function StyleSpawnMenuPanel( pnl, depth )
	if not IsValid( pnl ) or ( depth or 0 ) > 24 then return end
	depth = depth or 0

	local class = pnl:GetClassName()
	if PANEL_CLASSES[class] == true and pnl.Paint == PaintTerminalBg then
		-- already themed
	elseif PANEL_CLASSES[class] == true then
		pnl.Paint = PaintTerminalBg
	elseif PANEL_CLASSES[class] == nil and class:StartWith( "D" ) then
		-- Generic Derma panels (DLabel keeps text; only blank panels)
		if class == "DLabel" or class == "DButton" or class == "DImageButton" then
			-- leave controls alone
		elseif pnl.Paint and not pnl._SWGRPSpawnMenuThemed then
			local oldPaint = pnl.Paint
			pnl._SWGRPSpawnMenuThemed = true
			pnl.Paint = function( self, w, h )
				PaintTerminalBg( self, w, h )
				if oldPaint then oldPaint( self, w, h ) end
			end
		elseif not pnl.Paint then
			pnl.Paint = PaintTerminalBg
		end
	end

	for _, child in ipairs( pnl:GetChildren() ) do
		StyleSpawnMenuPanel( child, depth + 1 )
	end
end

local function ApplySpawnMenuTheme()
	if not IsValid( g_SpawnMenu ) then return end
	StyleSpawnMenuPanel( g_SpawnMenu, 0 )
end

hook.Add( "SpawnMenuCreated", "SWGRP_SpawnMenuTheme", function()
	timer.Simple( 0, ApplySpawnMenuTheme )
end )

hook.Add( "OnSpawnMenuOpen", "SWGRP_SpawnMenuTheme", function()
	timer.Simple( 0, ApplySpawnMenuTheme )
end )

hook.Add( "OnContextMenuOpen", "SWGRP_SpawnMenuTheme", function()
	if IsValid( g_ContextMenu ) then
		timer.Simple( 0, function()
			if IsValid( g_ContextMenu ) then
				StyleSpawnMenuPanel( g_ContextMenu, 0 )
			end
		end )
	end
end )

concommand.Add( "swgrp_reload_spawnmenu_theme", function()
	RunConsoleCommand( "spawnmenu_reload" )
	timer.Simple( 0.2, ApplySpawnMenuTheme )
end )

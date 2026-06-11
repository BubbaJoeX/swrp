--[[---------------------------------------------------------------------------
    SWGRP global UI skin — Derma menus, dialogs, and FAdmin color sync
---------------------------------------------------------------------------]]

local UI = SWGRP.UI
if not UI then return end

UI.RegisterFonts()
if FAdmin then UI.SyncFAdminMessageColors() end

hook.Add( "Initialize", "SWGRP_UI_Skin", function()
	UI.RegisterFonts()
	UI.SyncFAdminMessageColors()
end )

hook.Add( "SWGRP_ConfigUpdated", "SWGRP_UI_Skin", function()
	UI.SyncColors()
	UI.SyncFAdminMessageColors()
	if UI.RefreshAllSheets then UI.RefreshAllSheets() end
end )

-- Terminal-styled context menus (FAdmin job picker, player row RMB, etc.)
local _DermaMenu = DermaMenu
function DermaMenu( parent, menu )
	local m = _DermaMenu( parent, menu )
	UI.StyleDermaMenu( m )
	return m
end

-- String request dialogs from FAdmin / admin tools
if Derma_StringRequest then
	local _StringRequest = Derma_StringRequest
	function Derma_StringRequest( title, text, defaultText, enterFunc, cancelFunc, buttonText, cancelText )
		_StringRequest( title, text, defaultText, enterFunc, cancelFunc, buttonText, cancelText )
		timer.Simple( 0, function()
			for _, pnl in ipairs( vgui.GetWorldPanel():GetChildren() ) do
				if pnl:GetClassName() == "DFrame" and pnl:IsVisible() then
					UI.StyleDermaFrame( pnl, title )
					for _, child in ipairs( pnl:GetChildren() ) do
						if child:GetClassName() == "DTextEntry" and UI.StyleTextEntry then
							UI.StyleTextEntry( child )
						end
						if child:GetClassName() == "DLabel" then
							UI.StyleTerminalLabel( child, "DermaDefault", UI.Colors.secondary )
						end
						if child:GetClassName() == "DButton" and not child._swgrpStyled then
							child._swgrpStyled = true
							local label = child:GetText()
							child:SetText( "" )
							child.LabelText = label
							child.Paint = UI.PaintTerminalButton
						end
					end
				end
			end
		end )
	end
end

-- Query dialogs (yes/no)
if Derma_Query then
	local _Query = Derma_Query
	function Derma_Query( text, title, ... )
		_Query( text, title, ... )
		timer.Simple( 0, function()
			for _, pnl in ipairs( vgui.GetWorldPanel():GetChildren() ) do
				if pnl:GetClassName() == "DFrame" and pnl:IsVisible() then
					UI.StyleDermaFrame( pnl, title )
				end
			end
		end )
	end
end

local function StyleFrameChildren( frame )
	if not IsValid( frame ) then return end
	for _, child in ipairs( frame:GetChildren() ) do
		if child:GetClassName() == "DTextEntry" and UI.StyleTextEntry then
			UI.StyleTextEntry( child )
		elseif child:GetClassName() == "DLabel" then
			UI.StyleTerminalLabel( child, "DermaDefault", UI.Colors.secondary )
		elseif child:GetClassName() == "DButton" and not child._swgrpStyled then
			child._swgrpStyled = true
			local label = child:GetText()
			child:SetText( "" )
			child.LabelText = label
			child.Paint = UI.PaintTerminalButton
		elseif child:GetClassName() == "DScrollPanel" and UI.StyleScrollPanel then
			UI.StyleScrollPanel( child )
		end
	end
end

local _vguiCreate = vgui.Create
function vgui.Create( className, parent, name )
	local panel = _vguiCreate( className, parent, name )
	if className == "DFrame" and IsValid( panel ) and not panel._swgrpNoSkin then
		timer.Simple( 0, function()
			if not IsValid( panel ) then return end
			UI.StyleDermaFrame( panel )
			StyleFrameChildren( panel )
		end )
	end
	return panel
end

print( "[SWGRP] UI skin loaded." )

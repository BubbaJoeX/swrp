--[[---------------------------------------------------------------------------
    Admin Ownership Changer - client menu
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.OwnershipTool = SWGRP.OwnershipTool or {}

local OT = SWGRP.OwnershipTool

function OT.OpenMenu( entIndex, class, ownerName, players )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( OT.Menu ) then OT.Menu:Remove() end

	local frame = UI.CreateTerminalFrame( "OWNERSHIP CHANGER", 360, 480 )
	OT.Menu = frame

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	UI.CreateLabel( body, class, "DermaDefaultBold", UI.Colors.primary, TOP )
	UI.CreateLabel( body, "Current owner: " .. ownerName, "DermaDefault", UI.Colors.secondary, TOP )

	local clearBtn = UI.CreateButton( body, "Clear Ownership", function()
		net.Start( "SWGRP_OwnershipAction" )
			net.WriteUInt( entIndex, 16 )
			net.WriteString( "" )
		net.SendToServer()
	end )
	if IsValid( clearBtn ) then clearBtn:DockMargin( 0, UI.Spacing.gap, 0, UI.Spacing.gap ) end

	for _, row in ipairs( players or {} ) do
		local btn = UI.CreateButton( body, row.name, function()
			net.Start( "SWGRP_OwnershipAction" )
				net.WriteUInt( entIndex, 16 )
				net.WriteString( row.sid )
			net.SendToServer()
		end )
		if IsValid( btn ) then
			btn:Dock( TOP )
			btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		end
	end
end

net.Receive( "SWGRP_OwnershipMenu", function()
	local entIndex = net.ReadUInt( 16 )
	local class = net.ReadString()
	local ownerName = net.ReadString()
	local count = net.ReadUInt( 8 )
	local players = {}

	for _ = 1, count do
		table.insert( players, {
			sid = net.ReadString(),
			name = net.ReadString(),
		} )
	end

	OT.OpenMenu( entIndex, class, ownerName, players )
end )

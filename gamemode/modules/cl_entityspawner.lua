--[[---------------------------------------------------------------------------
    Admin Entity Spawner - client menu
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.EntitySpawner = SWGRP.EntitySpawner or {}

local ES = SWGRP.EntitySpawner

function ES.OpenMenu( catalog )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( ES.Menu ) then ES.Menu:Remove() end

	local frame = UI.CreateTerminalFrame( "ENTITY SPAWNER", 420, 560 )
	ES.Menu = frame

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	UI.CreateLabel( body, "Spawn CSV content (entities, food, spices, shipments, vehicles)", "DermaDefault", UI.Colors.secondary, TOP )

	for _, row in ipairs( catalog or {} ) do
		local label = string.format( "[%s] %s", row.kind, row.name )
		local btn = UI.CreateButton( body, label, function()
			net.Start( "SWGRP_EntitySpawnAction" )
				net.WriteString( row.kind )
				net.WriteString( tostring( row.id ) )
			net.SendToServer()
		end )
		if IsValid( btn ) then
			btn:Dock( TOP )
			btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		end
	end
end

net.Receive( "SWGRP_EntitySpawnMenu", function()
	local count = net.ReadUInt( 16 )
	local catalog = {}

	for _ = 1, count do
		table.insert( catalog, {
			kind = net.ReadString(),
			id = net.ReadString(),
			name = net.ReadString(),
			model = net.ReadString(),
		} )
	end

	ES.OpenMenu( catalog )
end )

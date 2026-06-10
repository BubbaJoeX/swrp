--[[---------------------------------------------------------------------------
    Jail Spawn Tool - client preview markers
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JailSpawns = SWGRP.JailSpawns or {}

local JS = SWGRP.JailSpawns
JS.Preview = JS.Preview or {}

local function SendAction( action )
	net.Start( "SWGRP_JailSpawnAction" )
		net.WriteString( action )
	net.SendToServer()
end

local function HasJailTool()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return false end
	local wep = ply:GetActiveWeapon()
	return IsValid( wep ) and wep:GetClass() == "swgrp_admin_jailtool"
end

function JS.OpenMenu( count )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( JS.Menu ) then JS.Menu:Remove() end

	local frame = UI.CreateTerminalFrame( "JAIL SPAWN TOOL", 340, 420 )
	JS.Menu = frame

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	local label = UI.CreateLabel( body, "Map: " .. game.GetMap(), "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( label ) then label:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local countLabel = UI.CreateLabel( body, "Jail points: " .. ( count or 0 ), "DermaDefaultBold", UI.Colors.primary, TOP )
	if IsValid( countLabel ) then countLabel:DockMargin( 0, 0, 0, UI.Spacing.gap ) end

	local function actionButton( text, onClick )
		local btn = UI.CreateButton( body, text, onClick )
		if IsValid( btn ) then
			btn:Dock( TOP )
			btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		end
		return btn
	end

	actionButton( "Add Jail Point At Crosshair", function()
		SendAction( "add_here" )
	end )

	actionButton( "Remove Nearest Jail Point", function()
		SendAction( "remove_nearest" )
	end )

	actionButton( "Clear All Jail Points", function()
		Derma_Query( "Remove every jail point on this map?", "Confirm Clear", "Clear", function()
			SendAction( "clear" )
		end, "Cancel" )
	end )

	actionButton( "Refresh Preview", function()
		SendAction( "refresh" )
	end )
end

net.Receive( "SWGRP_JailSpawnMenu", function()
	local count = net.ReadUInt( 16 )
	JS.OpenMenu( count )
end )

net.Receive( "SWGRP_JailSpawnSync", function()
	local count = net.ReadUInt( 16 )
	local list = {}

	for _ = 1, count do
		table.insert( list, {
			x = net.ReadFloat(),
			y = net.ReadFloat(),
			z = net.ReadFloat(),
			pitch = net.ReadFloat(),
			yaw = net.ReadFloat(),
			roll = net.ReadFloat(),
		} )
	end

	JS.Preview = list
end )

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_JailSpawnPreview", function()
	if not HasJailTool() then return end
	if not JS.Preview or #JS.Preview == 0 then return end

	render.SetColorMaterial()
	for _, row in ipairs( JS.Preview ) do
		local pos = Vector( row.x, row.y, row.z )
		render.DrawWireframeSphere( pos, 16, 12, 12, Color( 255, 80, 80, 180 ), true )

		local ang = Angle( row.pitch or 0, row.yaw or 0, row.roll or 0 )
		render.DrawLine( pos, pos + ang:Forward() * 32, Color( 255, 200, 80, 200 ), true )
	end
end )

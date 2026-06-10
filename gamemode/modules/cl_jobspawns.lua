--[[---------------------------------------------------------------------------
    Job Spawn Tool - client menu and preview markers
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JobSpawns = SWGRP.JobSpawns or {}

local JS = SWGRP.JobSpawns
JS.Preview = JS.Preview or {}
JS.SelectedCmd = JS.SelectedCmd or "colonist"

local function SendAction( action, cmd )
	net.Start( "SWGRP_JobSpawnAction" )
		net.WriteString( action )
		net.WriteString( cmd or JS.SelectedCmd or "" )
	net.SendToServer()
end

local function HasSpawnTool()
	local ply = LocalPlayer()
	if not IsValid( ply ) then return false end
	local wep = ply:GetActiveWeapon()
	return IsValid( wep ) and wep:GetClass() == "swgrp_admin_jobspawntool"
end

function JS.OpenMenu( selectedCmd, jobs )
	local UI = SWGRP.UI
	if not UI or not UI.CreateTerminalFrame then return end

	if IsValid( JS.Menu ) then JS.Menu:Remove() end

	JS.SelectedCmd = selectedCmd or JS.SelectedCmd or "colonist"

	local frame = UI.CreateTerminalFrame( "JOB SPAWN TOOL", 360, 560 )
	JS.Menu = frame

	local body = vgui.Create( "DScrollPanel", frame )
	body:Dock( FILL )
	body:DockMargin( UI.Spacing.frame, 34, UI.Spacing.frame, UI.Spacing.frame )
	body.Paint = function() end
	if UI.StyleScrollPanel then UI.StyleScrollPanel( body ) end

	local function label( text, font, color )
		local l = UI.CreateLabel( body, text, font, color, TOP )
		if IsValid( l ) then l:DockMargin( 0, 0, 0, UI.Spacing.gap ) end
		return l
	end

	local function actionButton( text, onClick )
		local btn = UI.CreateButton( body, text, onClick )
		if not IsValid( btn ) then return end
		btn:Dock( TOP )
		btn:DockMargin( 0, 0, 0, UI.Spacing.gap )
		return btn
	end

	label( "Map: " .. game.GetMap(), "DermaDefault", UI.Colors.secondary )
	label( "Left click: add spawn. Reload: remove nearest. Right click: this menu.", "DermaDefault", UI.Colors.secondary )

	local selectedLabel = label( "Selected: " .. JS.SelectedCmd, "DermaDefaultBold", UI.Colors.primary )

	local combo = vgui.Create( "DComboBox", body )
	combo:Dock( TOP )
	combo:DockMargin( 0, 0, 0, UI.Spacing.gap )
	combo:SetValue( JS.SelectedCmd )
	if UI.StyleComboBox then UI.StyleComboBox( combo ) end

	for _, job in ipairs( jobs or {} ) do
		local text = string.format( "%s (%s) - %d spawns", job.name, job.command, job.count or 0 )
		combo:AddChoice( text, job.command )
		if job.command == JS.SelectedCmd then
			combo:SetValue( text )
		end
	end

	combo.OnSelect = function( _, _, _, data )
		JS.SelectedCmd = data
		if IsValid( selectedLabel ) then
			selectedLabel:SetText( "Selected: " .. data )
		end
		SendAction( "select", data )
	end

	actionButton( "Add Spawn At Crosshair", function()
		SendAction( "add_here", JS.SelectedCmd )
	end )

	actionButton( "Remove Nearest Spawn", function()
		SendAction( "remove_nearest", JS.SelectedCmd )
	end )

	actionButton( "Clear All Spawns For Profession", function()
		Derma_Query(
			"Remove every spawn point for " .. JS.SelectedCmd .. " on this map?",
			"Confirm Clear",
			"Clear",
			function()
				SendAction( "clear", JS.SelectedCmd )
			end,
			"Cancel"
		)
	end )

	actionButton( "Refresh Preview", function()
		SendAction( "refresh", JS.SelectedCmd )
	end )
end

net.Receive( "SWGRP_JobSpawnMenu", function()
	local selected = net.ReadString()
	local count = net.ReadUInt( 16 )
	local jobs = {}

	for _ = 1, count do
		table.insert( jobs, {
			command = net.ReadString(),
			name = net.ReadString(),
			count = net.ReadUInt( 16 ),
		} )
	end

	JS.OpenMenu( selected, jobs )
end )

net.Receive( "SWGRP_JobSpawnSync", function()
	local cmd = net.ReadString()
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

	JS.Preview[cmd] = list
	JS.SelectedCmd = cmd
end )

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_JobSpawnPreview", function()
	if not HasSpawnTool() then return end

	local cmd = JS.SelectedCmd
	local list = JS.Preview[cmd]
	if not list or #list == 0 then return end

	render.SetColorMaterial()
	for _, row in ipairs( list ) do
		local pos = Vector( row.x, row.y, row.z )
		render.DrawWireframeSphere( pos, 16, 12, 12, Color( 80, 200, 255, 180 ), true )

		local ang = Angle( row.pitch or 0, row.yaw or 0, row.roll or 0 )
		local fwd = ang:Forward() * 32
		render.DrawLine( pos, pos + fwd, Color( 255, 220, 80, 200 ), true )
	end
end )

hook.Add( "OnPlayerChangedTeam", "SWGRP_JobSpawnPreviewClear", function()
	-- Preview stays keyed by profession; no action needed.
end )

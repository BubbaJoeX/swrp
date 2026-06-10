--[[---------------------------------------------------------------------------
    SWGRP Imperial Command Console - client UI

    Themed admin console built entirely on SWGRP.UI (amber terminal theme). Every
    button maps to a server action handled by sv_admin.lua; the client never
    enforces authority itself, it just refuses to open for non-admins and lets
    the server validate every request.

    Open with:  /admin  (chat)  •  swgrp_admin  (console)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Admin = SWGRP.Admin or {}
SWGRP.Admin.State = SWGRP.Admin.State or { treasury = 0, lottery = 0 }

local UI = SWGRP.UI

--[[---------------------------------------------------------------------------
    Net senders (one tiny wrapper per payload shape)
---------------------------------------------------------------------------]]

local function SendGlobal( action )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.SendToServer()
end

local function SendGlobalInt( action, v )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteInt( math.floor( v or 0 ), 32 ) net.SendToServer()
end

local function SendGlobalString( action, s )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteString( s or "" ) net.SendToServer()
end

local function SendGlobalU8( action, v )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteUInt( math.Clamp( math.floor( v or 0 ), 0, 255 ), 8 ) net.SendToServer()
end

local function SendGlobalBool( action, b )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteBool( b and true or false ) net.SendToServer()
end

local function SendConVar( name, value )
	net.Start( "SWGRP_AdminAction" ) net.WriteString( "setconvar" ) net.WriteString( name ) net.WriteString( tostring( value ) ) net.SendToServer()
end

local function SendTarget( action, target )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.SendToServer()
end

local function SendTargetInt( action, target, v )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.WriteInt( math.floor( v or 0 ), 32 ) net.SendToServer()
end

local function SendTargetU8( action, target, v )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.WriteUInt( math.Clamp( math.floor( v or 0 ), 0, 255 ), 8 ) net.SendToServer()
end

local function SendTargetU16( action, target, v )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.WriteUInt( math.Clamp( math.floor( v or 0 ), 0, 65535 ), 16 ) net.SendToServer()
end

local function SendTargetBool( action, target, b )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.WriteBool( b and true or false ) net.SendToServer()
end

local function SendTargetString( action, target, s )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" ) net.WriteString( action ) net.WriteEntity( target ) net.WriteString( s or "" ) net.SendToServer()
end

local function SendBan( target, minutes, reason )
	if not IsValid( target ) then return end
	net.Start( "SWGRP_AdminAction" )
		net.WriteString( "ban" )
		net.WriteEntity( target )
		net.WriteUInt( math.Clamp( math.floor( minutes or 0 ), 0, 525600 ), 32 )
		net.WriteString( reason or "" )
	net.SendToServer()
end

--[[---------------------------------------------------------------------------
    Small themed layout helpers
---------------------------------------------------------------------------]]

local function FieldRow( parent, labelText, placeholder, btnText, onApply )
	local lbl = UI.CreateLabel( parent, labelText, "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( lbl ) then lbl:DockMargin( 0, UI.Spacing.gap, 0, 4 ) end

	local row = vgui.Create( "DPanel", parent )
	row:Dock( TOP )
	row:SetTall( UI.Spacing.input )
	row:DockMargin( 0, 0, 0, 4 )
	row.Paint = function() end

	-- Dock the button (RIGHT) before the entry (FILL) so the FILL claims only the
	-- leftover width instead of overlapping the button.
	local entry
	local btn = UI.CreateButton( row, btnText, function() onApply( entry:GetValue() ) end )
	btn:Dock( RIGHT )
	btn:SetWide( 110 )

	entry = vgui.Create( "DTextEntry", row )
	entry:Dock( FILL )
	entry:DockMargin( 0, 0, UI.Spacing.gap, 0 )
	if placeholder then entry:SetPlaceholderText( placeholder ) end
	UI.StyleTextEntry( entry )
	entry.OnEnter = function() onApply( entry:GetValue() ) end

	return entry
end

local function ButtonGrid( parent, defs, perRow )
	perRow = perRow or 3
	local rows = math.ceil( #defs / perRow )

	local panel = vgui.Create( "DPanel", parent )
	panel:Dock( TOP )
	panel:DockMargin( 0, 4, 0, UI.Spacing.gap )
	panel.Paint = function() end

	local btns = {}
	for i, def in ipairs( defs ) do
		btns[i] = UI.CreateButton( panel, def.text, def.fn )
		if def.tooltip then btns[i]:SetTooltip( def.tooltip ) end
	end

	local gap = 6
	panel:SetTall( rows * ( UI.Spacing.button + gap ) - gap )
	panel.PerformLayout = function( s, w )
		local bw = ( w - gap * ( perRow - 1 ) ) / perRow
		for i, b in ipairs( btns ) do
			local col = ( i - 1 ) % perRow
			local r = math.floor( ( i - 1 ) / perRow )
			b:SetPos( col * ( bw + gap ), r * ( UI.Spacing.button + gap ) )
			b:SetSize( bw, UI.Spacing.button )
		end
	end

	return panel
end

--[[---------------------------------------------------------------------------
    Players tab
---------------------------------------------------------------------------]]

local function BuildPlayersTab( inner )
	local listScroll = vgui.Create( "DScrollPanel", inner )
	listScroll:Dock( LEFT )
	listScroll:SetWide( 240 )
	listScroll:DockMargin( 0, 0, UI.Spacing.gapLarge, 0 )
	UI.StyleScrollPanel( listScroll )

	local actionHost = vgui.Create( "DScrollPanel", inner )
	actionHost:Dock( FILL )
	UI.StyleScrollPanel( actionHost )

	local state = { selected = nil }

	local function RefreshActions()
		actionHost:Clear()
		local target = state.selected
		if not IsValid( target ) then
			local lbl = UI.CreateLabel( actionHost, "Select a player from the roster.", "DermaDefaultBold", UI.Colors.primary, TOP )
			if IsValid( lbl ) then lbl:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, 0 ) end
			return
		end

		-- Dock action widgets straight into the scroll canvas (it auto-grows to
		-- fit TOP-docked children); a canvas inset gives us left/right padding.
		local pad = actionHost
		local canvas = actionHost:GetCanvas()
		if IsValid( canvas ) then
			canvas:DockPadding( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )
		end

		local info = UI.CreateLabel( pad, "", "DermaDefaultBold", UI.Colors.primary, TOP )
		local function UpdateInfo()
			if not IsValid( target ) or not IsValid( info ) then return end
			local txt = target:Nick() .. "  [" .. target:SteamID() .. "]\n"
				.. "Profession: " .. ( target.SWGRP_GetJobName and target:SWGRP_GetJobName() or team.GetName( target:Team() ) ) .. "\n"
				.. "Wallet: " .. SWGRP.FormatCredits( target:SWGRP_GetCredits() )
				.. "   Bank: " .. SWGRP.FormatCredits( target:SWGRP_GetBank() ) .. "\n"
				.. ( target:SWGRP_IsWanted() and "WANTED: " .. target:SWGRP_GetWantedReason() .. "  " or "" )
				.. ( target:SWGRP_IsArrested() and "[DETAINED]" or "" )
			info:SetText( txt )
		end
		UpdateInfo()
		timer.Create( "SWGRP_AdminInfo", 0.5, 0, function()
			if not IsValid( actionHost ) then timer.Remove( "SWGRP_AdminInfo" ) return end
			UpdateInfo()
		end )

		-- Economy
		UI.CreateSectionHeader( pad, "ECONOMY", { first = true } )
		FieldRow( pad, "Set wallet credits", "e.g. 5000", "Set", function( v )
			SendTargetInt( "setcredits", target, tonumber( v ) or 0 )
		end )
		FieldRow( pad, "Adjust credits (+/-)", "e.g. -250", "Apply", function( v )
			SendTargetInt( "addcredits", target, tonumber( v ) or 0 )
		end )
		FieldRow( pad, "Set bank balance", "e.g. 10000", "Set", function( v )
			SendTargetInt( "setbank", target, tonumber( v ) or 0 )
		end )

		-- Profession
		UI.CreateSectionHeader( pad, "PROFESSION" )
		local jobRow = vgui.Create( "DPanel", pad )
		jobRow:Dock( TOP )
		jobRow:SetTall( UI.Spacing.input )
		jobRow:DockMargin( 0, 4, 0, 4 )
		jobRow.Paint = function() end

		local combo
		local applyJob = UI.CreateButton( jobRow, "Force Job", function()
			local _, id = combo:GetSelected()
			if id then SendTargetU16( "setjob", target, id ) end
		end )
		applyJob:Dock( RIGHT )
		applyJob:SetWide( 110 )

		combo = vgui.Create( "DComboBox", jobRow )
		combo:Dock( FILL )
		combo:DockMargin( 0, 0, UI.Spacing.gap, 0 )
		combo:SetValue( "Select profession..." )
		combo:SetTextColor( UI.Colors.secondary )

		local sortedJobs = {}
		for id, job in pairs( SWGRP.Jobs ) do sortedJobs[#sortedJobs + 1] = { id = id, name = job.name or ( "Team " .. id ) } end
		table.sort( sortedJobs, function( a, b ) return a.name < b.name end )
		for _, j in ipairs( sortedJobs ) do combo:AddChoice( j.name, j.id ) end

		-- Player control
		UI.CreateSectionHeader( pad, "PLAYER CONTROL" )
		ButtonGrid( pad, {
			{ text = "Bring",    fn = function() SendTarget( "bring", target ) end },
			{ text = "Goto",     fn = function() SendTarget( "goto", target ) end },
			{ text = "Return",   fn = function() SendTarget( "return", target ) end },
			{ text = "Freeze",   fn = function() SendTargetBool( "freeze", target, true ) end },
			{ text = "Unfreeze", fn = function() SendTargetBool( "freeze", target, false ) end },
			{ text = "Heal",     fn = function() SendTarget( "heal", target ) end },
			{ text = "Slay",     fn = function() SendTarget( "slay", target ) end },
			{ text = "God On",   fn = function() SendTargetBool( "god", target, true ) end },
			{ text = "God Off",  fn = function() SendTargetBool( "god", target, false ) end },
			{ text = "Cloak On", fn = function() SendTargetBool( "cloak", target, true ) end },
			{ text = "Cloak Off",fn = function() SendTargetBool( "cloak", target, false ) end },
		}, 3 )
		FieldRow( pad, "Set rations (0-100)", "e.g. 100", "Set", function( v )
			SendTargetU8( "sethunger", target, tonumber( v ) or 0 )
		end )

		-- Law enforcement
		UI.CreateSectionHeader( pad, "LAW ENFORCEMENT" )
		FieldRow( pad, "Mark wanted (reason)", "Reason...", "Set Wanted", function( v )
			SendTargetString( "setwanted", target, v )
		end )
		ButtonGrid( pad, {
			{ text = "Clear Wanted",   fn = function() SendTarget( "clearwanted", target ) end },
			{ text = "Detain",         fn = function() SendTarget( "arrest", target ) end },
			{ text = "Release",        fn = function() SendTarget( "unarrest", target ) end },
			{ text = "Clear Warrant",  fn = function() SendTarget( "clearwarrant", target ) end },
			{ text = "Grant Permit",   fn = function() SendTargetBool( "license", target, true ) end },
			{ text = "Revoke Permit",  fn = function() SendTargetBool( "license", target, false ) end },
		}, 3 )

		-- Moderation
		UI.CreateSectionHeader( pad, "MODERATION" )
		FieldRow( pad, "Kick (reason)", "Reason...", "Kick", function( v )
			SendTargetString( "kick", target, v )
		end )
		local banReason
		local banMinutes = FieldRow( pad, "Ban minutes (0 = permanent)", "e.g. 60", "—", function() end )
		banReason = FieldRow( pad, "Ban reason", "Reason...", "Ban (superadmin)", function( v )
			SendBan( target, tonumber( banMinutes:GetValue() ) or 0, v )
		end )
	end

	local function RefreshList()
		listScroll:Clear()
		for _, ply in ipairs( player.GetAll() ) do
			if not IsValid( ply ) then continue end
			local row = UI.CreateButton( listScroll, "", function()
				state.selected = ply
				RefreshActions()
			end )
			row:Dock( TOP )
			row:DockMargin( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, 0 )
			row:SetTall( 46 )
			local capture = ply
			row.PaintOver = function( s, w, h )
				if not IsValid( capture ) then return end
				draw.SimpleText( UI.TruncateText( capture:Nick(), "DermaDefaultBold", w - 20 ), "DermaDefaultBold", 10, 12, UI.Colors.primary, TEXT_ALIGN_LEFT )
				local sub = ( capture.SWGRP_GetJobName and capture:SWGRP_GetJobName() or team.GetName( capture:Team() ) )
				draw.SimpleText( UI.TruncateText( sub, "DermaDefault", w - 20 ), "DermaDefault", 10, 30, UI.Colors.secondary, TEXT_ALIGN_LEFT )
			end
		end
	end

	RefreshList()
	RefreshActions()

	-- Periodically refresh the roster so joins/leaves appear without reopening.
	timer.Create( "SWGRP_AdminRoster", 3, 0, function()
		if not IsValid( listScroll ) then timer.Remove( "SWGRP_AdminRoster" ) return end
		RefreshList()
	end )
end

--[[---------------------------------------------------------------------------
    Economy tab
---------------------------------------------------------------------------]]

local function BuildEconomyTab( inner )
	local treasuryLbl = UI.CreateLabel( inner, "", "DermaDefaultBold", UI.Colors.primary, TOP )

	local function UpdateLabels()
		if not IsValid( treasuryLbl ) then return end
		treasuryLbl:SetText( "Imperial Treasury: " .. SWGRP.FormatCredits( SWGRP.Admin.State.treasury or 0 )
			.. "\nLottery Pool: " .. SWGRP.FormatCredits( SWGRP.Admin.State.lottery or 0 ) )
	end
	UpdateLabels()
	SWGRP.Admin._EconomyRefresh = UpdateLabels

	SendGlobal( "requeststate" )

	UI.CreateSectionHeader( inner, "TREASURY", { first = true } )
	FieldRow( inner, "Set treasury balance", "e.g. 100000", "Set", function( v )
		SendGlobalInt( "settreasury", tonumber( v ) or 0 )
	end )

	UI.CreateSectionHeader( inner, "CYCLES" )
	ButtonGrid( inner, {
		{ text = "Force Payday",  fn = function() SendGlobal( "payday" ) end,  tooltip = "Pay every eligible player their salary now" },
		{ text = "Draw Lottery",  fn = function() SendGlobal( "lottery" ) end, tooltip = "Run the lottery draw immediately" },
	}, 2 )
end

--[[---------------------------------------------------------------------------
    Government & Law tab
---------------------------------------------------------------------------]]

local function BuildGovernmentTab( inner )
	local lawScroll = vgui.Create( "DScrollPanel", inner )
	lawScroll:Dock( TOP )
	lawScroll:SetTall( 180 )
	lawScroll:DockMargin( 0, 0, 0, UI.Spacing.gap )
	UI.StyleScrollPanel( lawScroll )

	local function RefreshLaws()
		if not IsValid( lawScroll ) then return end
		lawScroll:Clear()
		local laws = SWGRP.LawsClient or {}
		if #laws == 0 then
			local lbl = UI.CreateLabel( lawScroll, "No active edicts.", "DermaDefault", UI.Colors.secondary, TOP )
			if IsValid( lbl ) then lbl:DockMargin( UI.Spacing.gap, UI.Spacing.gap, 0, 0 ) end
			return
		end
		for i, law in ipairs( laws ) do
			local idx = i
			local row = vgui.Create( "DPanel", lawScroll )
			row:Dock( TOP )
			row:SetTall( UI.Spacing.input )
			row:DockMargin( 0, 0, 0, 4 )
			row.Paint = function() end

			local del = UI.CreateButton( row, "Remove", function()
				SendGlobalU8( "removelaw", idx )
				timer.Simple( 0.2, RefreshLaws )
			end )
			del:Dock( RIGHT )
			del:SetWide( 90 )

			local lbl = UI.CreateLabel( row, idx .. ". " .. law, "DermaDefault", UI.Colors.secondary, FILL )
			if IsValid( lbl ) then lbl:DockMargin( 4, 0, UI.Spacing.gap, 0 ) end
		end
	end

	UI.CreateSectionHeader( inner, "IMPERIAL EDICTS", { first = true } )
	RefreshLaws()
	FieldRow( inner, "Add edict", "Edict text...", "Add", function( v )
		if v ~= "" then
			SendGlobalString( "addlaw", v )
			timer.Simple( 0.2, RefreshLaws )
		end
	end )
	ButtonGrid( inner, {
		{ text = "Reset Edicts",   fn = function() SendGlobal( "resetlaws" ) timer.Simple( 0.2, RefreshLaws ) end },
		{ text = "Refresh List",   fn = RefreshLaws },
	}, 2 )

	UI.CreateSectionHeader( inner, "LOCKDOWN" )
	ButtonGrid( inner, {
		{ text = "Start Lockdown", fn = function() SendGlobalBool( "lockdown", true ) end },
		{ text = "End Lockdown",   fn = function() SendGlobalBool( "lockdown", false ) end },
	}, 2 )

	UI.CreateSectionHeader( inner, "GOVERNOR" )
	FieldRow( inner, "Set agenda", "Agenda text...", "Set", function( v )
		SendGlobalString( "agenda", v )
	end )
	FieldRow( inner, "Imperial broadcast", "Broadcast message...", "Broadcast", function( v )
		if v ~= "" then SendGlobalString( "broadcast", v ) end
	end )

	-- Keep edict list current while open.
	timer.Create( "SWGRP_AdminLaws", 2, 0, function()
		if not IsValid( inner ) then timer.Remove( "SWGRP_AdminLaws" ) return end
		RefreshLaws()
	end )
end

--[[---------------------------------------------------------------------------
    Systems tab
---------------------------------------------------------------------------]]

local function BuildSystemsTab( inner )
	-- The toggle list can exceed the tab height, so host it in a scroll panel.
	local scroll = vgui.Create( "DScrollPanel", inner )
	scroll:Dock( FILL )
	UI.StyleScrollPanel( scroll )
	local host = scroll
	local canvas = scroll:GetCanvas()
	if IsValid( canvas ) then
		canvas:DockPadding( UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap, UI.Spacing.gap )
	end

	UI.CreateSectionHeader( host, "SERVER SYSTEMS", { first = true } )

	for _, t in ipairs( SWGRP.Admin.SystemToggles or {} ) do
		local cv = GetConVar( t.cvar )
		if not cv then continue end

		if t.kind == "bool" then
			local row = vgui.Create( "DPanel", host )
			row:Dock( TOP )
			row:SetTall( UI.Spacing.input )
			row:DockMargin( 0, 0, 0, 6 )
			row.Paint = function() end

			local lbl
			local function UpdateLbl()
				if IsValid( lbl ) then
					lbl:SetText( t.label .. ":  " .. ( cv:GetBool() and "ENABLED" or "DISABLED" ) )
				end
			end

			local toggle = UI.CreateButton( row, "Toggle", function()
				SendConVar( t.cvar, cv:GetBool() and "0" or "1" )
				timer.Simple( 0.2, UpdateLbl )
			end )
			toggle:Dock( RIGHT )
			toggle:SetWide( 110 )

			lbl = UI.CreateLabel( row, "", "DermaDefault", UI.Colors.secondary, FILL )
			if IsValid( lbl ) then lbl:DockMargin( 4, 0, UI.Spacing.gap, 0 ) end
			UpdateLbl()
		else
			local cvar = t.cvar
			FieldRow( host, t.label .. "  (now: " .. cv:GetString() .. ")", cv:GetString(), "Set", function( v )
				SendConVar( cvar, v )
			end )
		end
	end

	UI.CreateSectionHeader( host, "MAINTENANCE" )
	ButtonGrid( host, {
		{ text = "Reload Content",   fn = function() SendGlobal( "reloadcontent" ) end, tooltip = "Re-read CSV jobs/entities/shipments (superadmin)" },
		{ text = "Clear Bounties",   fn = function() SendGlobal( "clearhits" ) end },
		{ text = "Clear Warrants",   fn = function() SendGlobal( "clearwarrants" ) end },
	}, 3 )
end

--[[---------------------------------------------------------------------------
    Frame assembly
---------------------------------------------------------------------------]]

function SWGRP.OpenAdminMenu()
	if not SWGRP.Admin.CanUse( LocalPlayer() ) then
		SWGRP.Notify( nil, "You are not authorized to open the Imperial Command Console." )
		return
	end
	if IsValid( SWGRP.AdminFrame ) then SWGRP.AdminFrame:Remove() end

	local frame = UI.CreateTerminalFrame( "IMPERIAL COMMAND CONSOLE", 920, 660 )
	SWGRP.AdminFrame = frame

	frame.OnClose = function()
		timer.Remove( "SWGRP_AdminInfo" )
		timer.Remove( "SWGRP_AdminRoster" )
		timer.Remove( "SWGRP_AdminLaws" )
		SWGRP.Admin._EconomyRefresh = nil
	end

	local sheet = vgui.Create( "DPropertySheet", frame )
	sheet:Dock( FILL )
	sheet:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )

	local players = UI.CreateTabPanel( sheet, "Players", "icon16/group.png" )
	BuildPlayersTab( players )

	local economy = UI.CreateTabPanel( sheet, "Economy", "icon16/money.png" )
	BuildEconomyTab( economy )

	local gov = UI.CreateTabPanel( sheet, "Government & Law", "icon16/book.png" )
	BuildGovernmentTab( gov )

	local systems = UI.CreateTabPanel( sheet, "Systems", "icon16/cog.png" )
	BuildSystemsTab( systems )

	UI.RegisterSheet( sheet )
end

concommand.Add( "swgrp_admin", function()
	SWGRP.OpenAdminMenu()
end )

net.Receive( "SWGRP_AdminMenu", function()
	SWGRP.OpenAdminMenu()
end )

net.Receive( "SWGRP_AdminSync", function()
	SWGRP.Admin.State = SWGRP.Admin.State or {}
	SWGRP.Admin.State.treasury = net.ReadInt( 32 )
	SWGRP.Admin.State.lottery = net.ReadInt( 32 )
	if SWGRP.Admin._EconomyRefresh then SWGRP.Admin._EconomyRefresh() end
end )

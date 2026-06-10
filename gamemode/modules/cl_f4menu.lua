--[[---------------------------------------------------------------------------
    F4 Menu - Galactic Profession Terminal (shop) + F3 Colony Datapad (services)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}

local function F4UI()
	return SWGRP.UI
end

local function F4Dock( panel, dock, margin )
	if not IsValid( panel ) then return end
	if dock then panel:Dock( dock ) end
	if margin then panel:DockMargin( margin[1], margin[2], margin[3], margin[4] ) end
	return panel
end

--[[---------------------------------------------------------------------------
    Shared menu shell
---------------------------------------------------------------------------]]

local function OpenMenu( frameKey, title, builder )
	local UI = F4UI()
	if not UI or not UI.CreateTerminalFrame then
		chat.AddText( Color( 255, 180, 50 ), "[SWGRP] ", color_white, "Terminal UI is not loaded. Reconnect or reload the gamemode." )
		return
	end

	UI.SyncColors()

	if IsValid( SWGRP[frameKey] ) then
		SWGRP[frameKey]:Remove()
		SWGRP[frameKey] = nil
		return
	end

	local scrW, scrH = ScrW(), ScrH()
	local frame = UI.CreateTerminalFrame( title, scrW * 0.72, scrH * 0.78 )
	SWGRP[frameKey] = frame

	UI._styledSheets = {}

	local sheet = vgui.Create( "DPropertySheet", frame )
	sheet:Dock( FILL )
	sheet:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )

	builder( sheet, UI, frame )

	UI.RegisterSheet( sheet, { compact = true } )

	timer.Simple( 0, function()
		UI.RefreshAllSheets()
	end )

	return frame, sheet
end

--[[---------------------------------------------------------------------------
    Shop terminal (F4): Professions, Structures, Vehicles, Shipments, Ammo
---------------------------------------------------------------------------]]

local function BuildShop( sheet, UI, frame )
	-- Professions -> faction sidebar -> job catalog
	local profCatalog = UI.CreateFactionCatalogTab( sheet, "Professions", "icon16/group.png" )

	local allegianceOrder = {}
	for id in pairs( SWGRP.AllegianceData ) do
		table.insert( allegianceOrder, id )
	end
	table.sort( allegianceOrder, function( a, b )
		local da = SWGRP.AllegianceData[a]
		local db = SWGRP.AllegianceData[b]
		return ( da and da.sortOrder or 99 ) < ( db and db.sortOrder or 99 )
	end )

	for _, allegianceId in ipairs( allegianceOrder ) do
		local faction = SWGRP.AllegianceData[allegianceId]
		if faction then
			local factionJobs = {}
			for _, job in pairs( SWGRP.Jobs ) do
				if SWGRP.GetJobAllegiance( job ) == allegianceId then
					table.insert( factionJobs, job )
				end
			end

			if #factionJobs > 0 then
				table.SortByMember( factionJobs, "name", true )

				profCatalog:AddFaction( allegianceId, faction.short or faction.name, faction.color, function( catalog )
					for _, job in ipairs( factionJobs ) do
						local teamId = job.team
						local maxText = ( job.max and job.max > 0 ) and ( "Max slots: " .. job.max ) or "Unlimited slots"
						local voteText = job.vote and "Requires colony vote" or "Open profession"

						-- List the weapons this profession is issued on spawn so players
						-- can see the loadout before assuming it. Prefer the SWEP's
						-- PrintName, falling back to the raw class when unregistered.
						local wepNames = {}
						for _, wepClass in ipairs( job.weapons or {} ) do
							local swep = weapons.Get( wepClass )
							table.insert( wepNames, ( swep and swep.PrintName and swep.PrintName ~= "" ) and swep.PrintName or wepClass )
						end
						local wepText = #wepNames > 0 and ( "Issued weapons: " .. table.concat( wepNames, ", " ) ) or "Issued weapons: None"

						catalog:AddItem( {
							name = job.name,
							subtitle = job.category or "General",
							listSub = SWGRP.FormatCredits( job.salary ) .. " / payday",
							description = ( job.description or "" ) .. "\n\nAllegiance: " .. faction.name .. "\n" .. maxText .. "\n" .. voteText .. "\n" .. wepText,
							priceText = "Salary: " .. SWGRP.FormatCredits( job.salary ) .. " per payday",
							model = SWGRP.GetJobPreviewModel( job ),
							color = job.color or faction.color,
							actionText = "Assume Profession",
							onAction = function()
								local function submitJob( modelIndex )
									net.Start( "SWGRP_SetJob" )
										net.WriteUInt( teamId, 16 )
										net.WriteUInt( modelIndex or 0, 8 )
									net.SendToServer()
									frame:Close()
								end

								local models = SWGRP.GetJobModels( job )
								if #models > 1 then
									UI.OpenJobModelPicker( job, submitJob )
								else
									submitJob( 0 )
								end
							end,
						} )
					end
				end )
			end
		end
	end

	-- Equipment / entities (preview)
	local entCatalog = UI.CreateCatalogTab( sheet, "Equipment", "icon16/brick.png" )
	for class, data in SortedPairsByMemberValue( SWGRP.Entities, "name" ) do
		local maxText = data.max and ( "Max owned: " .. data.max ) or ""
		entCatalog:AddItem( {
			name = data.name,
			subtitle = data.category or "Equipment",
			listSub = SWGRP.FormatCredits( data.price ),
			description = "An item for you, or your property. Can be pocketed.\n" .. maxText,
			priceText = "Cost: " .. SWGRP.FormatCredits( data.price ),
			model = SWGRP.GetEntityPreviewModel( class, data ),
			color = UI.Colors.accent,
			actionText = "Purchase Equipment",
			onAction = function()
				net.Start( "SWGRP_BuyEntity" )
					net.WriteString( class )
				net.SendToServer()
			end,
		} )
	end
	entCatalog:AutoSelectFirst()

	-- Vehicles (preview)
	if #SWGRP.Vehicles > 0 then
		local vehCatalog = UI.CreateCatalogTab( sheet, "Vehicles", "icon16/car.png" )
		for id, veh in ipairs( SWGRP.Vehicles ) do
			vehCatalog:AddItem( {
				name = veh.name,
				subtitle = veh.category or "Transport",
				listSub = SWGRP.FormatCredits( veh.price ),
				description = "Personal transport vehicle.\nClass: " .. ( veh.class or "unknown" ),
				priceText = "Cost: " .. SWGRP.FormatCredits( veh.price ),
				model = SWGRP.GetVehiclePreviewModel( veh ),
				color = UI.Colors.primary,
				actionText = "Purchase Vehicle",
				onAction = function()
					net.Start( "SWGRP_BuyVehicle" )
						net.WriteUInt( id, 8 )
					net.SendToServer()
				end,
			} )
		end
		vehCatalog:AutoSelectFirst()
	end

	-- Shipments (preview)
	if #SWGRP.Shipments > 0 then
		local shipCatalog = UI.CreateCatalogTab( sheet, "Shipments", "icon16/box.png" )
		for sid, ship in ipairs( SWGRP.Shipments ) do
		shipCatalog:AddItem( {
			name = ship.name,
			subtitle = ship.category or "Shipments",
			listSub = SWGRP.FormatCredits( ship.price ) .. " crate",
			description = "Weapon shipment crate.\nContains: " .. ship.amount .. " items",
			priceText = "Crate: " .. SWGRP.FormatCredits( ship.price ) .. "  |  Single: " .. SWGRP.FormatCredits( ship.pricesep or ship.price ),
			model = SWGRP.GetShipmentPreviewModel( ship ),
			color = Color( 255, 120, 50 ),
			actionText = "Buy Full Crate",
			onAction = function()
				net.Start( "SWGRP_BuyShipment" )
					net.WriteUInt( sid, 8 )
					net.WriteBool( false )
				net.SendToServer()
			end,
		} )

		if ship.separate then
			shipCatalog:AddItem( {
				name = ship.name .. " (Single)",
				subtitle = "Individual purchase",
				listSub = SWGRP.FormatCredits( ship.pricesep ),
				description = "Purchase a single item from this shipment.",
				priceText = "Cost: " .. SWGRP.FormatCredits( ship.pricesep ),
				model = SWGRP.GetWeaponWorldModel( ship.entities and ship.entities[1] ),
				color = Color( 255, 120, 50 ),
				actionText = "Buy Single Item",
				onAction = function()
					net.Start( "SWGRP_BuyShipment" )
						net.WriteUInt( sid, 8 )
						net.WriteBool( true )
					net.SendToServer()
				end,
			} )
			end
		end
		shipCatalog:AutoSelectFirst()
	end

	-- Ammunition — purchase cells here; press R while holding a blaster to load
		if table.Count( SWGRP.AmmoTypes ) > 0 then
		local ammoCatalog = UI.CreateCatalogTab( sheet, "Ammunition", "icon16/bullet_add.png" )
		local perCell = SWGRP.Config.AmmoRoundsPerEnergyCell or 5
		for name, data in SortedPairsByMemberValue( SWGRP.AmmoTypes, "name" ) do
			local loadHint = "Press R to load purchased cells into your blaster."
			ammoCatalog:AddItem( {
				name = data.name,
				subtitle = data.category or "Ammunition",
				listSub = SWGRP.FormatCredits( data.price ),
				description = data.ammoType == "energy_cell"
					and string.format( "Energy cells (%d rounds each).\nAmount: %d\n\n%s", perCell, data.amountGiven or 0, loadHint )
					or "Ammunition packs.\nAmount: " .. ( data.amountGiven or 0 ),
				priceText = "Cost: " .. SWGRP.FormatCredits( data.price ),
				model = SWGRP.GetAmmoPreviewModel( data ),
				color = UI.Colors.secondary,
				actionText = "Purchase Ammo",
				onAction = function()
					net.Start( "SWGRP_BuyAmmo" )
						net.WriteString( name )
					net.SendToServer()
				end,
			} )
		end
		ammoCatalog:AutoSelectFirst()
	end

end

--[[---------------------------------------------------------------------------
    Colony datapad (F3): Missions, Crafting, Status, Banking, Governance, Bounties
---------------------------------------------------------------------------]]

local function ServiceEmptyState( scroll, UI, text )
	local lbl = UI.CreateLabel( scroll, text, "DermaDefault", UI.Colors.secondary, TOP )
	if IsValid( lbl ) then
		lbl:DockMargin( 2, 2, 2, 2 )
	end
end

-- A tab whose body is a scroll panel, so long sections (banking, governance,
-- bounties) never clip their bottom controls.
local function ScrolledServiceTab( sheet, UI, tabName, icon )
	local inner = UI.CreateTabPanel( sheet, tabName, icon )
	local scroll = vgui.Create( "DScrollPanel", inner )
	scroll:Dock( FILL )
	UI.StyleScrollPanel( scroll )
	scroll.Paint = nil
	return scroll
end

local function BuildServices( sheet, UI, frame )
	local ply = LocalPlayer()

	-- Missions
	local missionScroll = UI.CreateSimpleListTab( sheet, "Missions", "icon16/flag_blue.png" )
	UI.CreateSectionHeader( missionScroll, "Available Contracts", { first = true } )
	if table.Count( SWGRP.Missions ) == 0 then
		ServiceEmptyState( missionScroll, UI, "No missions are available right now." )
	else
		for id, mission in SortedPairsByMemberValue( SWGRP.Missions, "name" ) do
			UI.AddListButton( missionScroll,
				mission.name .. "  —  " .. SWGRP.FormatCredits( mission.reward ),
				mission.description,
				function()
					net.Start( "SWGRP_AcceptMission" )
						net.WriteUInt( id, 8 )
					net.SendToServer()
				end
			)
		end
	end

	-- Crafting
	local craftScroll = UI.CreateSimpleListTab( sheet, "Crafting", "icon16/wrench.png" )
	UI.CreateSectionHeader( craftScroll, "Fabrication Recipes", { first = true } )
	if table.Count( SWGRP.Recipes ) == 0 then
		ServiceEmptyState( craftScroll, UI, "No crafting recipes are unlocked yet." )
	else
		for rid, recipe in SortedPairsByMemberValue( SWGRP.Recipes, "name" ) do
			local mats = {}
			if recipe.materials then
				for mat, count in pairs( recipe.materials ) do
					table.insert( mats, mat .. " x" .. count )
				end
			end
			local matText = #mats > 0 and table.concat( mats, ", " ) or "No materials"
			UI.AddListButton( craftScroll,
				recipe.name,
				"Requires: " .. matText,
				function()
					net.Start( "SWGRP_CraftItem" )
						net.WriteString( rid )
					net.SendToServer()
				end
			)
		end
	end

	-- Status
	local statusInner = UI.CreateTabPanel( sheet, "Status", "icon16/user.png" )
	UI.CreateSectionHeader( statusInner, "Colony Status", { first = true } )

	local statusScroll = vgui.Create( "DScrollPanel", statusInner )
	statusScroll:Dock( FILL )
	statusScroll:DockMargin( 0, 0, 0, 0 )
	UI.StyleScrollPanel( statusScroll )

	local lines = {
		{ "Profession", ply:SWGRP_GetJobName() .. "  —  Level " .. ply:SWGRP_GetProfLevel(), UI.Colors.primary },
		{ "Wallet", SWGRP.FormatCredits( ply:SWGRP_GetCredits() ), UI.Colors.secondary },
		{ "Bank", SWGRP.FormatCredits( ply:SWGRP_GetBank() ), UI.Colors.secondary },
		{ "Salary", SWGRP.FormatCredits( ply:SWGRP_GetSalary() ) .. " / payday", UI.Colors.secondary },
		{ "Hunger", ply:SWGRP_GetHunger() .. "%", UI.Colors.accent },
		{ "Imperial Standing", tostring( ply:SWGRP_GetFaction( "imperial" ) ), Color( 180, 180, 220 ) },
		{ "Rebel Standing", tostring( ply:SWGRP_GetFaction( "rebel" ) ), Color( 255, 100, 80 ) },
		{ "Underworld Standing", tostring( ply:SWGRP_GetFaction( "underworld" ) ), Color( 150, 50, 200 ) },
		{ "Materials", "Metal " .. ply:SWGRP_GetMaterial( "metal" ) .. "  Chem " .. ply:SWGRP_GetMaterial( "chemical" ) .. "  Fiber " .. ply:SWGRP_GetMaterial( "fiber" ) .. "  Elec " .. ply:SWGRP_GetMaterial( "electronics" ), UI.Colors.secondary },
	}

	for i, line in ipairs( lines ) do
		local row = vgui.Create( "DPanel", statusScroll )
		row:Dock( TOP )
		row:DockMargin( 0, 0, 0, UI.Spacing.gap )
		row.Paint = UI.PaintListItem

		local nameLbl = UI.CreateLabel( row, line[1], "DermaDefaultBold", UI.Colors.primary, TOP )
		nameLbl:DockMargin( 14, 10, 14, 0 )

		local valLbl = UI.CreateLabel( row, line[2], "DermaDefault", line[3] or UI.Colors.secondary, TOP )
		valLbl:DockMargin( 14, 2, 14, 10 )

		row:InvalidateLayout( true )
		row:SizeToChildren( false, true )
		row:SetTall( math.max( row:GetTall(), UI.Spacing.listItem ) )
	end

	-- Banking
	local bankInner = ScrolledServiceTab( sheet, UI, "Banking", "icon16/money.png" )
	if IsValid( bankInner ) then
		UI.CreateSectionHeader( bankInner, "Galactic Banking", { first = true } )

		local bankSummary = UI.CreateLabel( bankInner, "Bank: " .. SWGRP.FormatCredits( ply:SWGRP_GetBank() ) .. "   |   Wallet: " .. SWGRP.FormatCredits( ply:SWGRP_GetCredits() ), "DermaDefault", UI.Colors.secondary, TOP )
		F4Dock( bankSummary, nil, { 0, 0, 0, UI.Spacing.gapLarge } )

		local bankEntry = vgui.Create( "DTextEntry", bankInner )
		bankEntry:Dock( TOP )
		bankEntry:DockMargin( 0, 0, 0, UI.Spacing.gap )
		bankEntry:SetPlaceholderText( "Credit amount..." )
		UI.StyleTextEntry( bankEntry )

		F4Dock( UI.CreateButton( bankInner, "Deposit Credits", function()
			net.Start( "SWGRP_BankAction" )
				net.WriteString( "deposit" )
				net.WriteUInt( tonumber( bankEntry:GetValue() ) or 0, 32 )
				net.WriteString( "" )
			net.SendToServer()
		end ), TOP, { 0, 0, 0, UI.Spacing.gap } )

		F4Dock( UI.CreateButton( bankInner, "Withdraw Credits", function()
			net.Start( "SWGRP_BankAction" )
				net.WriteString( "withdraw" )
				net.WriteUInt( tonumber( bankEntry:GetValue() ) or 0, 32 )
				net.WriteString( "" )
			net.SendToServer()
		end ), TOP, nil )
	end

	-- Governor
	if ply:SWGRP_IsGovernor() then
		local govInner = ScrolledServiceTab( sheet, UI, "Governance", "icon16/star.png" )
		UI.CreateSectionHeader( govInner, "Planetary Governance", { first = true } )

		UI.CreateButton( govInner, "Initiate Imperial Lockdown", function()
			net.Start( "SWGRP_GovernorAction" )
				net.WriteString( "lockdown" )
			net.SendToServer()
		end ):Dock( TOP ):DockMargin( 0, 0, 0, UI.Spacing.gap )

		UI.CreateButton( govInner, "Lift Lockdown", function()
			net.Start( "SWGRP_GovernorAction" )
				net.WriteString( "endlockdown" )
			net.SendToServer()
		end ):Dock( TOP ):DockMargin( 0, 0, 0, UI.Spacing.gapLarge )

		local lawEntry = vgui.Create( "DTextEntry", govInner )
		lawEntry:Dock( TOP )
		lawEntry:DockMargin( 0, 0, 0, UI.Spacing.gap )
		lawEntry:SetPlaceholderText( "New planetary law..." )
		UI.StyleTextEntry( lawEntry )

		UI.CreateButton( govInner, "Add Law", function()
			net.Start( "SWGRP_GovernorAction" )
				net.WriteString( "addlaw" )
				net.WriteString( lawEntry:GetValue() )
			net.SendToServer()
			lawEntry:SetValue( "" )
		end ):Dock( TOP )
	end

	-- Bounties
	local hitInner = ScrolledServiceTab( sheet, UI, "Bounties", "icon16/ruby.png" )
	UI.CreateSectionHeader( hitInner, "Bounty Contracts", { first = true } )

	local targetEntry = vgui.Create( "DTextEntry", hitInner )
	targetEntry:Dock( TOP )
	targetEntry:DockMargin( 0, 0, 0, UI.Spacing.gap )
	targetEntry:SetPlaceholderText( "Target name..." )
	UI.StyleTextEntry( targetEntry )

	local priceEntry = vgui.Create( "DTextEntry", hitInner )
	priceEntry:Dock( TOP )
	priceEntry:DockMargin( 0, 0, 0, UI.Spacing.gapLarge )
	priceEntry:SetPlaceholderText( "Bounty amount..." )
	UI.StyleTextEntry( priceEntry )

	UI.CreateButton( hitInner, "Place Bounty Contract", function()
		net.Start( "SWGRP_RequestHit" )
			net.WriteString( targetEntry:GetValue() )
			net.WriteUInt( tonumber( priceEntry:GetValue() ) or 500, 32 )
		net.SendToServer()
	end ):Dock( TOP )
end

--[[---------------------------------------------------------------------------
    Entry points
---------------------------------------------------------------------------]]

function SWGRP.OpenF4Menu()
	OpenMenu( "F4Frame", "GALACTIC PROFESSION TERMINAL", BuildShop )
end

function SWGRP.OpenServicesMenu()
	OpenMenu( "ServicesFrame", "COLONY DATAPAD", BuildServices )
end

function GM:ShowSpare2()
	SWGRP.OpenF4Menu()
end

function GM:ShowSpare1()
	SWGRP.OpenServicesMenu()
end

concommand.Add( "swgrp_f4", function()
	SWGRP.OpenF4Menu()
end )

concommand.Add( "swgrp_services", function()
	SWGRP.OpenServicesMenu()
end )

--[[---------------------------------------------------------------------------
    FAdmin scoreboard integration for SWGRP
---------------------------------------------------------------------------]]

if not FAdmin or not FAdmin.StartHooks then return end

FAdmin.StartHooks["SWGRP"] = function()
	if not FAdmin.ScoreBoard or not FAdmin.ScoreBoard.Player then return end

	FAdmin.ScoreBoard.Player:AddInformation( "Credits", function( ply )
		if not IsValid( ply ) then return end
		return SWGRP.FormatCredits( ply:SWGRP_GetCredits() )
	end )

	FAdmin.ScoreBoard.Player:AddInformation( "Bank", function( ply )
		if not IsValid( ply ) or not LocalPlayer():IsAdmin() then return end
		return SWGRP.FormatCredits( ply:SWGRP_GetBank() )
	end )

	FAdmin.ScoreBoard.Player:AddInformation( "Profession", function( ply )
		if not IsValid( ply ) then return end
		return ply:SWGRP_GetJobName()
	end )

	FAdmin.ScoreBoard.Player:AddInformation( "Wanted", function( ply )
		if not IsValid( ply ) or not ply:SWGRP_IsWanted() then return end
		return ply:SWGRP_GetWantedReason()
	end )

	FAdmin.ScoreBoard.Player:AddInformation( "Steam name", function( ply )
		if not IsValid( ply ) then return end
		if ply.SteamName then return ply:SteamName() end
		return ply:Nick()
	end )

	if not FAdmin.ScoreBoard.Player.AddActionButton then return end

	local function canManage( ply )
		return FAdmin.Access.PlayerHasPrivilege( LocalPlayer(), "SWGRP_AdminCommands", ply )
	end

	FAdmin.ScoreBoard.Player:AddActionButton( "Set Credits", "icon16/money.png",
		Color( 80, 180, 80, 255 ), canManage,
		function( ply )
			Derma_StringRequest( "Set Credits",
				"Set credit balance for " .. ply:Nick(),
				tostring( ply:SWGRP_GetCredits() ),
				function( text )
					RunConsoleCommand( "_FAdmin", "SWGRPSetCredits", ply:UserID(), text )
				end )
		end )

	FAdmin.ScoreBoard.Player:AddActionButton( "Give Credits", "icon16/money_add.png",
		Color( 80, 180, 80, 255 ), canManage,
		function( ply )
			Derma_StringRequest( "Give Credits",
				"Amount of credits to add to " .. ply:Nick(),
				"100",
				function( text )
					RunConsoleCommand( "_FAdmin", "SWGRPGiveCredits", ply:UserID(), text )
				end )
		end )

	FAdmin.ScoreBoard.Player:AddActionButton( "Set Job", "icon16/user_suit.png",
		Color( 90, 140, 220, 255 ), canManage,
		function( ply )
			local menu = DermaMenu()

			local list = {}
			for id, job in pairs( SWGRP.Jobs ) do
				list[#list + 1] = { id = id, name = job.name or job.command, command = job.command }
			end
			table.sort( list, function( a, b ) return ( a.name or "" ) < ( b.name or "" ) end )

			for _, j in ipairs( list ) do
				if not j.command then continue end
				menu:AddOption( j.name, function()
					RunConsoleCommand( "_FAdmin", "SWGRPSetJob", ply:UserID(), j.command )
				end )
			end

			menu:Open()
		end )

	FAdmin.ScoreBoard.Player:AddActionButton(
		function( ply ) return ply:SWGRP_IsArrested() and "Release" or "Arrest" end,
		"icon16/lock.png", Color( 210, 120, 40, 255 ), canManage,
		function( ply )
			RunConsoleCommand( "_FAdmin", "SWGRPArrest", ply:UserID() )
		end )

	FAdmin.ScoreBoard.Player:AddActionButton(
		function( ply ) return ply:SWGRP_IsWanted() and "Clear Wanted" or "Mark Wanted" end,
		"icon16/error.png", Color( 190, 60, 60, 255 ), canManage,
		function( ply )
			if ply:SWGRP_IsWanted() then
				RunConsoleCommand( "_FAdmin", "SWGRPWanted", ply:UserID() )
			else
				Derma_StringRequest( "Mark Wanted",
					"Reason for wanting " .. ply:Nick(),
					"Wanted by administration",
					function( text )
						RunConsoleCommand( "_FAdmin", "SWGRPWanted", ply:UserID(), text )
					end )
			end
		end )

	FAdmin.ScoreBoard.Player:AddActionButton( "Heal", "icon16/heart.png",
		Color( 80, 200, 120, 255 ), canManage,
		function( ply )
			RunConsoleCommand( "_FAdmin", "SWGRPHeal", ply:UserID() )
		end )

	FAdmin.ScoreBoard.Player:AddActionButton( "Slay", "icon16/bomb.png",
		Color( 190, 60, 60, 255 ), canManage,
		function( ply )
			RunConsoleCommand( "_FAdmin", "SWGRPSlay", ply:UserID() )
		end )
end

-- Register command stubs client-side so they appear in the FAdmin command list
-- and gain console autocomplete (command names + player names, plus arg hints).
FAdmin.StartHooks["SWGRP_Commands"] = function()
	if not FAdmin.Commands or not FAdmin.Commands.AddCommand then return end

	local jobHint = "<job command>"
	local jobs = {}
	for _, j in pairs( SWGRP.Jobs or {} ) do
		if j.command then jobs[#jobs + 1] = j.command end
	end
	table.sort( jobs )
	if #jobs > 0 then jobHint = "<" .. table.concat( jobs, "/" ) .. ">" end

	FAdmin.Commands.AddCommand( "SWGRPSetCredits",    nil, "<Player>", "<amount>" )
	FAdmin.Commands.AddCommand( "SWGRPGiveCredits",   nil, "<Player>", "<amount>" )
	FAdmin.Commands.AddCommand( "SWGRPSetJob",        nil, "<Player>", jobHint )
	FAdmin.Commands.AddCommand( "SWGRPArrest",        nil, "<Player>" )
	FAdmin.Commands.AddCommand( "SWGRPUnArrest",      nil, "<Player>" )
	FAdmin.Commands.AddCommand( "SWGRPWanted",        nil, "<Player>", "[reason]" )
	FAdmin.Commands.AddCommand( "SWGRPUnWanted",      nil, "<Player>" )
	FAdmin.Commands.AddCommand( "SWGRPHeal",          nil, "<Player>", "[amount]" )
	FAdmin.Commands.AddCommand( "SWGRPSlay",          nil, "<Player>" )
	FAdmin.Commands.AddCommand( "SWGRPReloadContent", nil )
	FAdmin.Commands.AddCommand( "SWGRPReindexDoors",  nil )
end

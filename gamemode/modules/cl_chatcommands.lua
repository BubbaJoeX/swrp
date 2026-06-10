--[[---------------------------------------------------------------------------
    Redirect engine cheat commands to SWGRP credit chat commands.
    Without this, console "give 10000" hits GMod's SuperAdmin gate instead of
    moving credits.
---------------------------------------------------------------------------]]

local function sayChatCommand( cmd, amount )
	local text = "/" .. cmd
	if amount then
		text = text .. " " .. tostring( amount )
	end
	RunConsoleCommand( "say", text )
end

concommand.Add( "give", function( _, cmd, args )
	local amount = tonumber( args[1] )
	if amount and amount > 0 then
		sayChatCommand( "pay", amount )
		return
	end
	chat.AddText( Color( 255, 120, 80 ), "Use /pay <amount> (look at a player) or /dropcredits <amount> in chat." )
end )

concommand.Add( "dropcredits", function( _, cmd, args )
	local amount = tonumber( args[1] )
	if not amount then
		chat.AddText( Color( 255, 120, 80 ), "Usage: /dropcredits <amount> in chat, or dropcredits <amount> in console." )
		return
	end
	sayChatCommand( "dropcredits", amount )
end )

concommand.Add( "moneydrop", function( _, cmd, args )
	local amount = tonumber( args[1] )
	if not amount then
		chat.AddText( Color( 255, 120, 80 ), "Usage: /dropcredits <amount> in chat, or moneydrop <amount> in console." )
		return
	end
	sayChatCommand( "dropcredits", amount )
end )

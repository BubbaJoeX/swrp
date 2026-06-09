--[[---------------------------------------------------------------------------
    Chat Command Processing
---------------------------------------------------------------------------]]

function SWGRP.ProcessChat( ply, text, teamChat )
	if not IsValid( ply ) then return "" end
	if string.sub( text, 1, 1 ) ~= "/" then return end

	local args = SWGRP.Util.SplitArgs( string.sub( text, 2 ) )
	local cmd = string.lower( args[1] or "" )
	table.remove( args, 1 )

	local data = SWGRP.ChatCmds[cmd]
	if data and data.execute then
		data.execute( ply, args )
		return ""
	end

	return ""
end

hook.Add( "PlayerSay", "SWGRP_ChatCommands", function( ply, text, teamChat )
	return SWGRP.ProcessChat( ply, text, teamChat )
end )

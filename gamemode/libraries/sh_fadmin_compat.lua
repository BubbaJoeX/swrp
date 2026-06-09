--[[---------------------------------------------------------------------------
    DarkRP API shims for bundled FAdmin (from https://github.com/FPtje/DarkRP)
---------------------------------------------------------------------------]]

DarkRP = DarkRP or {}

-- FAdmin's bundled (DarkRP) build calls these unconditionally and also guards
-- some logic behind `if DarkRP then`. We expose a minimal, self-consistent shim
-- so those paths operate on SWGRP data instead of erroring on a missing full
-- DarkRP install. RPExtraTeams stays empty so FAdmin's changeteam falls back to
-- the standard team list.
RPExtraTeams = RPExtraTeams or {}

-- Concatenate a space to avoid text being parsed as a Valve localisation token.
local function safeText( text )
	text = text or ""
	return string.match( text, "^#([a-zA-Z_]+)$" ) and text .. " " or text
end

DarkRP.deLocalise = safeText

if CLIENT then
	-- Fonts that bundled FAdmin expects DarkRP to have created.
	surface.CreateFont( "Trebuchet18", { size = 18, weight = 500, antialias = true, font = "Trebuchet MS", extended = true } )
	surface.CreateFont( "Trebuchet20", { size = 20, weight = 500, antialias = true, font = "Trebuchet MS", extended = true } )
	surface.CreateFont( "Trebuchet24", { size = 24, weight = 500, antialias = true, font = "Trebuchet MS", extended = true } )
	surface.CreateFont( "Roboto18", { size = 18, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "Roboto20", { size = 20, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "Roboto22", { size = 22, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "TabLarge", { size = 18, weight = 700, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "UiBold", { size = 16, weight = 700, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "ScoreboardHeader", { size = 32, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "ScoreboardSubtitle", { size = 22, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "ScoreboardPlayerName", { size = 19, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "ScoreboardPlayerName2", { size = 15, weight = 500, antialias = true, font = "Roboto", extended = true } )
	surface.CreateFont( "ScoreboardPlayerNameBig", { size = 22, weight = 500, antialias = true, font = "Roboto", extended = true } )

	function draw.DrawNonParsedText( text, font, x, y, color, xAlign )
		return draw.DrawText( safeText( text ), font, x, y, color, xAlign )
	end

	function draw.DrawNonParsedSimpleText( text, font, x, y, color, xAlign, yAlign )
		return draw.SimpleText( safeText( text ), font, x, y, color, xAlign, yAlign )
	end

	function draw.DrawNonParsedSimpleTextOutlined( text, font, x, y, color, xAlign, yAlign, outlineWidth, outlineColor )
		return draw.SimpleTextOutlined( safeText( text ), font, x, y, color, xAlign, yAlign, outlineWidth, outlineColor )
	end

	function surface.DrawNonParsedText( text )
		return surface.DrawText( safeText( text ) )
	end

	function chat.AddNonParsedText( ... )
		local tbl = { ... }
		for i = 2, #tbl, 2 do
			tbl[i] = safeText( tbl[i] )
		end
		return chat.AddText( unpack( tbl ) )
	end
end

function DarkRP.toInt( n, default )
	return tonumber( n ) or default
end

function DarkRP.getPhrase( key )
	return key
end

function DarkRP.formatMoney( amount )
	if SWGRP and SWGRP.FormatCredits then
		return SWGRP.FormatCredits( amount or 0 )
	end
	return tostring( amount or 0 )
end

function DarkRP.nickSortedPlayers()
	local players = player.GetAll()
	table.sort( players, function( a, b )
		return string.lower( a:Nick() ) < string.lower( b:Nick() )
	end )
	return players
end

local meta = FindMetaTable( "Player" )
if meta then
	function meta:getDarkRPVar( key )
		if key == "job" then
			return self:SWGRP_GetJobName()
		elseif key == "wanted" then
			return self:SWGRP_IsWanted()
		elseif key == "wantedReason" then
			return self:SWGRP_GetWantedReason()
		end
	end

	function meta:isWanted()
		return self:SWGRP_IsWanted()
	end

	function meta:getWantedReason()
		return self:SWGRP_GetWantedReason()
	end

	function meta:isCP()
		return self:SWGRP_IsGovernment()
	end
end

hook.Add( "DatabaseInitialized", "SWGRP_FAdminDarkRPDB", function()
	hook.Run( "DarkRPDBInitialized" )
end )

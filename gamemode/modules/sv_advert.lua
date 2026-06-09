--[[---------------------------------------------------------------------------
    Adverts & Broadcasts - on-screen popup HUD banners
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Advert = SWGRP.Advert or {}

function SWGRP.Advert.Cooldown()
	return SWGRP.Config and SWGRP.Config.AdvertCooldown or 5
end

-- title: small label, body: message, color: banner accent.
function SWGRP.Advert.Broadcast( title, body, color )
	color = color or ( SWGRP.Config and SWGRP.Config.HUDColorPrimary ) or Color( 255, 180, 50 )

	net.Start( "SWGRP_Advert" )
		net.WriteString( title or "" )
		net.WriteString( body or "" )
		net.WriteUInt( color.r, 8 )
		net.WriteUInt( color.g, 8 )
		net.WriteUInt( color.b, 8 )
	net.Broadcast()
end

-- Sends an advert from a player, enforcing a per-player cooldown.
function SWGRP.Advert.Send( ply, title, body, color )
	if IsValid( ply ) then
		local now = CurTime()
		if ply.SWGRP_NextAdvert and ply.SWGRP_NextAdvert > now then
			SWGRP.Notify( ply, "Advert on cooldown (" .. math.ceil( ply.SWGRP_NextAdvert - now ) .. "s)." )
			return false
		end
		ply.SWGRP_NextAdvert = now + SWGRP.Advert.Cooldown()
	end

	body = string.Trim( body or "" )
	if body == "" then return false end

	SWGRP.Advert.Broadcast( title, body, color )
	SWGRP.Log( "chat", "[" .. ( title or "Advert" ) .. "] " .. ( IsValid( ply ) and ply:Nick() or "Server" ) .. ": " .. body )
	return true
end

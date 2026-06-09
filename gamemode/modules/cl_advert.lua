--[[---------------------------------------------------------------------------
    Advert / Broadcast on-screen popup HUD
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Advert = SWGRP.Advert or {}

SWGRP.Advert.Active = SWGRP.Advert.Active or nil

local HOLD_TIME = 6
local FADE_TIME = 0.6

net.Receive( "SWGRP_Advert", function()
	local title = net.ReadString()
	local body = net.ReadString()
	local color = Color( net.ReadUInt( 8 ), net.ReadUInt( 8 ), net.ReadUInt( 8 ) )

	SWGRP.Advert.Active = {
		title = title,
		body = body,
		color = color,
		start = CurTime(),
	}

	surface.PlaySound( "buttons/button17.wav" )
end )

hook.Add( "HUDPaint", "SWGRP_AdvertHUD", function()
	local a = SWGRP.Advert.Active
	if not a then return end

	local elapsed = CurTime() - a.start
	local total = HOLD_TIME + FADE_TIME
	if elapsed > total then
		SWGRP.Advert.Active = nil
		return
	end

	local alpha = 255
	if elapsed > HOLD_TIME then
		alpha = 255 * ( 1 - ( elapsed - HOLD_TIME ) / FADE_TIME )
	elseif elapsed < 0.3 then
		alpha = 255 * ( elapsed / 0.3 )
	end
	alpha = math.Clamp( alpha, 0, 255 )

	surface.SetFont( "DermaDefault" )
	local bodyW = surface.GetTextSize( a.body )
	surface.SetFont( "DermaDefaultBold" )
	local titleW = surface.GetTextSize( a.title )

	local w = math.max( bodyW, titleW ) + 48
	w = math.Clamp( w, 240, ScrW() * 0.8 )
	local h = 50
	local x = ScrW() / 2 - w / 2
	local y = ScrH() * 0.16

	surface.SetDrawColor( 10, 15, 25, alpha * 0.88 )
	surface.DrawRect( x, y, w, h )

	surface.SetDrawColor( a.color.r, a.color.g, a.color.b, alpha )
	surface.DrawOutlinedRect( x, y, w, h, 1 )
	surface.DrawRect( x, y, 4, h )

	draw.SimpleText( a.title, "DermaDefaultBold", x + 16, y + 12,
		Color( a.color.r, a.color.g, a.color.b, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( a.body, "DermaDefault", x + 16, y + 32,
		Color( 230, 230, 230, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end )

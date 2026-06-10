--[[---------------------------------------------------------------------------
    Holo sign menu actions
---------------------------------------------------------------------------]]

net.Receive( "SWGRP_HoloSignAction", function( _, ply )
	local ent = net.ReadEntity()
	local text = net.ReadString()
	if not IsValid( ent ) or not IsValid( ply ) then return end
	if ent:GetClass() ~= "swgrp_holo_sign" then return end
	if ply:GetPos():DistToSqr( ent:GetPos() ) > 200 * 200 then return end

	ent:SetSignMessage( ply, text )
end )

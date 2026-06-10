--[[---------------------------------------------------------------------------
    Casino bet handling
---------------------------------------------------------------------------]]

net.Receive( "SWGRP_CasinoBet", function( _, ply )
	local ent = net.ReadEntity()
	local bet = net.ReadUInt( 16 )
	if not IsValid( ent ) or not IsValid( ply ) then return end

	local class = ent:GetClass()
	if class ~= "swgrp_casino_machine_s01" and class ~= "swgrp_casino_machine_s02" then return end
	if ply:GetPos():DistToSqr( ent:GetPos() ) > 200 * 200 then return end

	if ent.Play then
		ent:Play( ply, bet )
	end
end )

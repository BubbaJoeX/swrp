--[[---------------------------------------------------------------------------
    Tip jar menu actions
---------------------------------------------------------------------------]]

net.Receive( "SWGRP_TipJarAction", function( _, ply )
	local ent = net.ReadEntity()
	local action = net.ReadString()
	local amount = net.ReadUInt( 32 )
	if not IsValid( ent ) or not IsValid( ply ) then return end
	if ent:GetClass() ~= "swgrp_tipjar" then return end
	if ply:GetPos():DistToSqr( ent:GetPos() ) > 200 * 200 then return end

	if action == "collect" then
		ent:CollectTips( ply )
	elseif action == "tip" then
		ent:GiveTip( ply, amount )
	end
end )

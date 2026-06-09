--[[---------------------------------------------------------------------------
    Prop Ownership Protection
---------------------------------------------------------------------------]]

hook.Add( "PlayerSpawnedProp", "SWGRP_PropOwner", function( ply, model, ent )
	ent.SWGRP_Owner = ply
	if ent.CPPISetOwner then ent:CPPISetOwner( ply ) end
end )

hook.Add( "CanTool", "SWGRP_PropProtect", function( ply, tr, tool )
	if not IsValid( tr.Entity ) then return end
	if tr.Entity.SWGRP_Owner and tr.Entity.SWGRP_Owner ~= ply and not ply:IsAdmin() then
		return false
	end
end )

hook.Add( "PhysgunPickup", "SWGRP_PropProtectPhys", function( ply, ent )
	if ent.SWGRP_Owner and ent.SWGRP_Owner ~= ply and not ply:IsAdmin() then
		return false
	end
end )

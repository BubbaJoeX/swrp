--[[---------------------------------------------------------------------------
    Medic / Doctor Healing
---------------------------------------------------------------------------]]

hook.Add( "EntityTakeDamage", "SWGRP_MedicHeal", function( target, dmginfo )
	-- Reserved for future medic ability tuning
end )

concommand.Add( "swgrp_heal", function( ply )
	if not IsValid( ply ) or not ply:SWGRP_IsMedic() then return end

	local tr = ply:GetEyeTrace()
	if not IsValid( tr.Entity ) or not tr.Entity:IsPlayer() then return end
	if tr.HitPos:DistToSqr( ply:GetPos() ) > 10000 then return end

	tr.Entity:SetHealth( tr.Entity:GetMaxHealth() )
	tr.Entity:SetArmor( math.min( 100, tr.Entity:Armor() + 50 ) )
	SWGRP.Notify( ply, "Patient treated." )
end )

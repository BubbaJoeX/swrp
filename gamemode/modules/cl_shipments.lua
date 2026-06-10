--[[---------------------------------------------------------------------------
    Weapon pickup world labels (shipment crate visuals live on the entity file)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Shipment = SWGRP.Shipment or {}

local S = SWGRP.Shipment

function S.DrawWeaponPickup( ent )
	if not IsValid( ent ) then return end
	if ent:GetPos():Distance( EyePos() ) > 400 then return end

	local class = ent.ReadWeaponClass and ent:ReadWeaponClass() or ent:GetNW2String( "WeaponClass", "" )
	local name = class
	local swep = weapons.Get( class )
	if swep and swep.PrintName then name = swep.PrintName end

	if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
		SWGRP.UI.DrawWorldLabel( ent, name, "Press E to take", SWGRP.UI.Colors.accent )
	end
end

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_WeaponPickupDraw", function( depth, skybox )
	if depth or skybox then return end

	for _, ent in ipairs( ents.FindByClass( "swgrp_weapon_pickup" ) ) do
		S.DrawWeaponPickup( ent )
	end
end )

hook.Add( "EntityRemoved", "SWGRP_WeaponPickupCleanup", function( ent )
	if ent:GetClass() ~= "swgrp_weapon_pickup" then return end
	if IsValid( ent.SWGRP_CsWeapon ) then
		ent.SWGRP_CsWeapon:Remove()
	end
	ent.SWGRP_CsWeapon = nil
end )

--[[---------------------------------------------------------------------------
    Crafting materials (shared types + client read helpers)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Materials = SWGRP.Materials or {}

SWGRP.Materials.Types = { "metal", "chemical", "fiber", "electronics", "energy_cell" }

function SWGRP.Materials.ReadNW( ply, matType )
	if not IsValid( ply ) then return 0 end

	if matType == "energy_cell" then
		local cells = ply:GetNW2Int( "SWGRP_EnergyCells", -1 )
		if cells >= 0 then return cells end
	end

	local key = "SWGRP_Mat_" .. matType
	local n = ply:GetNW2Int( key, -1 )
	if n >= 0 then return n end
	return ply:GetNWInt( key, 0 )
end

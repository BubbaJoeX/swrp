--[[---------------------------------------------------------------------------
    Crafting Materials Inventory (server)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Materials = SWGRP.Materials or {}

function SWGRP.Materials.Get( ply, matType )
	ply.SWGRP_Materials = ply.SWGRP_Materials or {}
	return ply.SWGRP_Materials[matType] or 0
end

function SWGRP.Materials.WriteNW( ply, matType, amount )
	local key = "SWGRP_Mat_" .. matType
	ply:SetNW2Int( key, amount )
	if matType == "energy_cell" then
		ply:SetNW2Int( "SWGRP_EnergyCells", amount )
	end
end

function SWGRP.Materials.Set( ply, matType, amount )
	ply.SWGRP_Materials = ply.SWGRP_Materials or {}
	local max = SWGRP.Config and SWGRP.Config.MaxMaterials or 99
	ply.SWGRP_Materials[matType] = math.Clamp( math.floor( amount ), 0, max )
	SWGRP.Materials.WriteNW( ply, matType, ply.SWGRP_Materials[matType] )
	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
end

function SWGRP.Materials.Add( ply, matType, amount )
	SWGRP.Materials.Set( ply, matType, SWGRP.Materials.Get( ply, matType ) + amount )
end

function SWGRP.Materials.Has( ply, requirements )
	for mat, count in pairs( requirements ) do
		if SWGRP.Materials.Get( ply, mat ) < count then return false end
	end
	return true
end

function SWGRP.Materials.Take( ply, requirements )
	if not SWGRP.Materials.Has( ply, requirements ) then return false end
	for mat, count in pairs( requirements ) do
		SWGRP.Materials.Add( ply, mat, -count )
	end
	return true
end

function SWGRP.Materials.SyncAll( ply )
	if not IsValid( ply ) then return end
	for _, mat in ipairs( SWGRP.Materials.Types ) do
		SWGRP.Materials.WriteNW( ply, mat, SWGRP.Materials.Get( ply, mat ) )
	end
end

hook.Add( "PlayerSpawn", "SWGRP_MaterialsNW", function( ply )
	timer.Simple( 0, function()
		if IsValid( ply ) then
			SWGRP.Materials.SyncAll( ply )
		end
	end )
end )

-- Periodic resource gathering for scouts/artisans near map
timer.Create( "SWGRP_MaterialGather", 120, 0, function()
	local gatherTypes = { "metal", "chemical", "fiber", "electronics" }
	for _, ply in ipairs( player.GetAll() ) do
		if not ply:Alive() then continue end
		local job = SWGRP.GetJob( ply:Team() )
		if job and ( job.name == "Artisan" or job.name == "Colonist" ) then
			local mat = gatherTypes[math.random( #gatherTypes )]
			SWGRP.Materials.Add( ply, mat, 1 )
		end
	end
end )

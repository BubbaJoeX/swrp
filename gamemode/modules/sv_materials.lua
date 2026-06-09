--[[---------------------------------------------------------------------------
    Crafting Materials Inventory
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Materials = SWGRP.Materials or {}

SWGRP.Materials.Types = { "metal", "chemical", "fiber", "electronics" }

function SWGRP.Materials.Get( ply, matType )
	ply.SWGRP_Materials = ply.SWGRP_Materials or {}
	return ply.SWGRP_Materials[matType] or 0
end

function SWGRP.Materials.Set( ply, matType, amount )
	ply.SWGRP_Materials = ply.SWGRP_Materials or {}
	ply.SWGRP_Materials[matType] = math.Clamp( math.floor( amount ), 0, SWGRP.Config.MaxMaterials )
	ply:SetNWInt( "SWGRP_Mat_" .. matType, ply.SWGRP_Materials[matType] )
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
	for _, mat in ipairs( SWGRP.Materials.Types ) do
		ply:SetNWInt( "SWGRP_Mat_" .. mat, SWGRP.Materials.Get( ply, mat ) )
	end
end

-- Periodic resource gathering for scouts/artisans near map
timer.Create( "SWGRP_MaterialGather", 120, 0, function()
	for _, ply in ipairs( player.GetAll() ) do
		if not ply:Alive() then continue end
		local job = SWGRP.GetJob( ply:Team() )
		if job and ( job.name == "Artisan" or job.name == "Colonist" ) then
			local mat = SWGRP.Materials.Types[math.random( #SWGRP.Materials.Types )]
			SWGRP.Materials.Add( ply, mat, 1 )
		end
	end
end )

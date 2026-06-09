--[[---------------------------------------------------------------------------
    Contraband & Imperial Scanning
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Contraband = SWGRP.Contraband or {}

function SWGRP.Contraband.GetInventory( ply )
	ply.SWGRP_Contraband = ply.SWGRP_Contraband or {}
	return ply.SWGRP_Contraband
end

function SWGRP.Contraband.Add( ply, contrabandId, amount )
	amount = amount or 1
	local data = SWGRP.ContrabandTypes[contrabandId]
	if not data then return false end

	ply.SWGRP_Contraband = ply.SWGRP_Contraband or {}
	ply.SWGRP_Contraband[contrabandId] = ( ply.SWGRP_Contraband[contrabandId] or 0 ) + amount
	ply:SetNWInt( "SWGRP_ContraCount", SWGRP.Contraband.TotalCount( ply ) )
	SWGRP.Factions.Add( ply, "underworld", 2 )
	if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( ply ) end
	return true
end

function SWGRP.Contraband.TotalCount( ply )
	local total = 0
	for _, count in pairs( SWGRP.Contraband.GetInventory( ply ) ) do
		total = total + count
	end
	return total
end

function SWGRP.Contraband.Clear( ply )
	ply.SWGRP_Contraband = {}
	ply:SetNWInt( "SWGRP_ContraCount", 0 )
end

function SWGRP.Contraband.Scan( officer, target )
	if not IsValid( officer ) or not IsValid( target ) then return end
	if not officer:SWGRP_IsGovernment() then
		SWGRP.Notify( officer, SWGRP.Lang.not_government )
		return
	end
	if officer:GetPos():DistToSqr( target:GetPos() ) > SWGRP.Config.ScanRange ^ 2 then
		SWGRP.Notify( officer, "Target out of scan range." )
		return
	end

	local inv = SWGRP.Contraband.GetInventory( target )
	local found = false

	for id, count in pairs( inv ) do
		if count > 0 then
			local data = SWGRP.ContrabandTypes[id]
			found = true
			SWGRP.Notify( officer, "DETECTED: " .. data.name .. " x" .. count .. " on " .. target:Nick() )

			if SWGRP.Config.ContrabandFine and data.fine then
				local fine = data.fine * count
				if target:SWGRP_TakeCredits( fine ) then
					SWGRP.Notify( target, "Fined " .. SWGRP.FormatCredits( fine ) .. " for contraband." )
				else
					SWGRP.Police.SetWanted( target, "Possession of " .. data.name, officer )
				end
			end

			if data.wanted then
				SWGRP.Police.SetWanted( target, "Contraband: " .. data.name, officer )
			end

			SWGRP.Contraband.Clear( target )
			SWGRP.Hooks.Call( "SWGRPContrabandFound", officer, target, id, count )
			SWGRP.Factions.Add( officer, "imperial", 3 )
			SWGRP.Factions.Add( target, "imperial", -5 )
		end
	end

	if not found then
		SWGRP.Notify( officer, "Scan clear — no contraband detected on " .. target:Nick() )
	end
end

function SWGRP.Contraband.AcquireRandom( ply )
	local ids = {}
	for id in pairs( SWGRP.ContrabandTypes ) do table.insert( ids, id ) end
	local pick = ids[math.random( #ids )]
	SWGRP.Contraband.Add( ply, pick, 1 )
	local data = SWGRP.ContrabandTypes[pick]
	SWGRP.Notify( ply, "Acquired contraband: " .. data.name )
end

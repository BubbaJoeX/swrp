--[[---------------------------------------------------------------------------
    Jail Spawn Points - per-map positions for RP arrest teleportation
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JailSpawns = SWGRP.JailSpawns or {}

local JS = SWGRP.JailSpawns
JS.Data = JS.Data or {}

local REMOVE_RADIUS_SQR = 96 * 96

local function AdminAllowed( ply )
	return IsValid( ply ) and ply:IsAdmin()
end

local function StorageKey()
	return "swgrp_jailspawns_" .. game.GetMap()
end

function JS.SerializeSpawn( pos, ang )
	ang = ang or Angle( 0, 0, 0 )
	return {
		x = math.Round( pos.x, 2 ),
		y = math.Round( pos.y, 2 ),
		z = math.Round( pos.z, 2 ),
		pitch = math.Round( ang.p, 2 ),
		yaw = math.Round( ang.y, 2 ),
		roll = math.Round( ang.r, 2 ),
	}
end

function JS.DeserializeSpawn( row )
	if not row then return nil end
	return Vector( row.x or 0, row.y or 0, row.z or 0 ),
		Angle( row.pitch or row.p or 0, row.yaw or 0, row.roll or row.r or 0 )
end

function JS.ApplyToWorld()
	SWGRP.JailPositions = {}
	for _, row in ipairs( JS.Data ) do
		local pos, ang = JS.DeserializeSpawn( row )
		if pos then
			table.insert( SWGRP.JailPositions, { pos = pos, ang = ang } )
		end
	end
end

function JS.Save()
	if not SWGRP.DB or not SWGRP.DB.SetWorld then return end
	SWGRP.DB.SetWorld( StorageKey(), util.TableToJSON( JS.Data ) )
end

function JS.Load()
	JS.Data = {}

	if not SWGRP.DB or not SWGRP.DB.GetWorld then return end

	local raw = SWGRP.DB.GetWorld( StorageKey(), "[]" )
	local parsed = SWGRP.DB.ParseJSON( raw )
	if istable( parsed ) then
		JS.Data = parsed
	end

	JS.ApplyToWorld()
end

function JS.AddSpawn( ply, pos, ang )
	table.insert( JS.Data, JS.SerializeSpawn( pos, ang ) )
	JS.ApplyToWorld()
	JS.Save()
	return true, string.format( "Added jail point (%d total on this map).", #JS.Data )
end

function JS.RemoveNearest( ply, pos )
	if #JS.Data == 0 then
		return false, "No jail points on this map."
	end

	local bestIdx, bestDist
	for i, row in ipairs( JS.Data ) do
		local spPos = select( 1, JS.DeserializeSpawn( row ) )
		if spPos then
			local dist = spPos:DistToSqr( pos )
			if dist <= REMOVE_RADIUS_SQR and ( not bestDist or dist < bestDist ) then
				bestDist = dist
				bestIdx = i
			end
		end
	end

	if not bestIdx then
		return false, "No jail point within range."
	end

	table.remove( JS.Data, bestIdx )
	JS.ApplyToWorld()
	JS.Save()
	return true, "Removed nearest jail point."
end

function JS.ClearAll()
	if #JS.Data == 0 then
		return false, "No jail points to clear."
	end
	JS.Data = {}
	JS.ApplyToWorld()
	JS.Save()
	return true, "Cleared all jail points on this map."
end

function JS.SyncTo( ply )
	if not IsValid( ply ) then return end

	net.Start( "SWGRP_JailSpawnSync" )
		net.WriteUInt( #JS.Data, 16 )
		for _, row in ipairs( JS.Data ) do
			net.WriteFloat( row.x or 0 )
			net.WriteFloat( row.y or 0 )
			net.WriteFloat( row.z or 0 )
			net.WriteFloat( row.pitch or row.p or 0 )
			net.WriteFloat( row.yaw or 0 )
			net.WriteFloat( row.roll or row.r or 0 )
		end
	net.Send( ply )
end

function JS.OpenMenu( ply )
	if not AdminAllowed( ply ) then return end

	net.Start( "SWGRP_JailSpawnMenu" )
		net.WriteUInt( #JS.Data, 16 )
	net.Send( ply )

	JS.SyncTo( ply )
end

function JS.AddAtAim( ply )
	if not AdminAllowed( ply ) then return end

	local tr = ply:GetEyeTrace()
	if not tr.Hit then
		SWGRP.Notify( ply, "Aim at a valid surface." )
		return
	end

	local pos = tr.HitPos + tr.HitNormal * 4
	local ang = Angle( 0, ply:EyeAngles().y, 0 )
	local ok, msg = JS.AddSpawn( ply, pos, ang )
	SWGRP.Notify( ply, msg, ok and 0 or 1 )
	JS.SyncTo( ply )
end

function JS.RemoveAtAim( ply )
	if not AdminAllowed( ply ) then return end

	local tr = ply:GetEyeTrace()
	local ok, msg = JS.RemoveNearest( ply, tr.HitPos )
	SWGRP.Notify( ply, msg, ok and 0 or 1 )
	if ok then JS.SyncTo( ply ) end
end

function JS.AdminToolPrimary( ply )
	JS.AddAtAim( ply )
end

function JS.AdminToolSecondary( ply )
	JS.OpenMenu( ply )
end

function JS.AdminToolReload( ply )
	JS.RemoveAtAim( ply )
end

hook.Add( "InitPostEntity", "SWGRP_LoadJailSpawns", function()
	timer.Simple( 0, function()
		JS.Load()
	end )
end )

net.Receive( "SWGRP_JailSpawnAction", function( _, ply )
	if not AdminAllowed( ply ) then return end

	local action = net.ReadString()

	if action == "add_here" then
		JS.AddAtAim( ply )
		return
	end

	if action == "remove_nearest" then
		JS.RemoveAtAim( ply )
		return
	end

	if action == "clear" then
		local ok, msg = JS.ClearAll()
		SWGRP.Notify( ply, msg, ok and 0 or 1 )
		if ok then JS.SyncTo( ply ) end
		return
	end

	if action == "refresh" then
		JS.SyncTo( ply )
	end
end )

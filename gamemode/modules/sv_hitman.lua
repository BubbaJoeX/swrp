--[[---------------------------------------------------------------------------
    Bounty Hunter Contract System (Hitman equivalent)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Hitman = SWGRP.Hitman or {}

function SWGRP.Hitman.PlaceContract( customer, target, price )
	if not IsValid( customer ) or not IsValid( target ) then return end
	if customer == target then return end
	if not customer:SWGRP_IsBountyHunter() and not customer:SWGRP_IsGovernor() then
		-- Anyone can place hits, but bounty hunters collect
	end

	price = math.Clamp( math.floor( price ), SWGRP.Config.HitMinPrice, SWGRP.Config.HitMaxPrice )
	if not customer:SWGRP_TakeCredits( price ) then
		SWGRP.Notify( customer, SWGRP.Lang.cant_afford )
		return
	end

	SWGRP.HitContracts[target:SteamID()] = {
		customer = customer:SteamID(),
		target = target,
		price = price,
		time = os.time(),
	}

	SWGRP.Persistence.SaveBounty( target:SteamID(), customer:SteamID(), price )

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.hit_placed, target:Nick(), SWGRP.FormatCredits( price ) ) )
	end

	SWGRP.Hitman.Sync()
end

function SWGRP.Hitman.CompleteContract( hunter, target )
	if not IsValid( hunter ) or not IsValid( target ) then return end
	if not hunter:SWGRP_IsBountyHunter() then return end

	local contract = SWGRP.HitContracts[target:SteamID()]
	if not contract then return end

	hunter:SWGRP_AddCredits( contract.price )
	SWGRP.HitContracts[target:SteamID()] = nil
	SWGRP.Persistence.DeleteBounty( target:SteamID() )

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( string.format( SWGRP.Lang.hit_completed, SWGRP.FormatCredits( contract.price ) ) )
	end

	SWGRP.Hitman.Sync()
end

function SWGRP.Hitman.Sync( ply )
	local count = 0
	for _ in pairs( SWGRP.HitContracts ) do count = count + 1 end

	net.Start( "SWGRP_SyncHits" )
		net.WriteUInt( count, 8 )
		for sid, contract in pairs( SWGRP.HitContracts ) do
			net.WriteString( sid )
			local target = IsValid( contract.target ) and contract.target or player.GetBySteamID( sid )
			net.WriteString( IsValid( target ) and target:Nick() or sid )
			net.WriteUInt( contract.price, 32 )
		end
	if IsValid( ply ) then net.Send( ply ) else net.Broadcast() end
end

hook.Add( "PlayerDeath", "SWGRP_HitComplete", function( victim, inflictor, attacker )
	if not IsValid( attacker ) or not attacker:IsPlayer() then return end
	if attacker == victim then return end
	SWGRP.Hitman.CompleteContract( attacker, victim )
end )

net.Receive( "SWGRP_RequestHit", function( len, ply )
	local targetName = net.ReadString()
	local price = net.ReadUInt( 32 )
	local target = SWGRP.FindPlayer( targetName )
	if IsValid( target ) then
		SWGRP.Hitman.PlaceContract( ply, target, price )
	end
end )

hook.Add( "PlayerInitialSpawn", "SWGRP_SyncHits", function( ply )
	timer.Simple( 2, function()
		if IsValid( ply ) then SWGRP.Hitman.Sync( ply ) end
	end )
end )

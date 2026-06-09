--[[---------------------------------------------------------------------------
    Government - Governor, Laws, Lockdown, Lottery
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Government = SWGRP.Government or {}

SWGRP.Government.Lockdown = false
SWGRP.Government.LockdownEnd = 0
SWGRP.Government.LotteryPool = 0

function SWGRP.Government.GetGovernor()
	for _, ply in ipairs( player.GetAll() ) do
		if ply:SWGRP_IsGovernor() then return ply end
	end
end

function SWGRP.Government.SetAgenda( text )
	text = string.sub( text or "", 1, 256 )
	SetGlobalString( "SWGRP_Agenda", text )
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.SetLaw( index, text )
	if index < 1 or index > SWGRP.Config.MaxLaws then return end
	SWGRP.Laws[index] = string.sub( text, 1, 128 )
	SWGRP.Government.SyncLaws()
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.AddLaw( text )
	if #SWGRP.Laws >= SWGRP.Config.MaxLaws then return end
	table.insert( SWGRP.Laws, string.sub( text, 1, 128 ) )
	SWGRP.Government.SyncLaws()
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.RemoveLaw( index )
	if not SWGRP.Laws[index] then return end
	table.remove( SWGRP.Laws, index )
	SWGRP.Government.SyncLaws()
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.ResetLaws()
	SWGRP.Laws = table.Copy( SWGRP.Config.DefaultLaws )
	SWGRP.Government.SyncLaws()
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.SyncLaws( ply )
	net.Start( "SWGRP_SyncLaws" )
		net.WriteUInt( #SWGRP.Laws, 8 )
		for _, law in ipairs( SWGRP.Laws ) do
			net.WriteString( law )
		end
	if IsValid( ply ) then net.Send( ply ) else net.Broadcast() end
end

function SWGRP.Government.StartLockdown( ply )
	if not IsValid( ply ) or not ply:SWGRP_IsGovernor() then return end
	if SWGRP.Government.Lockdown then return end

	SWGRP.Government.Lockdown = true
	SWGRP.Government.LockdownEnd = CurTime() + SWGRP.Config.LockdownTime

	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( SWGRP.Lang.lockdown_start )
	end

	SWGRP.Government.SyncLockdown()

	timer.Create( "SWGRP_LockdownEnd", SWGRP.Config.LockdownTime, 1, function()
		SWGRP.Government.EndLockdown()
	end )
end

function SWGRP.Government.EndLockdown()
	if not SWGRP.Government.Lockdown then return end
	SWGRP.Government.Lockdown = false
	for _, p in ipairs( player.GetAll() ) do
		p:ChatPrint( SWGRP.Lang.lockdown_end )
	end
	SWGRP.Government.SyncLockdown()
end

function SWGRP.Government.SyncLockdown( ply )
	net.Start( "SWGRP_SyncLockdown" )
		net.WriteBool( SWGRP.Government.Lockdown )
		net.WriteFloat( SWGRP.Government.LockdownEnd )
	if IsValid( ply ) then net.Send( ply ) else net.Broadcast() end
end

function SWGRP.Government.BuyLotteryTicket( ply )
	if not ply:SWGRP_TakeCredits( SWGRP.Config.LotteryTicketCost ) then
		SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
		return
	end
	SWGRP.Government.LotteryPool = SWGRP.Government.LotteryPool + SWGRP.Config.LotteryTicketCost
	ply.SWGRP_LotteryTicket = true
	SWGRP.Notify( ply, "Lottery ticket purchased." )
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

function SWGRP.Government.RunLottery()
	if SWGRP.Government.LotteryPool <= 0 then return end
	local entrants = {}
	for _, ply in ipairs( player.GetAll() ) do
		if ply.SWGRP_LotteryTicket then table.insert( entrants, ply ) end
	end
	if #entrants == 0 then return end

	local winner = entrants[math.random( #entrants )]
	winner:SWGRP_AddCredits( SWGRP.Government.LotteryPool )
	SWGRP.Notify( nil, winner:Nick() .. " won the lottery: " .. SWGRP.FormatCredits( SWGRP.Government.LotteryPool ) )

	for _, ply in ipairs( player.GetAll() ) do
		ply.SWGRP_LotteryTicket = nil
	end
	SWGRP.Government.LotteryPool = 0
	if SWGRP.Persistence then SWGRP.Persistence.SaveWorld() end
end

timer.Create( "SWGRP_Lottery", 600, 0, SWGRP.Government.RunLottery )

hook.Add( "PlayerInitialSpawn", "SWGRP_SyncGov", function( ply )
	timer.Simple( 1, function()
		if not IsValid( ply ) then return end
		SWGRP.Government.SyncLaws( ply )
		SWGRP.Government.SyncLockdown( ply )
	end )
end )

net.Receive( "SWGRP_GovernorAction", function( len, ply )
	if not ply:SWGRP_IsGovernor() then return end
	local action = net.ReadString()

	if action == "lockdown" then
		SWGRP.Government.StartLockdown( ply )
	elseif action == "endlockdown" then
		SWGRP.Government.EndLockdown()
	elseif action == "addlaw" then
		SWGRP.Government.AddLaw( net.ReadString() )
	elseif action == "removelaw" then
		SWGRP.Government.RemoveLaw( net.ReadUInt( 8 ) )
	elseif action == "resetlaws" then
		SWGRP.Government.ResetLaws()
	end
end )

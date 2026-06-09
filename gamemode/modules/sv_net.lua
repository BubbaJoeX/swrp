--[[---------------------------------------------------------------------------
    Server Network Receivers
---------------------------------------------------------------------------]]

net.Receive( "SWGRP_SetJob", function( len, ply )
	local teamId = net.ReadUInt( 16 )
	local modelIndex = net.ReadUInt( 8 )
	if teamId and SWGRP.Jobs[teamId] then
		SWGRP.JobsMgr.StartVote( ply, teamId, modelIndex )
	end
end )

net.Receive( "SWGRP_BuyEntity", function( len, ply )
	local class = net.ReadString()
	if SWGRP.Entities[class] then
		SWGRP.Economy.BuyEntity( ply, class )
	end
end )

net.Receive( "SWGRP_BuyShipment", function( len, ply )
	local id = net.ReadUInt( 8 )
	local separate = net.ReadBool()
	SWGRP.Economy.BuyShipment( ply, id, separate )
end )

net.Receive( "SWGRP_BuyAmmo", function( len, ply )
	local name = net.ReadString()
	SWGRP.Economy.BuyAmmo( ply, name )
end )

net.Receive( "SWGRP_BuyVehicle", function( len, ply )
	local id = net.ReadUInt( 8 )
	SWGRP.VehiclesMgr.Buy( ply, id )
end )

net.Receive( "SWGRP_AcceptMission", function( len, ply )
	local id = net.ReadUInt( 8 )
	SWGRP.MissionsMgr.Accept( ply, id )
end )

net.Receive( "SWGRP_CraftItem", function( len, ply )
	local recipeId = net.ReadString()
	SWGRP.Crafting.Craft( ply, recipeId )
end )

net.Receive( "SWGRP_BankAction", function( len, ply )
	local action = net.ReadString()
	local amount = net.ReadUInt( 32 )
	local target = net.ReadString()

	if action == "deposit" then
		SWGRP.Banking.Deposit( ply, amount )
	elseif action == "withdraw" then
		SWGRP.Banking.Withdraw( ply, amount )
	elseif action == "transfer" then
		SWGRP.Banking.Transfer( ply, target, amount )
	end
end )

net.Receive( "SWGRP_CastVote", function( len, ply )
	local voteType = net.ReadString()
	local target = net.ReadEntity()
	local voteYes = net.ReadBool()

	if voteType == "job" then
		local active = SWGRP.JobsMgr.ActiveVotes[target]
		if not active then return end
		if active.voters[ply] then return end
		active.voters[ply] = true
		if voteYes then active.yes = active.yes + 1 else active.no = active.no + 1 end
	elseif voteType == "demote" then
		local active = SWGRP.Demote.Active[target]
		if not active then return end
		if active.voters[ply] then return end
		active.voters[ply] = true
		if voteYes then active.yes = active.yes + 1 else active.no = active.no + 1 end
	elseif voteType == "voteban" then
		local active = SWGRP.VoteBan and SWGRP.VoteBan.Active[target]
		if not active then return end
		if active.voters[ply] then return end
		active.voters[ply] = true
		if voteYes then active.yes = active.yes + 1 else active.no = active.no + 1 end
	end
end )

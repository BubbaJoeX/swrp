--[[---------------------------------------------------------------------------
    SWGRP Network Strings
---------------------------------------------------------------------------]]

if SERVER then
	local nets = {
		"SWGRP_SyncLaws",
		"SWGRP_SyncLockdown",
		"SWGRP_OpenF4",
		"SWGRP_JobVote",
		"SWGRP_DemoteVote",
		"SWGRP_Notify",
		"SWGRP_DoorMenu",
		"SWGRP_UpdateDoor",
		"SWGRP_SyncHits",
		"SWGRP_RequestHit",
		"SWGRP_GovernorAction",
		"SWGRP_BuyEntity",
		"SWGRP_BuyShipment",
		"SWGRP_BuyAmmo",
		"SWGRP_SetJob",
		"SWGRP_BuyVehicle",
		"SWGRP_AcceptMission",
		"SWGRP_CraftItem",
		"SWGRP_BankAction",
		"SWGRP_OpenVote",
		"SWGRP_CastVote",
		"SWGRP_Lockpick",
		"SWGRP_LockpickResult",
		"SWGRP_Advert",
		"SWGRP_PocketSync",
		"SWGRP_PocketDrop",
		"SWGRP_PocketOpen",
		"SWGRP_ReloadContent",
		"SWGRP_DoorAction",
	}

	for _, name in ipairs( nets ) do
		util.AddNetworkString( name )
	end
end

function SWGRP.NetWriteNotify( msg, msgType )
	net.WriteString( msg or "" )
	net.WriteUInt( msgType or 0, 4 )
end

function SWGRP.NetReadNotify()
	return net.ReadString(), net.ReadUInt( 4 )
end

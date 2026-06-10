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
		"SWGRP_BuyFood",
		"SWGRP_CraftSpice",
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
		"SWGRP_PocketStore",
		"SWGRP_PocketSwap",
		"SWGRP_PocketRequestSync",
		"SWGRP_PocketQuickStore",
		"SWGRP_PocketOpen",
		"SWGRP_ReloadContent",
		"SWGRP_DoorAction",
		"SWGRP_AdminDoorMenu",
		"SWGRP_AdminDoorAction",
		"SWGRP_AdminButtonMenu",
		"SWGRP_AdminButtonAction",
		"SWGRP_DoorNoBuy",
		"SWGRP_AdminMenu",
		"SWGRP_AdminAction",
		"SWGRP_AdminSync",
		"SWGRP_JobSpawnMenu",
		"SWGRP_JobSpawnAction",
		"SWGRP_JobSpawnSync",
		"SWGRP_JailSpawnMenu",
		"SWGRP_JailSpawnAction",
		"SWGRP_JailSpawnSync",
		"SWGRP_MapAdjustMenu",
		"SWGRP_MapAdjustAction",
		"SWGRP_MapAdjustSync",
		"SWGRP_EntitySpawnMenu",
		"SWGRP_EntitySpawnAction",
		"SWGRP_OwnershipMenu",
		"SWGRP_OwnershipAction",
		"SWGRP_SecuritySync",
		"SWGRP_CasinoOpenMenu",
		"SWGRP_CasinoBet",
		"SWGRP_TipJarOpenMenu",
		"SWGRP_TipJarAction",
		"SWGRP_HoloSignOpenMenu",
		"SWGRP_HoloSignAction",
		"SWGRP_MountOffsetSync",
		"SWGRP_MountOffsetAction",
		"SWGRP_MountOffsetMenu",
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

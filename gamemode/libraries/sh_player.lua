--[[---------------------------------------------------------------------------
    SWGRP Player Meta Extensions
---------------------------------------------------------------------------]]

local meta = FindMetaTable( "Player" )
if not meta then return end

function meta:SWGRP_GetCredits()
	return self:GetNWInt( "SWGRP_Credits", 0 )
end

function meta:SWGRP_HasLicense()
	return self:GetNWBool( "SWGRP_License", false )
end

function meta:SWGRP_HasVehicleLicense()
	return self:GetNWBool( "SWGRP_VehicleLicense", false )
end

function meta:SWGRP_IsWanted()
	return self:GetNWBool( "SWGRP_Wanted", false )
end

function meta:SWGRP_GetWantedReason()
	return self:GetNWString( "SWGRP_WantedReason", "" )
end

function meta:SWGRP_IsArrested()
	return self:GetNWBool( "SWGRP_Arrested", false )
end

function meta:SWGRP_IsAFK()
	return self:GetNWBool( "SWGRP_AFK", false )
end

function meta:SWGRP_GetSalary()
	local job = SWGRP.GetJob( self:Team() )
	return job and job.salary or 0
end

function meta:SWGRP_GetJobName()
	local job = SWGRP.GetJob( self:Team() )
	return job and job.name or team.GetName( self:Team() )
end

function meta:SWGRP_CanAfford( amount )
	return self:SWGRP_GetCredits() >= amount
end

function meta:SWGRP_IsGovernment()
	return SWGRP.IsGovernmentJob( self:Team() )
end

function meta:SWGRP_IsGovernor()
	return SWGRP.IsGovernor( self:Team() )
end

function meta:SWGRP_IsMedic()
	return SWGRP.IsMedicJob( self:Team() )
end

function meta:SWGRP_IsBountyHunter()
	return SWGRP.IsBountyHunter( self:Team() )
end

function meta:SWGRP_GetDoorCount()
	return self.SWGRP_DoorCount or 0
end

function meta:SWGRP_GetPropCount()
	return self.SWGRP_PropCount or 0
end

function meta:SWGRP_GetBank()
	return self:GetNWInt( "SWGRP_Bank", 0 )
end

function meta:SWGRP_GetHunger()
	return self:GetNWInt( "SWGRP_Hunger", SWGRP.Config.HungerMax or 100 )
end

function meta:SWGRP_GetFaction( faction )
	return self:GetNWInt( "SWGRP_Faction_" .. faction, 0 )
end

function meta:SWGRP_GetProfLevel()
	return self:GetNWInt( "SWGRP_ProfLevel", 1 )
end

function meta:SWGRP_GetMaterial( matType )
	return self:GetNWInt( "SWGRP_Mat_" .. matType, 0 )
end

function meta:SWGRP_GetContrabandCount()
	return self:GetNWInt( "SWGRP_ContraCount", 0 )
end

function meta:SWGRP_IsRestrained()
	return self:GetNWBool( "SWGRP_Restrained", false )
end

function meta:SWGRP_GetPocketItem()
	return self:GetNWString( "SWGRP_Pocket", "" )
end

function meta:SWGRP_GetMissionName()
	return self:GetNWString( "SWGRP_Mission", "" )
end

if SERVER then
	function meta:SWGRP_SetCredits( amount )
		amount = math.max( 0, math.floor( amount ) )
		self:SetNWInt( "SWGRP_Credits", amount )
		self.SWGRP_Credits = amount
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_AddCredits( amount )
		self:SWGRP_SetCredits( self:SWGRP_GetCredits() + amount )
	end

	function meta:SWGRP_TakeCredits( amount )
		-- Guard against negative amounts, which would turn a charge into a grant.
		amount = math.floor( amount or 0 )
		if amount < 0 then return false end
		if not self:SWGRP_CanAfford( amount ) then return false end
		self:SWGRP_SetCredits( self:SWGRP_GetCredits() - amount )
		return true
	end

	function meta:SWGRP_SetLicense( state )
		self:SetNWBool( "SWGRP_License", state )
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_SetVehicleLicense( state )
		self:SetNWBool( "SWGRP_VehicleLicense", state )
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_SetWanted( reason )
		self:SetNWBool( "SWGRP_Wanted", true )
		self:SetNWString( "SWGRP_WantedReason", reason or "Unspecified offense" )
		self.SWGRP_WantedExpire = os.time() + SWGRP.Config.WantedTime
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_UnWanted()
		self:SetNWBool( "SWGRP_Wanted", false )
		self:SetNWString( "SWGRP_WantedReason", "" )
		self.SWGRP_WantedExpire = nil
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_SetArrested( state )
		self:SetNWBool( "SWGRP_Arrested", state )
		if not state then
			self.SWGRP_ArrestExpire = nil
		end
		if SWGRP.Persistence then SWGRP.Persistence.ScheduleSave( self ) end
	end

	function meta:SWGRP_SetAFK( state )
		self:SetNWBool( "SWGRP_AFK", state )
	end
end

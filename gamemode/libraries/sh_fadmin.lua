--[[---------------------------------------------------------------------------
    FAdmin integration helpers (optional — safe when FAdmin is not installed)
    Follows patterns from DarkRP + FAdmin: https://github.com/FPtje/DarkRP
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.FAdmin = SWGRP.FAdmin or {}

local FA = SWGRP.FAdmin

FA.SandboxWeapons = {
	"weapon_physgun",
	"gmod_tool",
	"weapon_physcannon",
}

function FA.Available()
	return FAdmin and FAdmin.Access and FAdmin.Access.PlayerHasPrivilege
end

function FA.HasPrivilege( ply, privilege )
	if not IsValid( ply ) then return false end

	if FA.Available() then
		local ok = FAdmin.Access.PlayerHasPrivilege( ply, privilege )
		if ok == true then return true end
	end

	if privilege == "Spawn" or privilege == "Physgun" or privilege == "Toolgun" then
		return ply:IsAdmin()
	end

	return false
end

function FA.CanSpawn( ply )
	return FA.HasPrivilege( ply, "Spawn" )
end

function FA.CanPhysgun( ply )
	if not IsValid( ply ) or ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then return false end

	local mode = SWGRP.Config and SWGRP.Config.SandboxTools and SWGRP.Config.SandboxTools:GetInt() or 1
	if mode == 0 then return false end
	if mode == 1 then return true end

	return FA.HasPrivilege( ply, "Physgun" )
end

function FA.CanToolgun( ply )
	if not IsValid( ply ) or ply:SWGRP_IsArrested() or ply:SWGRP_IsRestrained() then return false end

	local mode = SWGRP.Config and SWGRP.Config.SandboxTools and SWGRP.Config.SandboxTools:GetInt() or 1
	if mode == 0 then return false end
	if mode == 1 then return true end

	return FA.HasPrivilege( ply, "Toolgun" )
end

function FA.CanUseSandboxTools( ply )
	return FA.CanPhysgun( ply ) or FA.CanToolgun( ply )
end

function FA.ShouldGiveWeapon( ply, class )
	if class == "weapon_physgun" or class == "weapon_physcannon" then
		return FA.CanPhysgun( ply )
	end
	if class == "gmod_tool" then
		return FA.CanToolgun( ply )
	end
	return false
end

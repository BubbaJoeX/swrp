if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Disguise Kit"
SWEP.Author = "SWGRP"
SWEP.Instructions = "Left click: toggle disguise. Changes your appearance and identity."
SWEP.Category = "SWGRP"
SWEP.Spawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.Slot = 3
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.HoldType = "normal"

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
end

if SERVER then
	local DEFAULT_MODELS = {
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group02/male_05.mdl",
	}

	local DEFAULT_NAMES = {
		"Dock Worker", "Spaceport Vagrant", "Moisture Farmer", "Cargo Hauler",
		"Cantina Patron", "Trader", "Pilgrim", "Drifter",
	}

	local function disguiseModels()
		return ( SWGRP.Config and SWGRP.Config.DisguiseModels ) or DEFAULT_MODELS
	end

	local function disguiseNames()
		return ( SWGRP.Config and SWGRP.Config.DisguiseNames ) or DEFAULT_NAMES
	end

	function SWEP:PrimaryAttack()
		self:SetNextPrimaryFire( CurTime() + 1 )

		local owner = self:GetOwner()
		if not IsValid( owner ) then return end

		local job = SWGRP.GetJob( owner:Team() )
		if not ( job and job.disguise ) and not owner:IsAdmin() then
			SWGRP.Notify( owner, "Your profession cannot use a disguise kit." )
			return
		end

		if owner:GetNWBool( "SWGRP_Disguised", false ) then
			owner:SetNWBool( "SWGRP_Disguised", false )
			owner:SetNWString( "SWGRP_DisguiseName", "" )
			if owner.SWGRP_RealModel then
				owner:SetModel( owner.SWGRP_RealModel )
			end
			SWGRP.Notify( owner, "Disguise removed." )
		else
			owner.SWGRP_RealModel = owner:GetModel()
			local models = disguiseModels()
			local names = disguiseNames()
			owner:SetModel( models[math.random( #models )] )
			owner:SetNWBool( "SWGRP_Disguised", true )
			owner:SetNWString( "SWGRP_DisguiseName", names[math.random( #names )] )
			SWGRP.Notify( owner, "Disguise active. Your identity is concealed." )
			SWGRP.Log( "system", owner:Nick() .. " (" .. owner:SteamID() .. ") activated a disguise" )
		end
	end

	-- Clear disguise on death/job change so models reset cleanly.
	hook.Add( "PlayerDeath", "SWGRP_DisguiseClear", function( ply )
		if IsValid( ply ) and ply:GetNWBool( "SWGRP_Disguised", false ) then
			ply:SetNWBool( "SWGRP_Disguised", false )
			ply:SetNWString( "SWGRP_DisguiseName", "" )
		end
	end )
else
	-- Show the disguised identity instead of the real name on the target ID.
	hook.Add( "HUDDrawTargetID", "SWGRP_DisguiseTargetID", function()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end
		local tr = ply:GetEyeTrace()
		local ent = tr.Entity
		if not IsValid( ent ) or not ent:IsPlayer() then return end
		if not ent:GetNWBool( "SWGRP_Disguised", false ) then return end

		local name = ent:GetNWString( "SWGRP_DisguiseName", "Unknown" )
		local scrW, scrH = ScrW(), ScrH()
		draw.SimpleTextOutlined( name, "TargetID", scrW / 2, scrH / 2 + 40,
			Color( 220, 220, 220 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color( 0, 0, 0, 200 ) )
		return true
	end )
end

function SWEP:SecondaryAttack()
end

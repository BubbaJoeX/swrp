AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Junk Pile"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.FallbackModel = "models/props_junk/garbage_bag_01a.mdl"
ENT.ScavengeSound = "physics/metal/metal_box_impact_soft2.wav"
ENT.WeaponFoundSound = "items/ammo_pickup.wav"

local function modelOk( mdl )
	return mdl and mdl ~= "" and util.IsValidModel( mdl )
end

if SERVER then
	function ENT:Initialize()
		local mdl = self.SWGRP_PendingModel or self.FallbackModel
		if not modelOk( mdl ) then mdl = self.FallbackModel end

		self:SetModel( mdl )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			if not self.SWGRP_SkyDrop then
				phys:EnableMotion( false )
			else
				self:NextThink( CurTime() + 0.25 )
			end
		end
	end

	function ENT:Think()
		if not self.SWGRP_SkyDrop then return end

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) and phys:GetVelocity():Length() < 24 then
			phys:EnableMotion( false )
			self.SWGRP_SkyDrop = false
			return
		end

		self:NextThink( CurTime() + 0.25 )
		return true
	end

	function ENT:SetJunkModel( mdl )
		self.SWGRP_PendingModel = mdl
		if self:EntIndex() > 0 and modelOk( mdl ) then
			self:SetModel( mdl )
			self:PhysicsInit( SOLID_VPHYSICS )
			local phys = self:GetPhysicsObject()
			if IsValid( phys ) then
				phys:Wake()
				if not self.SWGRP_SkyDrop then
					phys:EnableMotion( false )
				else
					self:NextThink( CurTime() + 0.25 )
				end
			end
		end
	end

	function ENT:GetPlayerCooldown()
		local cv = SWGRP.Config.JunkPilePlayerCooldown
		return cv and cv:GetInt() or 30
	end

	function ENT:AwardCredits( ply, minCr, maxCr )
		local amount = math.random( minCr, maxCr )
		ply:SWGRP_AddCredits( amount )
		SWGRP.Notify( ply, "Scavenged " .. SWGRP.FormatCredits( amount ) .. " from the junk pile." )
		return amount
	end

	function ENT:TryAwardWeapon( ply )
		local cv = SWGRP.Config.JunkPileWeaponClass
		local class = ( cv and cv:GetString() ) or "weapon_752_se14c"
		if class == "" then class = "weapon_752_se14c" end

		if ply:HasWeapon( class ) then
			return false
		end

		if not SWGRP.GrantWeapon( ply, class ) then
			return false
		end

		self:EmitSound( self.WeaponFoundSound, 70, 100, 0.9 )
		SWGRP.Notify( ply, "You salvaged a SE-14C blaster from the scrap!" )
		if SWGRP.Log then
			SWGRP.Log( "economy", ply:Nick() .. " scavenged " .. class .. " from a junk pile" )
		end
		return true
	end

	function ENT:TryAwardFood( ply, dropPos )
		if not SWGRP.Foods or #SWGRP.Foods == 0 then return false end
		if not SWGRP.Economy or not SWGRP.Economy.SpawnFoodPickup then return false end

		local foodId = math.random( #SWGRP.Foods )
		local spawnPos = dropPos + Vector( math.random( -24, 24 ), math.random( -24, 24 ), 12 )
		local ent = SWGRP.Economy.SpawnFoodPickup( ply, foodId, spawnPos, Angle( 0, math.random( 0, 359 ), 0 ) )
		if not IsValid( ent ) then return false end

		local food = SWGRP.Foods[foodId]
		SWGRP.Notify( ply, "You found " .. ( food and food.name or "food" ) .. " — press E to eat it." )
		if SWGRP.Log then
			SWGRP.Log( "economy", ply:Nick() .. " scavenged food '" .. ( food and food.name or foodId ) .. "' from a junk pile" )
		end
		return true
	end

	function ENT:DropReplacement( dropPos, dropAng )
		if SWGRP.JunkPiles and SWGRP.JunkPiles.DropFromSky then
			SWGRP.JunkPiles.DropFromSky( dropPos, dropAng )
		end
	end

	function ENT:Scavenge( ply )
		if not IsValid( ply ) or not ply:IsPlayer() then return end

		if not ply:SWGRP_IsRefugee() then
			SWGRP.Notify( ply, "Only refugees can scavenge junk piles." )
			return
		end

		local now = CurTime()
		if ply.SWGRP_JunkPileNextScavenge and ply.SWGRP_JunkPileNextScavenge > now then
			SWGRP.Notify( ply, "You need to wait before scavenging junk again." )
			return
		end

		local dropPos = self:GetPos()
		local dropAng = self:GetAngles()

		ply.SWGRP_JunkPileNextScavenge = now + self:GetPlayerCooldown()

		local chanceCv = SWGRP.Config.JunkPileWeaponChance
		local weaponChance = chanceCv and chanceCv:GetFloat() or 0.06
		local foodChanceCv = SWGRP.Config.JunkPileFoodChance
		local foodChance = foodChanceCv and foodChanceCv:GetFloat() or 0.12
		local minCv = SWGRP.Config.JunkPileCreditMin
		local maxCv = SWGRP.Config.JunkPileCreditMax
		local minCr = minCv and minCv:GetInt() or 10
		local maxCr = maxCv and maxCv:GetInt() or 100

		local roll = math.random()
		local rewarded = false

		if roll < weaponChance then
			rewarded = self:TryAwardWeapon( ply )
		elseif roll < weaponChance + foodChance then
			rewarded = self:TryAwardFood( ply, dropPos )
		end

		if not rewarded then
			local credits = self:AwardCredits( ply, minCr, maxCr )
			if SWGRP.Log then
				SWGRP.Log( "economy", ply:Nick() .. " scavenged " .. SWGRP.FormatCredits( credits ) .. " from a junk pile" )
			end
		end

		self:EmitSound( self.ScavengeSound, 65, math.random( 95, 105 ), 0.8 )

		self:Remove()
		self:DropReplacement( dropPos, dropAng )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.5

		self:Scavenge( activator )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local subtitle = "Refugees: Press E to scavenge"

		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "JUNK PILE", subtitle, SWGRP.UI.Colors.secondary )
		end
	end
end

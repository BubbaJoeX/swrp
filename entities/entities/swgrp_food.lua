AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Food"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.FallbackModel = "models/props_junk/garbage_bag_01a.mdl"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "FoodID" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.FallbackModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:SetFood( id )
		local food = SWGRP.Foods and SWGRP.Foods[id]
		if not food then return end

		self:SetFoodID( id )

		if food.model and food.model ~= "" then
			self:SetModel( food.model )
			self:PhysicsInit( SOLID_VPHYSICS )
			if not IsValid( self:GetPhysicsObject() ) then
				self:SetModel( self.FallbackModel )
				self:PhysicsInit( SOLID_VPHYSICS )
			end
			self:SetSolid( SOLID_VPHYSICS )
			self:SetMoveType( MOVETYPE_VPHYSICS )
			local phys = self:GetPhysicsObject()
			if IsValid( phys ) then phys:Wake() end
		end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		local food = SWGRP.Foods and SWGRP.Foods[self:GetFoodID()]
		if not food then self:Remove() return end

		if SWGRP.Hunger and ( food.hunger or 0 ) ~= 0 then
			SWGRP.Hunger.Add( activator, food.hunger )
		end
		if ( food.health or 0 ) ~= 0 then
			activator:SetHealth( math.Clamp( activator:Health() + food.health, 1, activator:GetMaxHealth() ) )
		end

		activator:EmitSound( "npc/barnacle/barnacle gulp2.wav", 60, math.random( 90, 110 ) )
		SWGRP.Notify( activator, "You ate " .. ( food.name or "food" ) .. "." )
		SWGRP.Hooks.Call( "SWGRPFoodConsumed", activator, food.name )
		self:Remove()
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local food = SWGRP.Foods and SWGRP.Foods[self:GetFoodID()]
		if not food then return end

		local pos = self:GetPos() + Vector( 0, 0, self:OBBMaxs().z + 6 )
		local dist = LocalPlayer():EyePos():Distance( pos )
		if dist > 300 then return end
		local alpha = math.Clamp( ( 300 - dist ) / 120, 0, 1 ) * 255

		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )

		cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.08 )
			draw.SimpleText( food.name, "DermaDefaultBold", 0, 0, Color( 255, 200, 80, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Press E to eat", "DermaDefault", 0, 16, Color( 220, 220, 220, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

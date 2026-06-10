AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spice"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- Used until a spice definition is applied (and if a spice's model isn't
-- mounted on this server).
ENT.FallbackModel = "models/props_junk/cardboard_box004a.mdl"

-- The networked SpiceID indexes SWGRP.Spices (shared), so both realms can look
-- up the name / effects / model without sending them per entity.
function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "SpiceID" )
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

	-- Apply a spice definition after the entity is created. Swaps to the spice's
	-- model, falling back to the default if that model isn't mounted so the
	-- pickup can't become an invisible, collisionless prop at the world origin.
	function ENT:SetSpice( id )
		local spice = SWGRP.Spices and SWGRP.Spices[id]
		if not spice then return end

		self:SetSpiceID( id )

		if spice.model and spice.model ~= "" then
			self:SetModel( spice.model )
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

		local spice = SWGRP.Spices and SWGRP.Spices[self:GetSpiceID()]
		if not spice then self:Remove() return end

		-- Hunger / health deltas can be negative; these are narcotics. Health is
		-- clamped to a minimum of 1 so a hit never outright kills the user.
		if SWGRP.Hunger and ( spice.hunger or 0 ) ~= 0 then
			SWGRP.Hunger.Add( activator, spice.hunger )
		end
		if ( spice.health or 0 ) ~= 0 then
			activator:SetHealth( math.Clamp( activator:Health() + spice.health, 1, activator:GetMaxHealth() ) )
		end

		activator:EmitSound( "npc/barnacle/barnacle gulp2.wav", 60, math.random( 90, 110 ) )
		SWGRP.Notify( activator, "You consumed " .. ( spice.name or "spice" ) .. "." )
		SWGRP.Hooks.Call( "SWGRPSpiceConsumed", activator, spice.name )
		self:Remove()
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local spice = SWGRP.Spices and SWGRP.Spices[self:GetSpiceID()]
		if not spice then return end

		local pos = self:GetPos() + Vector( 0, 0, self:OBBMaxs().z + 6 )
		local dist = LocalPlayer():EyePos():Distance( pos )
		if dist > 300 then return end
		local alpha = math.Clamp( ( 300 - dist ) / 120, 0, 1 ) * 255

		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )

		cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.08 )
			draw.SimpleText( spice.name, "DermaDefaultBold", 0, 0, Color( 200, 120, 255, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Press E to consume", "DermaDefault", 0, 16, Color( 220, 220, 220, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
end

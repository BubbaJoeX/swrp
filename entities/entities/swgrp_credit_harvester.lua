AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Credit Press"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- Built-in model; entities.csv overrides this via BuyEntity. Kept in sync with
-- the galactic credit prop so toolgun / direct spawns look right too.
ENT.DefaultModel  = "models/props/starwars/weapons/hoth_bomb.mdl"
ENT.FallbackModel = "models/props/starwars/weapons/hoth_bomb.mdl"

-- Money-printer tuning. The harvester slowly "prints" credits; once it has
-- enough banked it ejects a physical money pile beside itself that anyone can
-- grab, and the owner can press E to pocket whatever is still banked. Printing
-- builds heat, and an overheated printer pauses until it cools back down.
ENT.PrintInterval = 8     -- seconds between production ticks
ENT.PrintMin      = 60    -- credits produced per tick (min)
ENT.PrintMax      = 110   -- credits produced per tick (max)
ENT.EjectAt       = 500   -- bank this much, then spit out a money pile
ENT.MaxPiles      = 6     -- printed piles allowed nearby before it pauses
ENT.PileRadius    = 96    -- how far to count piles as "nearby"
ENT.HeatPerTick   = 10    -- heat gained per production tick
ENT.CoolPerTick   = 18    -- heat shed per tick while idle / overheated
ENT.OverheatAt    = 100   -- pause production at/above this heat
ENT.CoolResume    = 45    -- resume once heat drops back to this

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "StoredCredits" )
	self:NetworkVar( "Int", 1, "Heat" )
	self:NetworkVar( "Bool", 0, "Overheated" )
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )

		-- Guard against the galactic credit prop not being mounted; an entity
		-- with no physics mesh snaps to the world origin instead of where it was
		-- placed, so fall back to a guaranteed Star Wars prop.
		if not IsValid( self:GetPhysicsObject() ) then
			self:SetModel( self.FallbackModel )
			self:PhysicsInit( SOLID_VPHYSICS )
		end

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetStoredCredits( 0 )
		self:SetHeat( 0 )
		self:SetOverheated( false )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end

		timer.Create( "SWGRP_Harvester_" .. self:EntIndex(), self.PrintInterval, 0, function()
			if IsValid( self ) then self:Tick() end
		end )
	end

	-- Count printed money piles still sitting next to the harvester so it pauses
	-- instead of burying the area in piles nobody has collected.
	function ENT:NearbyPiles()
		local n = 0
		for _, e in ipairs( ents.FindInSphere( self:GetPos(), self.PileRadius ) ) do
			if e:GetClass() == "swgrp_dropped_credits" then n = n + 1 end
		end
		return n
	end

	function ENT:EjectPile( amount )
		local pile = ents.Create( "swgrp_dropped_credits" )
		if not IsValid( pile ) then return end

		local ang = math.random( 0, 360 )
		local offset = Vector( math.cos( ang ) * 16, math.sin( ang ) * 16, 24 )
		pile:SetPos( self:GetPos() + offset )
		pile:SetCredits( amount )
		pile:Spawn()
		pile.SWGRP_DroppedBy = self.SWGRP_Owner

		local phys = pile:GetPhysicsObject()
		if IsValid( phys ) then
			phys:Wake()
			phys:SetVelocity( Vector( 0, 0, 90 ) )
		end

		self:EmitSound( "ambient/levels/labs/coinslot1.wav", 60 )
	end

	function ENT:Tick()
		-- Cooling always runs; production only when not overheated.
		if self:GetOverheated() then
			local heat = math.max( 0, self:GetHeat() - self.CoolPerTick )
			self:SetHeat( heat )
			if heat <= self.CoolResume then self:SetOverheated( false ) end
			return
		end

		-- Don't print while a stack of uncollected piles is sitting next to us;
		-- bleed off heat instead so it stays ready to resume.
		if self:NearbyPiles() >= self.MaxPiles then
			self:SetHeat( math.max( 0, self:GetHeat() - self.CoolPerTick ) )
			return
		end

		self:SetStoredCredits( self:GetStoredCredits() + math.random( self.PrintMin, self.PrintMax ) )

		local heat = self:GetHeat() + self.HeatPerTick
		self:SetHeat( heat )
		if heat >= self.OverheatAt then
			self:SetOverheated( true )
			self:EmitSound( "ambient/energy/spark6.wav", 65 )
		end

		while self:GetStoredCredits() >= self.EjectAt do
			self:SetStoredCredits( self:GetStoredCredits() - self.EjectAt )
			self:EjectPile( self.EjectAt )
		end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if self.SWGRP_Owner and self.SWGRP_Owner ~= activator then
			SWGRP.Notify( activator, "This credit harvester isn't yours." )
			return
		end

		if IsValid( self.SWGRP_MountCase ) then
			local total, presses = self.SWGRP_MountCase:CollectAllMounted( activator )
			if total > 0 then
				SWGRP.Notify( activator, string.format(
					"Collected %s from %d mounted press(es).",
					SWGRP.FormatCredits( total ),
					presses
				) )
			else
				SWGRP.Notify( activator, "Nothing banked on mounted presses yet." )
			end
			return
		end

		local stored = self:GetStoredCredits()
		if stored <= 0 then
			SWGRP.Notify( activator, "Nothing banked yet. The harvester is still printing." )
			return
		end

		activator:SWGRP_AddCredits( stored )
		self:SetStoredCredits( 0 )
		SWGRP.Notify( activator, "Collected " .. SWGRP.FormatCredits( stored ) .. " from the harvester." )
	end

	function ENT:OnRemove()
		timer.Remove( "SWGRP_Harvester_" .. self:EntIndex() )

		local case = self.SWGRP_MountCase
		local slot = self.SWGRP_MountSlot
		if IsValid( case ) and slot and case.SWGRP_MountedPresses then
			case.SWGRP_MountedPresses[slot] = nil
			case:SyncMountedCount()
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local pos = self:GetPos() + Vector( 0, 0, 24 )
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis( ang:Forward(), 90 )
		ang:RotateAroundAxis( ang:Right(), 90 )

		cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.1 )
			draw.SimpleText( SWGRP.FormatCredits( self:GetStoredCredits() ), "DermaDefaultBold", 0, -14, SWGRP.Config.HUDColorPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			-- Heat bar so owners can see how close it is to overheating.
			local bw, bh = 80, 8
			local frac = math.Clamp( self:GetHeat() / ( self.OverheatAt or 100 ), 0, 1 )
			surface.SetDrawColor( 0, 0, 0, 200 )
			surface.DrawRect( -bw / 2, 4, bw, bh )
			local hot = self:GetOverheated()
			surface.SetDrawColor( hot and 220 or 90, hot and 60 or 180, 60, 230 )
			surface.DrawRect( -bw / 2 + 1, 5, ( bw - 2 ) * frac, bh - 2 )

			if hot then
				draw.SimpleText( "OVERHEATED", "DermaDefault", 0, 20, Color( 230, 80, 80 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		cam.End3D2D()
	end
end

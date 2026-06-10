AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Spice Storage Terminal"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- entities.csv overrides this via BuyEntity; kept as the safe built-in default.
ENT.DefaultModel = "models/props/starwars/vehicles/bd_dispenser.mdl"

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		-- Light cooldown so a held use key doesn't reopen the menu every tick.
		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.75

		activator:SendLua( "SWGRP.OpenSpiceMenu()" )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "SPICE STORAGE", "Press E to craft", Color( 200, 120, 255 ) )
		end
	end

	function SWGRP.OpenSpiceMenu()
		local UI = SWGRP.UI
		if not UI or not UI.CreateTerminalFrame then return end

		if IsValid( SWGRP.SpiceFrame ) then
			SWGRP.SpiceFrame:Remove()
			SWGRP.SpiceFrame = nil
			return
		end

		UI.SyncColors()

		local frame = UI.CreateTerminalFrame( "SPICE STORAGE TERMINAL", math.min( ScrW() * 0.55, 900 ), math.min( ScrH() * 0.65, 640 ) )
		SWGRP.SpiceFrame = frame

		local body = vgui.Create( "DPanel", frame )
		body:Dock( FILL )
		body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
		body.Paint = function() end

		local catalog = UI.CreateCatalog( body )

		if #SWGRP.Spices == 0 then
			catalog.title:SetText( "No spice available" )
			catalog.desc:SetText( "This terminal has no recipes configured (spices.csv is empty)." )
			return
		end

		for id, spice in ipairs( SWGRP.Spices ) do
			local effects = {}
			if ( spice.hunger or 0 ) ~= 0 then
				table.insert( effects, ( spice.hunger > 0 and "+" or "" ) .. spice.hunger .. " hunger" )
			end
			if ( spice.health or 0 ) ~= 0 then
				table.insert( effects, ( spice.health > 0 and "+" or "" ) .. spice.health .. " HP" )
			end
			local effectText = #effects > 0 and table.concat( effects, ", " ) or "No effect"

			catalog:AddItem( {
				name        = spice.name,
				subtitle    = spice.category or "Spice",
				listSub     = SWGRP.FormatCredits( spice.price ),
				description = "Effects when consumed: " .. effectText .. ".\nCrafted as a physical item that drops in front of you.",
				priceText   = "Craft cost: " .. SWGRP.FormatCredits( spice.price ),
				model       = spice.model,
				color       = Color( 200, 120, 255 ),
				actionText  = "Craft",
				onAction    = function()
					net.Start( "SWGRP_CraftSpice" )
						net.WriteUInt( id, 8 )
					net.SendToServer()
				end,
			} )
		end

		catalog:AutoSelectFirst()
	end
end

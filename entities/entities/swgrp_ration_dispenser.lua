AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ration Terminal"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- Model the data file (entities.csv) overrides via BuyEntity; this is the safe
-- built-in default used if that model isn't mounted on a given server.
ENT.DefaultModel = "models/bananakin/rp_daedalus_v1/cantina_console.mdl"

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

		activator:SendLua( "SWGRP.OpenRationMenu()" )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "RATION TERMINAL", "Press E to buy food", SWGRP.UI.Colors.accent )
		end
	end

	function SWGRP.OpenRationMenu()
		local UI = SWGRP.UI
		if not UI or not UI.CreateTerminalFrame then return end

		if IsValid( SWGRP.RationFrame ) then
			SWGRP.RationFrame:Remove()
			SWGRP.RationFrame = nil
			return
		end

		UI.SyncColors()

		local frame = UI.CreateTerminalFrame( "RATION TERMINAL", math.min( ScrW() * 0.55, 900 ), math.min( ScrH() * 0.65, 640 ) )
		SWGRP.RationFrame = frame

		local body = vgui.Create( "DPanel", frame )
		body:Dock( FILL )
		body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
		body.Paint = function() end

		local catalog = UI.CreateCatalog( body )

		if #SWGRP.Foods == 0 then
			catalog.title:SetText( "No rations available" )
			catalog.desc:SetText( "This terminal has no items configured (foods.csv is empty)." )
			return
		end

		for id, food in ipairs( SWGRP.Foods ) do
			local restore = "Restores " .. ( food.hunger or 0 ) .. " hunger"
			if ( food.health or 0 ) > 0 then
				restore = restore .. " and heals " .. food.health .. " HP"
			end

			catalog:AddItem( {
				name        = food.name,
				subtitle    = food.category or "Rations",
				listSub     = SWGRP.FormatCredits( food.price ),
				description = restore .. ".\nConsumed immediately on purchase.",
				priceText   = "Cost: " .. SWGRP.FormatCredits( food.price ),
				model       = food.model,
				color       = UI.Colors.accent,
				actionText  = "Purchase",
				onAction    = function()
					net.Start( "SWGRP_BuyFood" )
						net.WriteUInt( id, 8 )
					net.SendToServer()
				end,
			} )
		end

		catalog:AutoSelectFirst()
	end
end

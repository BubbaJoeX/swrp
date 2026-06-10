AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Weapon Shipment"
ENT.Category = "SWGRP"
ENT.Spawnable = false

-- All shipments share the same cargo crate look regardless of the model field
-- in shipments.csv. A safe fallback keeps physics/collision sane if the SW
-- content pack that ships this model isn't mounted on a given server.
ENT.CrateModel = "models/starwars/bandit/3rd_cargo_box.mdl"
ENT.FallbackModel = "models/Items/item_item_crate.mdl"

-- Spinning weapon preview hovering above the crate so players can tell at a
-- glance what's inside. Purely cosmetic / clientside.
ENT.PreviewSpinSpeed = 80   -- degrees per second
ENT.PreviewScale     = 0.55 -- shrink world models so they don't dwarf the crate
ENT.PreviewHover     = 12   -- units above the crate's top
ENT.PreviewBob       = 2    -- vertical bob amplitude

util.PrecacheModel( "models/starwars/bandit/3rd_cargo_box.mdl" )
util.PrecacheModel( "models/Items/item_item_crate.mdl" )

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Remaining" )
	self:NetworkVar( "String", 0, "WeaponClass" )
	self:NetworkVar( "String", 1, "ShipmentName" )
end

function ENT:GetCrateModel()
	local mdl = self.CrateModel
	if CLIENT and not util.IsValidModel( mdl ) then
		return self.FallbackModel
	end
	return mdl
end

if SERVER then
	function ENT:SetShipmentData( data, separate )
		self.SWGRP_ShipmentData = data
		self.SWGRP_Separate = separate
		self:SetRemaining( separate and 1 or data.amount )
		self:SetWeaponClass( data.entities[1] or "" )
		self:SetShipmentName( data.name or "" )
	end

	function ENT:Initialize()
		self:SetModel( self.CrateModel )
		self:PhysicsInit( SOLID_VPHYSICS )

		-- util.IsValidModel can report true for a model that was precached but is
		-- not actually mounted on this server (e.g. the SW cargo prop pack is
		-- missing). That yields an invisible error model with no collision mesh,
		-- and a MOVETYPE_VPHYSICS entity with no physics object snaps to the world
		-- origin instead of spawning in front of the buyer. Verify we got real
		-- physics and fall back to the always-present HL2 crate if not.
		if not IsValid( self:GetPhysicsObject() ) then
			self:SetModel( self.FallbackModel )
			self:PhysicsInit( SOLID_VPHYSICS )
		end

		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		if self:GetRemaining() <= 0 then
			SWGRP.Notify( activator, "This shipment crate is empty." )
			return
		end

		local class = self:GetWeaponClass()
		if class == "" then
			SWGRP.Notify( activator, "This shipment crate has no contents configured." )
			return
		end

		activator:Give( class )
		self:SetRemaining( self:GetRemaining() - 1 )

		local remaining = self:GetRemaining()
		if remaining > 0 then
			SWGRP.Notify( activator, string.format( "Took %s from the crate. %d remaining.", self:GetShipmentName() ~= "" and self:GetShipmentName() or class, remaining ) )
		else
			SWGRP.Notify( activator, string.format( "Took the last %s. Crate emptied.", self:GetShipmentName() ~= "" and self:GetShipmentName() or class ) )
			self:Remove()
		end
	end
end

if CLIENT then
	local function LabelColors()
		local UI = SWGRP and SWGRP.UI
		local c = UI and UI.Colors
		if UI and UI.SyncColors then UI.SyncColors() end
		return {
			primary   = c and c.primary   or Color( 255, 180, 50 ),
			secondary = c and c.secondary or Color( 200, 200, 200 ),
			accent    = c and c.accent    or Color( 80, 200, 255 ),
			bg        = c and c.bg        or Color( 10, 15, 25 ),
			border    = c and c.border    or Color( 255, 180, 50, 200 ),
		}
	end

	-- Weapon shipments are identified by the weapon entity's own name (the SWEP
	-- PrintName) rather than the configured shipment spawn name. Fall back to the
	-- raw class, then to the shipment's configured name if the SWEP is unknown.
	function ENT:GetDisplayName()
		local class = self:GetWeaponClass()
		if class ~= "" then
			local swep = weapons.Get( class )
			if swep and swep.PrintName and swep.PrintName ~= "" then
				return swep.PrintName
			end
			return class
		end

		local name = self:GetShipmentName()
		if name and name ~= "" then return name end
		return "Shipment"
	end

	-- Resolve the world model for the shipment's weapon and (re)build a hidden
	-- clientside model we can render ourselves. Rebuilt only when the networked
	-- weapon class changes so we aren't churning entities every frame.
	function ENT:GetPreviewModel()
		local class = self:GetWeaponClass()

		if class == "" then
			if IsValid( self.PreviewModel ) then self.PreviewModel:Remove() end
			self.PreviewModel = nil
			self.PreviewClass = nil
			return nil
		end

		if self.PreviewClass == class then
			return IsValid( self.PreviewModel ) and self.PreviewModel or nil
		end

		if IsValid( self.PreviewModel ) then self.PreviewModel:Remove() end
		self.PreviewModel = nil
		self.PreviewClass = class

		local swep = weapons.Get( class )
		local wm = swep and swep.WorldModel
		if not wm or wm == "" or not util.IsValidModel( wm ) then
			return nil
		end

		local mdl = ClientsideModel( wm, RENDERGROUP_OPAQUE )
		if IsValid( mdl ) then
			mdl:SetNoDraw( true )
			self.PreviewModel = mdl
		end

		return self.PreviewModel
	end

	-- Draw the weapon spinning in place above the crate. Spinning around the
	-- model's OBB center keeps it pivoting cleanly instead of orbiting its
	-- (often off-center) origin.
	local function DrawWeaponPreview( ent )
		local mdl = ent:GetPreviewModel()
		if not IsValid( mdl ) then return end

		local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
		local _, rmaxs = ent:GetRenderBounds()
		local topZ = math.max( maxs.z, rmaxs.z )
		local top = ent:LocalToWorld( Vector(
			( mins.x + maxs.x ) * 0.5,
			( mins.y + maxs.y ) * 0.5,
			topZ
		) )

		local scale = ent.PreviewScale
		local bob = math.sin( CurTime() * 2 ) * ent.PreviewBob
		local target = top + Vector( 0, 0, ent.PreviewHover + bob )

		local ang = Angle( 0, ( CurTime() * ent.PreviewSpinSpeed ) % 360, 0 )

		-- Place the origin so the (scaled, rotated) OBB center lands on target.
		local offset = mdl:OBBCenter() * scale
		offset:Rotate( ang )

		mdl:SetModelScale( scale )
		mdl:SetPos( target - offset )
		mdl:SetAngles( ang )
		mdl:SetupBones()
		mdl:DrawModel()
	end

	function ENT:OnRemove()
		if IsValid( self.PreviewModel ) then self.PreviewModel:Remove() end
		self.PreviewModel = nil
	end

	local DRAW_MAX  = 600
	local DRAW_FADE = 350

	local function DrawLabel( ent, alpha )
		local colors = LabelColors()

		local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
		local _, rmaxs = ent:GetRenderBounds()
		local topZ = math.max( maxs.z, rmaxs.z )
		local center = ent:LocalToWorld( Vector(
			( mins.x + maxs.x ) * 0.5,
			( mins.y + maxs.y ) * 0.5,
			topZ
		) )

		local pos = center + Vector( 0, 0, 8 )

		-- Yaw-billboard: the plate normal points horizontally toward the viewer,
		-- mirroring the door-plate angle construction so the text stays upright.
		local dir = EyePos() - pos
		dir.z = 0
		if dir:LengthSqr() < 0.01 then return end
		local yaw = dir:Angle().y

		local drawAng = Angle( 0, yaw, 90 )
		drawAng:RotateAroundAxis( drawAng:Right(), 90 )

		local name = ent:GetDisplayName()
		local remaining = ent:GetRemaining()

		surface.SetFont( "DermaDefaultBold" )
		local tw = surface.GetTextSize( name )
		local w = math.max( tw + 40, 160 )
		local h = 56

		local scale = 0.12

		cam.Start3D2D( pos, drawAng, scale )
			surface.SetDrawColor( colors.bg.r, colors.bg.g, colors.bg.b, math.min( 220, alpha ) )
			surface.DrawRect( -w / 2, -h, w, h )

			surface.SetDrawColor( colors.border.r, colors.border.g, colors.border.b, alpha )
			surface.DrawOutlinedRect( -w / 2, -h, w, h, 2 )

			surface.SetDrawColor( colors.primary.r, colors.primary.g, colors.primary.b, math.min( 40, alpha ) )
			surface.DrawRect( -w / 2, -h, w, 22 )

			local UI = SWGRP and SWGRP.UI
			local label = UI and UI.TruncateText and UI.TruncateText( name, "DermaDefaultBold", w - 16 ) or name
			draw.SimpleText( label, "DermaDefaultBold", 0, -h + 11, ColorAlpha( colors.primary, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( "SHIPMENT", "DermaDefault", 0, -h + 30, ColorAlpha( colors.accent, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			if remaining and remaining > 0 then
				draw.SimpleText( "Remaining: " .. remaining, "DermaDefault", 0, -h + 46, ColorAlpha( colors.secondary, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		cam.End3D2D()
	end

	function ENT:Draw()
		self:DrawModel()

		local dist = self:GetPos():Distance( EyePos() )
		if dist > DRAW_MAX then return end

		DrawWeaponPreview( self )

		local alpha = 255
		if dist > DRAW_FADE then
			alpha = math.floor( 255 * ( 1 - ( dist - DRAW_FADE ) / ( DRAW_MAX - DRAW_FADE ) ) )
		end
		if alpha <= 0 then return end

		DrawLabel( self, alpha )
	end
end

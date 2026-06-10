AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Holo Sign"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/squiddy/hologram_01.mdl"
ENT.ModelScale = 1.7
ENT.MaxSignLength = 64
ENT.TextCamScale = 0.17
ENT.TextLineHeight = 14
ENT.TextCharsPerLine = 18

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "SignText" )
end

function ENT:CanPlayerEdit( ply )
	if not IsValid( ply ) or not ply:IsPlayer() then return false end
	if ply:IsAdmin() then return true end
	if self.SWGRP_Owner == ply then return true end
	if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, self ) then return true end
	return false
end

local function WrapSignText( text, maxCharsPerLine )
	maxCharsPerLine = maxCharsPerLine or 18
	local words = string.Explode( " ", text or "" )
	local lines = {}
	local line = ""

	for _, word in ipairs( words ) do
		if line == "" then
			line = word
		elseif #line + 1 + #word <= maxCharsPerLine then
			line = line .. " " .. word
		else
			table.insert( lines, line )
			line = word
		end
	end

	if line ~= "" then
		table.insert( lines, line )
	end

	if #lines == 0 then
		lines[1] = ""
	end

	return lines
end

if SERVER then
	local function IsPropEntity( ent )
		if not IsValid( ent ) then return false end
		return ent:GetClass():find( "^prop_" ) ~= nil
	end

	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetSignText( "Advertise here" )
		self:SetModelScale( self.ModelScale )

		-- World brushes only: no blocking players, props, or other ents.
		self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		self:SetCustomCollisionCheck( true )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			phys:SetCollisionGroup( COLLISION_GROUP_WEAPON )
			phys:Wake()
		end
	end

	hook.Add( "ShouldCollide", "SWGRP_HoloSign", function( entA, entB )
		if not IsValid( entA ) or not IsValid( entB ) then return end

		local sign, other
		if entA:GetClass() == "swgrp_holo_sign" then
			sign, other = entA, entB
		elseif entB:GetClass() == "swgrp_holo_sign" then
			sign, other = entB, entA
		else
			return
		end

		if IsPropEntity( other ) then return false end
	end )

	function ENT:SetSignMessage( ply, text )
		if not self:CanPlayerEdit( ply ) then
			SWGRP.Notify( ply, "You don't own this holo sign." )
			return false
		end

		text = string.Trim( text or "" )
		if text == "" then
			SWGRP.Notify( ply, "Sign text can't be empty." )
			return false
		end

		text = string.sub( text, 1, self.MaxSignLength )
		self:SetSignText( text )
		SWGRP.Notify( ply, "Sign updated." )
		return true
	end

	function ENT:OpenMenu( activator )
		net.Start( "SWGRP_HoloSignOpenMenu" )
			net.WriteEntity( self )
			net.WriteString( self:GetSignText() )
		net.Send( activator )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if not self:CanPlayerEdit( activator ) then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.4

		self:OpenMenu( activator )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()

		local text = self.GetSignText and self:GetSignText() or ""
		if text == "" then return end

		local pos = self:LocalToWorld( self:OBBCenter() )
		local ang = self:GetAngles()
		ang:RotateAroundAxis( ang:Up(), 90 )
		ang:RotateAroundAxis( ang:Forward(), 90 )

		local lines = WrapSignText( text, self.TextCharsPerLine )
		local lineHeight = self.TextLineHeight
		local totalHeight = #lines * lineHeight

		cam.Start3D2D( pos, ang, self.TextCamScale )
			for i, line in ipairs( lines ) do
				local y = ( i - 1 ) * lineHeight - totalHeight / 2 + lineHeight / 2
				draw.SimpleText(
					line,
					"DermaDefaultBold",
					0,
					y,
					SWGRP.Config.HUDColorPrimary,
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_CENTER
				)
			end
		cam.End3D2D()
	end

	function SWGRP.OpenHoloSignMenu( ent, currentText )
		local UI = SWGRP.UI
		if not UI or not UI.CreateTerminalFrame then return end

		if IsValid( SWGRP.HoloSignFrame ) then SWGRP.HoloSignFrame:Remove() end

		local frame = UI.CreateTerminalFrame( "HOLO SIGN", 340, 200 )
		SWGRP.HoloSignFrame = frame

		local body = vgui.Create( "DPanel", frame )
		body:Dock( FILL )
		body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
		body.Paint = function() end

		UI.CreateLabel( body, "Sign message (max " .. ent.MaxSignLength .. " chars)", "DermaDefault", UI.Colors.secondary, TOP )

		local entry = vgui.Create( "DTextEntry", body )
		entry:Dock( TOP )
		entry:DockMargin( 0, UI.Spacing.gap, 0, UI.Spacing.gap )
		entry:SetTall( UI.Spacing.input )
		entry:SetText( currentText or "" )
		entry:SetUpdateOnType( true )

		entry.OnValueChange = function( self, val )
			if #val > ent.MaxSignLength then
				self:SetText( string.sub( val, 1, ent.MaxSignLength ) )
				self:SetCaretPos( ent.MaxSignLength )
			end
		end

		local updateBtn = UI.CreateButton( body, "UPDATE SIGN", function()
			net.Start( "SWGRP_HoloSignAction" )
				net.WriteEntity( ent )
				net.WriteString( entry:GetValue() )
			net.SendToServer()
			frame:Close()
		end )
		if IsValid( updateBtn ) then updateBtn:Dock( TOP ) end
	end

	net.Receive( "SWGRP_HoloSignOpenMenu", function()
		local ent = net.ReadEntity()
		local currentText = net.ReadString()
		if IsValid( ent ) then
			SWGRP.OpenHoloSignMenu( ent, currentText )
		end
	end )
end

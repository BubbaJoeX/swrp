AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Tip Jar"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/starwars/syphadias/props/sw_tor/bioware_ea/items/harvesting/scavenge/scavenge_barrel.mdl"
ENT.SpinSpeed = 48
ENT.MinTip = 5
ENT.MaxTip = 500
ENT.TipSound = "items/suitchargepick1.wav"

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "Tips" )
end

local function IsJarOwner( jar, ply )
	if jar.SWGRP_Owner == ply then return true end
	if SWGRP.Ownership and SWGRP.Ownership.IsOwner( ply, jar ) then return true end
	return false
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetTips( 0 )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:CollectTips( ply )
		local tips = self:GetTips()
		if tips <= 0 then
			SWGRP.Notify( ply, "No tips in the jar yet." )
			return false
		end

		if not IsJarOwner( self, ply ) then
			SWGRP.Notify( ply, "Only the jar owner can collect tips." )
			return false
		end

		ply:SWGRP_AddCredits( tips )
		self:SetTips( 0 )
		self:EmitSound( self.TipSound, 65 )
		SWGRP.Notify( ply, "Collected tips: " .. SWGRP.FormatCredits( tips ) )
		return true
	end

	function ENT:GiveTip( ply, amount )
		amount = math.floor( amount or 0 )
		local minTip = self.MinTip
		local maxTip = self.MaxTip

		if amount < minTip or amount > maxTip then
			SWGRP.Notify( ply, string.format( "Tip must be between %s and %s.", SWGRP.FormatCredits( minTip ), SWGRP.FormatCredits( maxTip ) ) )
			return false
		end

		if IsJarOwner( self, ply ) then
			SWGRP.Notify( ply, "You can't tip your own jar." )
			return false
		end

		if not ply:SWGRP_TakeCredits( amount ) then
			SWGRP.Notify( ply, SWGRP.Lang.cant_afford or "You can't afford that." )
			return false
		end

		self:SetTips( self:GetTips() + amount )
		self:EmitSound( self.TipSound, 60 )
		SWGRP.Notify( ply, "You tipped " .. SWGRP.FormatCredits( amount ) )
		return true
	end

	function ENT:OpenMenu( activator )
		local minTip = self.MinTip
		local maxTip = math.min( self.MaxTip, activator:SWGRP_GetCredits() )
		if maxTip < minTip then maxTip = minTip end

		net.Start( "SWGRP_TipJarOpenMenu" )
			net.WriteEntity( self )
			net.WriteUInt( self:GetTips(), 32 )
			net.WriteBool( IsJarOwner( self, activator ) )
			net.WriteUInt( minTip, 16 )
			net.WriteUInt( maxTip, 16 )
		net.Send( activator )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.4

		self:OpenMenu( activator )
	end
end

if CLIENT then
	function ENT:Draw()
		local ang = self:GetAngles()
		ang.y = ( CurTime() * self.SpinSpeed ) % 360
		self:SetRenderAngles( ang )
		self:DrawModel()

		local tips = self.GetTips and self:GetTips() or self:GetNW2Int( "Tips", 0 )
		local subtitle = tips > 0
			and SWGRP.FormatCredits( tips ) .. " in jar — Press E"
			or "Press E to tip"

		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "TIP JAR", subtitle, SWGRP.UI.Colors.primary )
		end
	end

	function SWGRP.OpenTipJarMenu( ent, tips, isOwner, minTip, maxTip )
		local UI = SWGRP.UI
		if not UI or not UI.CreateTerminalFrame then return end

		if IsValid( SWGRP.TipJarFrame ) then SWGRP.TipJarFrame:Remove() end

		local frame = UI.CreateTerminalFrame( "TIP JAR", 300, isOwner and 180 or 240 )
		SWGRP.TipJarFrame = frame

		local body = vgui.Create( "DPanel", frame )
		body:Dock( FILL )
		body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
		body.Paint = function() end

		UI.CreateLabel( body, "In jar: " .. SWGRP.FormatCredits( tips ), "DermaDefaultBold", UI.Colors.primary, TOP )

		if isOwner then
			UI.CreateLabel( body, "Collect credits left by patrons.", "DermaDefault", UI.Colors.secondary, TOP )

			local collectBtn = UI.CreateButton( body, "COLLECT TIPS", function()
				net.Start( "SWGRP_TipJarAction" )
					net.WriteEntity( ent )
					net.WriteString( "collect" )
					net.WriteUInt( 0, 32 )
				net.SendToServer()
				frame:Close()
			end )
			if IsValid( collectBtn ) then
				collectBtn:Dock( TOP )
				collectBtn:SetEnabled( tips > 0 )
			end
			return
		end

		if maxTip < minTip then
			UI.CreateLabel( body, "You need at least " .. SWGRP.FormatCredits( minTip ) .. " to tip.", "DermaDefault", UI.Colors.danger, TOP )
			return
		end

		UI.CreateLabel( body, "Tip: " .. minTip .. " - " .. maxTip .. " CR", "DermaDefault", UI.Colors.secondary, TOP )

		local tipSlider = vgui.Create( "DNumSlider", body )
		tipSlider:Dock( TOP )
		tipSlider:DockMargin( 0, UI.Spacing.gap, 0, UI.Spacing.gap )
		tipSlider:SetMin( minTip )
		tipSlider:SetMax( maxTip )
		tipSlider:SetDecimals( 0 )
		tipSlider:SetValue( math.min( 25, maxTip ) )
		tipSlider:SetText( "Amount" )

		local quickRow = vgui.Create( "DPanel", body )
		quickRow:Dock( TOP )
		quickRow:DockMargin( 0, 0, 0, UI.Spacing.gap )
		quickRow:SetTall( UI.Spacing.button )
		quickRow.Paint = function() end

		local function sendTip( amount )
			net.Start( "SWGRP_TipJarAction" )
				net.WriteEntity( ent )
				net.WriteString( "tip" )
				net.WriteUInt( amount, 32 )
			net.SendToServer()
			frame:Close()
		end

		for _, preset in ipairs( { 25, 50, 100 } ) do
			if preset >= minTip and preset <= maxTip then
				local btn = UI.CreateButton( quickRow, tostring( preset ), function()
					sendTip( preset )
				end )
				if IsValid( btn ) then
					btn:Dock( LEFT )
					btn:DockMargin( 0, 0, 6, 0 )
					btn:SetWide( 72 )
				end
			end
		end

		local tipBtn = UI.CreateButton( body, "TIP", function()
			sendTip( math.Round( tipSlider:GetValue() ) )
		end )
		if IsValid( tipBtn ) then tipBtn:Dock( TOP ) end
	end

	net.Receive( "SWGRP_TipJarOpenMenu", function()
		local ent = net.ReadEntity()
		local tips = net.ReadUInt( 32 )
		local isOwner = net.ReadBool()
		local minTip = net.ReadUInt( 16 )
		local maxTip = net.ReadUInt( 16 )
		if IsValid( ent ) then
			SWGRP.OpenTipJarMenu( ent, tips, isOwner, minTip, maxTip )
		end
	end )
end

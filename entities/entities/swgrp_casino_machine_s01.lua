AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Gambling Gonk"
ENT.Category = "SWGRP"
ENT.Spawnable = false

ENT.DefaultModel = "models/kingpommes/emperors_tower/ph_props/gnk_droid/gnk_droid.mdl"
ENT.FallbackModel = "models/kingpommes/emperors_tower/ph_props/gnk_droid/gnk_droid.mdl"
ENT.Theme = "Spend your credits on this!"
ENT.SpinSound = "buttons/button14.wav"
ENT.WinSound = "ambient/levels/labs/coinslot1.wav"

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Spinning" )
end

local function IsCantinaOperator( ply )
	local job = SWGRP.GetJob( ply:Team() )
	return job and string.lower( job.command or "" ) == "cantina"
end

local function MinBet()
	return SWGRP.Config.CasinoMinBet and SWGRP.Config.CasinoMinBet:GetInt() or 10
end

local function MaxBet()
	return SWGRP.Config.CasinoMaxBet and SWGRP.Config.CasinoMaxBet:GetInt() or 500
end

if SERVER then
	function ENT:Initialize()
		self:SetModel( self.DefaultModel )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:SetSpinning( false )

		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Play( ply, bet )
		if self:GetSpinning() then return end

		bet = math.Clamp( math.floor( bet or MinBet() ), MinBet(), MaxBet() )
		if not ply:SWGRP_TakeCredits( bet ) then
			SWGRP.Notify( ply, SWGRP.Lang.cant_afford )
			return
		end

		self:SetSpinning( true )
		self:EmitSound( self.SpinSound, 65 )

		timer.Simple( 1.2, function()
			if not IsValid( self ) or not IsValid( ply ) then return end
			self:SetSpinning( false )

			local edge = SWGRP.Config.CasinoHouseEdge and SWGRP.Config.CasinoHouseEdge:GetFloat() or 0.05
			local winChance = 0.42 - edge
			local won = math.random() < winChance
			local payout = won and math.floor( bet * ( 1.5 + math.random() * 1.5 ) ) or 0

			if won and payout > 0 then
				ply:SWGRP_AddCredits( payout )
				self:EmitSound( self.WinSound, 70 )
				SWGRP.Notify( ply, string.format( "You won %s!", SWGRP.FormatCredits( payout ) ) )
			else
				-- House take goes to cantina operator owner when present.
				if IsValid( self.SWGRP_Owner ) and IsCantinaOperator( self.SWGRP_Owner ) then
					self.SWGRP_Owner:SWGRP_AddCredits( math.floor( bet * 0.9 ) )
				end
				SWGRP.Notify( ply, string.format( "You lost %s. Better luck next spin.", SWGRP.FormatCredits( bet ) ) )
			end
		end )
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		if self:GetSpinning() then return end

		self.SWGRP_NextUse = self.SWGRP_NextUse or {}
		local now = CurTime()
		if self.SWGRP_NextUse[activator] and self.SWGRP_NextUse[activator] > now then return end
		self.SWGRP_NextUse[activator] = now + 0.5

		net.Start( "SWGRP_CasinoOpenMenu" )
			net.WriteEntity( self )
			net.WriteUInt( MinBet(), 16 )
			net.WriteUInt( MaxBet(), 16 )
		net.Send( activator )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		local label = self:GetSpinning() and "SPINNING..." or "Gambling Gonk - Press [E] to gamble"
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, label, self.Theme or "classic", SWGRP.UI.Colors.accent )
		end
	end

	function SWGRP.OpenCasinoMenu( ent, minBet, maxBet )
		local UI = SWGRP.UI
		if not UI or not UI.CreateTerminalFrame then return end

		if IsValid( SWGRP.CasinoFrame ) then SWGRP.CasinoFrame:Remove() end

		local frame = UI.CreateTerminalFrame( "CASINO", 300, 200 )
		SWGRP.CasinoFrame = frame

		local body = vgui.Create( "DPanel", frame )
		body:Dock( FILL )
		body:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
		body.Paint = function() end

		UI.CreateLabel( body, "Bet: " .. minBet .. " - " .. maxBet .. " CR", "DermaDefault", UI.Colors.secondary, TOP )

		local betSlider = vgui.Create( "DNumSlider", body )
		betSlider:Dock( TOP )
		betSlider:DockMargin( 0, UI.Spacing.gap, 0, UI.Spacing.gap )
		betSlider:SetMin( minBet )
		betSlider:SetMax( maxBet )
		betSlider:SetDecimals( 0 )
		betSlider:SetValue( minBet )
		betSlider:SetText( "Wager" )

		local spinBtn = UI.CreateButton( body, "SPIN", function()
			net.Start( "SWGRP_CasinoBet" )
				net.WriteEntity( ent )
				net.WriteUInt( math.Round( betSlider:GetValue() ), 16 )
			net.SendToServer()
			frame:Close()
		end )
		if IsValid( spinBtn ) then spinBtn:Dock( TOP ) end
	end

	net.Receive( "SWGRP_CasinoOpenMenu", function()
		local ent = net.ReadEntity()
		local minBet = net.ReadUInt( 16 )
		local maxBet = net.ReadUInt( 16 )
		if IsValid( ent ) then
			SWGRP.OpenCasinoMenu( ent, minBet, maxBet )
		end
	end )
end

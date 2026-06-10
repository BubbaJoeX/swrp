AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Galactic ATM"
ENT.Category = "SWGRP"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/kingpommes/emperors_tower/ph_props/palp_panel1/palp_panel1.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		activator:SendLua( "SWGRP.OpenBankMenu()" )
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		if SWGRP.UI and SWGRP.UI.DrawWorldLabel then
			SWGRP.UI.DrawWorldLabel( self, "GALACTIC ATM", "Press E to bank", SWGRP.UI.Colors.accent )
		end
	end

	function SWGRP.OpenBankMenu()
		if IsValid( SWGRP.BankFrame ) then SWGRP.BankFrame:Remove() end

		local frame = vgui.Create( "DFrame" )
		frame:SetSize( 300, 220 )
		frame:Center()
		frame:SetTitle( "Galactic ATM" )
		frame:MakePopup()
		SWGRP.BankFrame = frame

		local bal = vgui.Create( "DLabel", frame )
		bal:SetText( "Bank: " .. SWGRP.FormatCredits( LocalPlayer():SWGRP_GetBank() ) )
		bal:Dock( TOP )
		bal:DockMargin( 10, 10, 10, 5 )

		local entry = vgui.Create( "DTextEntry", frame )
		entry:Dock( TOP )
		entry:DockMargin( 10, 5, 10, 5 )
		entry:SetPlaceholderText( "Amount..." )

		local dep = vgui.Create( "DButton", frame )
		dep:SetText( "Deposit" )
		dep:Dock( TOP )
		dep:DockMargin( 10, 2, 10, 2 )
		dep.DoClick = function()
			net.Start( "SWGRP_BankAction" )
				net.WriteString( "deposit" )
				net.WriteUInt( tonumber( entry:GetValue() ) or 0, 32 )
				net.WriteString( "" )
			net.SendToServer()
		end

		local wit = vgui.Create( "DButton", frame )
		wit:SetText( "Withdraw" )
		wit:Dock( TOP )
		wit:DockMargin( 10, 2, 10, 2 )
		wit.DoClick = function()
			net.Start( "SWGRP_BankAction" )
				net.WriteString( "withdraw" )
				net.WriteUInt( tonumber( entry:GetValue() ) or 0, 32 )
				net.WriteString( "" )
			net.SendToServer()
		end
	end
end

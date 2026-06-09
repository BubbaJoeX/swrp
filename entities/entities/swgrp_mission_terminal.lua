AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Mission Terminal"
ENT.Category = "SWGRP"
ENT.Spawnable = false

if SERVER then
	function ENT:Initialize()
		self:SetModel( "models/props_c17/consolebox03a.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then phys:Wake() end
	end

	function ENT:Use( activator )
		if not IsValid( activator ) or not activator:IsPlayer() then return end
		activator:SendLua( "SWGRP.OpenMissionMenu()" )
	end
end

if CLIENT then
	function SWGRP.OpenMissionMenu()
		if IsValid( SWGRP.MissionFrame ) then SWGRP.MissionFrame:Remove() end
		local frame = vgui.Create( "DFrame" )
		frame:SetSize( 400, 400 )
		frame:Center()
		frame:SetTitle( "Mission Terminal" )
		frame:MakePopup()
		SWGRP.MissionFrame = frame

		local scroll = vgui.Create( "DScrollPanel", frame )
		scroll:Dock( FILL )

		for id, mission in SortedPairsByMemberValue( SWGRP.Missions, "name" ) do
			local btn = vgui.Create( "DButton", scroll )
			btn:SetText( mission.name .. " - " .. SWGRP.FormatCredits( mission.reward ) )
			btn:Dock( TOP )
			btn:DockMargin( 5, 2, 5, 2 )
			btn:SetTooltip( mission.description )
			btn.DoClick = function()
				net.Start( "SWGRP_AcceptMission" )
					net.WriteUInt( id, 8 )
				net.SendToServer()
				frame:Close()
			end
		end
	end
end

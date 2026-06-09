--[[---------------------------------------------------------------------------
    Lockpick Minigame Client
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.LockpickUI = SWGRP.LockpickUI or {}

net.Receive( "SWGRP_Lockpick", function()
	local entIndex = net.ReadUInt( 16 )
	local endTime = net.ReadFloat()

	if IsValid( SWGRP.LockpickUI.Frame ) then
		SWGRP.LockpickUI.Frame:Remove()
	end

	local UI = SWGRP.UI
	local frame = UI.CreateTerminalFrame( "SECURITY BYPASS", 360, 160 )
	frame:SetPos( ScrW() / 2 - 180, ScrH() / 2 - 80 )
	frame:ShowCloseButton( false )
	SWGRP.LockpickUI.Frame = frame

	local inner = vgui.Create( "DPanel", frame )
	inner:Dock( FILL )
	inner:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	inner.Paint = function() end

	UI.CreateLabel( inner, "Press SPACE when the marker is in the green zone.", "DermaDefault", UI.Colors.secondary, TOP )
		:DockMargin( 0, 0, 0, UI.Spacing.gap )

	local bar = vgui.Create( "DPanel", inner )
	bar:Dock( TOP )
	bar:SetTall( 28 )
	bar:DockMargin( 0, 0, 0, UI.Spacing.gap )

	local zoneStart = math.Rand( 0.25, 0.55 )
	local zoneWidth = 0.18
	local cursor = 0
	local direction = 1
	local fired = false

	bar.Paint = function( self, w, h )
		surface.SetDrawColor( UI.Colors.bgLight )
		surface.DrawRect( 0, 0, w, h )

		local zx = zoneStart * w
		local zw = zoneWidth * w
		surface.SetDrawColor( 40, 160, 80, 180 )
		surface.DrawRect( zx, 2, zw, h - 4 )

		surface.SetDrawColor( UI.Colors.primary )
		surface.DrawRect( cursor * w - 2, 0, 4, h )

		surface.SetDrawColor( UI.Colors.borderDim )
		surface.DrawOutlinedRect( 0, 0, w, h, 1 )
	end

	bar.Think = function( self )
		if fired then return end
		cursor = cursor + direction * FrameTime() * 0.85
		if cursor >= 1 then
			cursor = 1
			direction = -1
		elseif cursor <= 0 then
			cursor = 0
			direction = 1
		end
	end

	local function submit( success )
		if fired then return end
		fired = true
		net.Start( "SWGRP_LockpickResult" )
			net.WriteBool( success )
		net.SendToServer()
		if IsValid( frame ) then frame:Remove() end
	end

	frame.Think = function()
		if CurTime() > endTime then
			submit( false )
			return
		end

		if input.IsKeyDown( KEY_SPACE ) and not fired then
			local inZone = cursor >= zoneStart and cursor <= ( zoneStart + zoneWidth )
			submit( inZone )
		end
	end
end )

--[[---------------------------------------------------------------------------
    Vote UI Panels
---------------------------------------------------------------------------]]

local UI = SWGRP.UI

net.Receive( "SWGRP_OpenVote", function()
	local voteType = net.ReadString()
	local target = net.ReadEntity()
	local label = net.ReadString()
	local endTime = net.ReadFloat()

	if not IsValid( target ) then return end
	if IsValid( SWGRP.VoteFrame ) then SWGRP.VoteFrame:Remove() end

	local frame = UI.CreateTerminalFrame( "COLONY VOTE: " .. string.upper( label ), 340, 150 )
	frame:SetPos( ScrW() / 2 - 170, 100 )
	frame:SetDraggable( false )
	frame:ShowCloseButton( false )
	SWGRP.VoteFrame = frame

	if IsValid( frame.btnClose ) then
		frame.btnClose:SetVisible( false )
	end

	local inner = vgui.Create( "DPanel", frame )
	inner:Dock( FILL )
	inner:DockMargin( UI.Spacing.frame, 40, UI.Spacing.frame, UI.Spacing.frame )
	inner.Paint = function() end

	local timerLabel = UI.CreateLabel( inner, "Time remaining...", "DermaDefaultBold", UI.Colors.accent, TOP )
	timerLabel:DockMargin( 0, 0, 0, UI.Spacing.gapLarge )

	frame.Think = function()
		local left = math.max( 0, endTime - CurTime() )
		timerLabel:SetText( "Time remaining: " .. math.ceil( left ) .. "s" )
		if left <= 0 then frame:Remove() end
	end

	local btnRow = vgui.Create( "DPanel", inner )
	btnRow:Dock( BOTTOM )
	btnRow:SetTall( UI.Spacing.button )
	btnRow:DockMargin( 0, UI.Spacing.gap, 0, 0 )
	btnRow.Paint = function() end

	local yes = UI.CreateButton( btnRow, "Approve", function()
		net.Start( "SWGRP_CastVote" )
			net.WriteString( voteType )
			net.WriteEntity( target )
			net.WriteBool( true )
		net.SendToServer()
		frame:Remove()
	end )
	yes:Dock( LEFT )
	yes:SetWide( 150 )
	yes:DockMargin( 0, 0, UI.Spacing.gap, 0 )

	local no = UI.CreateButton( btnRow, "Deny", function()
		net.Start( "SWGRP_CastVote" )
			net.WriteString( voteType )
			net.WriteEntity( target )
			net.WriteBool( false )
		net.SendToServer()
		frame:Remove()
	end )
	no:Dock( FILL )
end )

--[[---------------------------------------------------------------------------
    Client asset precache and HUD drawing helpers
---------------------------------------------------------------------------]]

local A = SWGRP.Assets
local UI = SWGRP.UI

function A.DrawScoreboardLogo( x, y, w, h, alpha )
	alpha = alpha or 255
	local path = A.GetScoreboardLogoPath()

	if A.IsGuiPath( path ) then
		surface.SetTexture( surface.GetTextureID( path ) )
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.DrawTexturedRect( x, y, w, h )
		return
	end

	if UI then UI.SyncColors() end
	local tint = UI and UI.Colors.primary or Color( 255, 180, 50 )
	local mat = A.Material( path )
	surface.SetMaterial( mat )
	surface.SetDrawColor( tint.r, tint.g, tint.b, alpha )
	surface.DrawTexturedRect( x, y, w, h )
end

hook.Add( "Initialize", "SWGRP_Assets", function()
	A.GetScoreboardLogoPath()
	for _, path in ipairs( A.LogoCandidates ) do
		A.Material( path )
	end
	A.Material( A.FAdminBack )
end )

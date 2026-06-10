--[[---------------------------------------------------------------------------
    Vehicle owner labels (3D2D) and lock state display
---------------------------------------------------------------------------]]

local UI = SWGRP.UI or {}
local LABEL_DIST = 900
local SPIN_SPEED = 24

local function labelColors()
	if UI.SyncColors then UI.SyncColors() end
	return {
		primary   = UI.Colors and UI.Colors.primary or Color( 255, 180, 50 ),
		secondary = UI.Colors and UI.Colors.secondary or Color( 200, 200, 200 ),
		danger    = UI.Colors and UI.Colors.danger or Color( 255, 60, 60 ),
		bg        = UI.Colors and UI.Colors.bg or Color( 10, 15, 25 ),
	}
end

local function vehicleLabelPos( ent )
	local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
	local center = ent:LocalToWorld( ( mins + maxs ) * 0.5 )
	local lift = ( maxs.z - mins.z ) * 0.5 + 32
	return center + Vector( 0, 0, lift )
end

local function drawVehicleOwnerLabel( ent, eyePos )
	local ownerName = ent:GetNWString( "SWGRP_VehicleOwnerName", "" )
	if ownerName == "" then return end

	local ownerJob = ent:GetNWString( "SWGRP_VehicleOwnerJob", "" )
	local locked = ent:GetNWBool( "SWGRP_VehicleLocked", false )
	local colors = labelColors()

	local pos = vehicleLabelPos( ent )
	local dist = eyePos:Distance( pos )
	if dist > LABEL_DIST then return end

	local alpha = math.Clamp( ( LABEL_DIST - dist ) / 250, 0, 1 ) * 255
	local spin = ( CurTime() * SPIN_SPEED ) % 360
	local ang = Angle( 0, spin, 90 )
	local scale = 0.11

	local subtitle = ownerJob ~= "" and ownerJob or "Owner"
	surface.SetFont( "DermaLarge" )
	local tw = surface.GetTextSize( ownerName )
	surface.SetFont( "DermaDefaultBold" )
	local sw = surface.GetTextSize( subtitle )
	local boxW = math.max( tw, sw ) + 48
	local boxH = locked and 78 or 58

	cam.Start3D2D( pos, ang, scale )
		draw.RoundedBox( 8, -boxW / 2, -boxH / 2, boxW, boxH, Color( colors.bg.r, colors.bg.g, colors.bg.b, alpha * 0.85 ) )
		surface.SetDrawColor( colors.primary.r, colors.primary.g, colors.primary.b, alpha )
		surface.DrawOutlinedRect( -boxW / 2, -boxH / 2, boxW, boxH, 2 )

		local titleY = locked and -14 or -6
		draw.SimpleText(
			ownerName,
			"DermaLarge",
			0,
			titleY,
			Color( colors.primary.r, colors.primary.g, colors.primary.b, alpha ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		draw.SimpleText(
			subtitle,
			"DermaDefaultBold",
			0,
			locked and 8 or 14,
			Color( 220, 220, 220, alpha ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		if locked then
			draw.SimpleText(
				"LOCKED",
				"DermaDefaultBold",
				0,
				26,
				Color( colors.danger.r, colors.danger.g, colors.danger.b, alpha ),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER
			)
		end
	cam.End3D2D()
end

hook.Add( "PostDrawTranslucentRenderables", "SWGRP_VehicleLabels", function( _, skybox )
	if skybox then return end

	local ply = LocalPlayer()
	if not IsValid( ply ) then return end

	local eyePos = ply:EyePos()

	for _, ent in ipairs( ents.FindInSphere( eyePos, LABEL_DIST ) ) do
		if not SWGRP.IsManagedVehicle( ent ) then continue end
		if SWGRP.VehicleHasDriver( ent ) then continue end
		drawVehicleOwnerLabel( ent, eyePos )
	end
end )

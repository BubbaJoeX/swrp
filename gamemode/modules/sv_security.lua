--[[---------------------------------------------------------------------------
    Security Cameras & Screens
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Security = SWGRP.Security or {}

local SEC = SWGRP.Security

function SEC.MaxCameras()
	return SWGRP.Config.SecurityCamMax and SWGRP.Config.SecurityCamMax:GetInt() or 3
end

function SEC.CountCameras( ply )
	local n = 0
	for _, ent in ipairs( ents.FindByClass( "swgrp_security_camera" ) ) do
		if IsValid( ent ) and ent.SWGRP_Owner == ply then
			n = n + 1
		end
	end
	return n
end

function SEC.CountScreens( ply )
	local n = 0
	for _, ent in ipairs( ents.FindByClass( "swgrp_security_screen" ) ) do
		if IsValid( ent ) and ent.SWGRP_Owner == ply then
			n = n + 1
		end
	end
	return n
end

function SEC.GetCameras( ply )
	local list = {}
	for _, ent in ipairs( ents.FindByClass( "swgrp_security_camera" ) ) do
		if IsValid( ent ) and ent.SWGRP_Owner == ply then
			table.insert( list, ent )
		end
	end
	return list
end

function SEC.CanPlaceCamera( ply )
	return SEC.CountCameras( ply ) < SEC.MaxCameras()
end

function SEC.PlaceCamera( ply, pos, ang )
	if not IsValid( ply ) then return nil end
	if not SEC.CanPlaceCamera( ply ) then
		SWGRP.Notify( ply, "Maximum security cameras placed (" .. SEC.MaxCameras() .. ")." )
		return nil
	end

	local ent = ents.Create( "swgrp_security_camera" )
	if not IsValid( ent ) then return nil end

	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	if SWGRP.Ownership then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	ent:LinkOwnerScreens()
	SWGRP.Notify( ply, "Security camera placed (" .. SEC.CountCameras( ply ) .. "/" .. SEC.MaxCameras() .. ")." )
	return ent
end

function SEC.PlaceScreen( ply, pos, ang )
	if not IsValid( ply ) then return nil end

	local ent = ents.Create( "swgrp_security_screen" )
	if not IsValid( ent ) then return nil end

	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	if SWGRP.Ownership then
		SWGRP.Ownership.SetOwner( ent, ply )
	end

	ent:RefreshCameraList()
	SWGRP.Notify( ply, "Security screen placed. Press E to cycle camera feeds." )
	return ent
end

function SEC.SyncTo( ply )
	if not IsValid( ply ) then return end

	local cams = SEC.GetCameras( ply )
	net.Start( "SWGRP_SecuritySync" )
		net.WriteUInt( #cams, 8 )
		for _, cam in ipairs( cams ) do
			net.WriteUInt( cam:EntIndex(), 16 )
		end
	net.Send( ply )
end

hook.Add( "PlayerDisconnected", "SWGRP_SecurityCleanup", function( ply )
	for _, class in ipairs( { "swgrp_security_camera", "swgrp_security_screen" } ) do
		for _, ent in ipairs( ents.FindByClass( class ) ) do
			if IsValid( ent ) and ent.SWGRP_Owner == ply then
				ent:Remove()
			end
		end
	end
end )

TOOL.Category = "SWGRP"
TOOL.Name = "#Security Camera"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {}

if CLIENT then
	language.Add( "tool.swgrp_security_camera.name", "Security Camera" )
	language.Add( "tool.swgrp_security_camera.desc", "Place a security camera (max 3 per player)" )
	language.Add( "tool.swgrp_security_camera.0", "Primary: Place camera" )
end

function TOOL:LeftClick( trace )
	if not trace.Hit then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not IsValid( ply ) then return false end

	if not SWGRP.Security or not SWGRP.Security.PlaceCamera then return false end

	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = ply:EyeAngles()
	ang.p = 0
	ang.r = 0

	SWGRP.Security.PlaceCamera( ply, pos, ang )
	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Reload( trace )
	return false
end

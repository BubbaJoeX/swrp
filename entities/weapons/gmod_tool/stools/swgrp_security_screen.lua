TOOL.Category = "SWGRP"
TOOL.Name = "#Security Screen"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {}

if CLIENT then
	language.Add( "tool.swgrp_security_screen.name", "Security Screen" )
	language.Add( "tool.swgrp_security_screen.desc", "Place a monitor linked to your security cameras" )
	language.Add( "tool.swgrp_security_screen.0", "Primary: Place screen. Press E on screen to cycle feeds." )
end

function TOOL:LeftClick( trace )
	if not trace.Hit then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not IsValid( ply ) then return false end

	if not SWGRP.Security or not SWGRP.Security.PlaceScreen then return false end

	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = trace.HitNormal:Angle()
	ang:RotateAroundAxis( ang:Right(), -90 )

	SWGRP.Security.PlaceScreen( ply, pos, ang )
	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Reload( trace )
	return false
end

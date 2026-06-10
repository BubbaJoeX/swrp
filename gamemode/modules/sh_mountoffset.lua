--[[---------------------------------------------------------------------------
    Mount offset helpers (shared)
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.MountOffset = SWGRP.MountOffset or {}

-- Align entity +Z (up) with the outward face normal so a prop sits on the clicked surface.
function SWGRP.MountOffset.WorldAnglesOnSurface( normal )
	normal = Vector( normal.x, normal.y, normal.z )
	if normal:LengthSqr() < 0.0001 then
		return Angle( 0, 0, 0 )
	end

	normal:Normalize()
	local ang = normal:Angle()
	ang:RotateAroundAxis( ang:Right(), -90 )
	return ang
end

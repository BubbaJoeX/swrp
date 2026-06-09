--[[---------------------------------------------------------------------------
    SWGRP Hook API - Addon integration points
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Hooks = SWGRP.Hooks or {}

function SWGRP.Hooks.Call( name, ... )
	return hook.Call( name, nil, ... )
end

function SWGRP.Hooks.CallCan( name, default, ... )
	local results = { hook.Call( name, nil, ... ) }
	for _, result in ipairs( results ) do
		if result == false then return false end
		if istable( result ) and result[1] == false then
			return false, result[2]
		end
	end
	return default
end

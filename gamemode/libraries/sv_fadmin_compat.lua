--[[---------------------------------------------------------------------------
    Server-side DarkRP utilities used by FAdmin teleport actions
---------------------------------------------------------------------------]]

function DarkRP.isEmpty( vector, ignore )
	ignore = ignore or {}

	local point = util.PointContents( vector )
	local clear = point ~= CONTENTS_SOLID
		and point ~= CONTENTS_MOVEABLE
		and point ~= CONTENTS_LADDER
		and point ~= CONTENTS_PLAYERCLIP
		and point ~= CONTENTS_MONSTERCLIP

	if not clear then return false end

	for _, ent in ipairs( ents.FindInSphere( vector, 35 ) ) do
		if ( ent:IsNPC() or ent:IsPlayer() or ent:GetClass() == "prop_physics" or ent.NotEmptyPos )
			and not table.HasValue( ignore, ent ) then
			return false
		end
	end

	return true
end

function DarkRP.findEmptyPos( pos, ignore, distance, step, area )
	if DarkRP.isEmpty( pos, ignore ) and DarkRP.isEmpty( pos + area, ignore ) then
		return pos
	end

	for j = step, distance, step do
		for i = -1, 1, 2 do
			local k = j * i

			if DarkRP.isEmpty( pos + Vector( k, 0, 0 ), ignore ) and DarkRP.isEmpty( pos + Vector( k, 0, 0 ) + area, ignore ) then
				return pos + Vector( k, 0, 0 )
			end

			if DarkRP.isEmpty( pos + Vector( 0, k, 0 ), ignore ) and DarkRP.isEmpty( pos + Vector( 0, k, 0 ) + area, ignore ) then
				return pos + Vector( 0, k, 0 )
			end

			if DarkRP.isEmpty( pos + Vector( 0, 0, k ), ignore ) and DarkRP.isEmpty( pos + Vector( 0, 0, k ) + area, ignore ) then
				return pos + Vector( 0, 0, k )
			end
		end
	end

	return pos
end

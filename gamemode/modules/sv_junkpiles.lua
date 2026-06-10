--[[---------------------------------------------------------------------------
    Refugee junk piles — random map spawns scavengable for credits, food, or SE-14C
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.JunkPiles = SWGRP.JunkPiles or {}

local JP = SWGRP.JunkPiles

JP.ModelPool = {
	"models/props_junk/garbage_bag_01a.mdl",
	"models/props_junk/garbage_bag_02a.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_junk/wood_crate002a.mdl",
	"models/props_junk/cardboard_box001a.mdl",
	"models/props_junk/cardboard_box003a.mdl",
	"models/props_junk/cardboard_box004a.mdl",
	"models/props_junk/metalbucket01a.mdl",
	"models/props_junk/garbage_metalcan001a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props/cs_office/trash_can.mdl",
	"models/starwars/syphadias/props/sw_tor/bioware_ea/items/harvesting/scavenge/scavenge_barrel.mdl",
}

local MIN_SPACING_SQR = 360 * 360
local MAP_EDGE_MARGIN = 384
local DEFAULT_MAP_HALF = 8192

local function enabled()
	local cv = SWGRP.Config.JunkPilesEnabled
	return cv and cv:GetBool()
end

local function targetCount()
	local cv = SWGRP.Config.JunkPileCount
	return math.max( 0, cv and cv:GetInt() or 16 )
end

local function modelOk( mdl )
	return mdl and mdl ~= "" and util.IsValidModel( mdl )
end

function JP.GetValidModels()
	local list = {}
	for _, mdl in ipairs( JP.ModelPool ) do
		if modelOk( mdl ) then
			table.insert( list, mdl )
		end
	end
	if #list == 0 then
		table.insert( list, "models/props_junk/garbage_bag_01a.mdl" )
	end
	return list
end

function JP.PickModel()
	local models = JP.GetValidModels()
	return models[math.random( #models )]
end

-- Playable XY bounds from the world hull (map-wide), not player spawns.
function JP.GetMapBounds()
	local mins, maxs

	local world = game.GetWorld()
	if IsValid( world ) then
		mins, maxs = world:GetModelBounds()
	end

	if not mins or not maxs or mins:DistToSqr( maxs ) < 1 then
		mins = Vector( -DEFAULT_MAP_HALF, -DEFAULT_MAP_HALF, 0 )
		maxs = Vector( DEFAULT_MAP_HALF, DEFAULT_MAP_HALF, 0 )
	end

	mins = Vector( mins.x + MAP_EDGE_MARGIN, mins.y + MAP_EDGE_MARGIN, 0 )
	maxs = Vector( maxs.x - MAP_EDGE_MARGIN, maxs.y - MAP_EDGE_MARGIN, 0 )

	if maxs.x <= mins.x or maxs.y <= mins.y then
		mins = Vector( -DEFAULT_MAP_HALF, -DEFAULT_MAP_HALF, 0 )
		maxs = Vector( DEFAULT_MAP_HALF, DEFAULT_MAP_HALF, 0 )
	end

	return mins, maxs
end

function JP.RandomMapPoint()
	local mins, maxs = JP.GetMapBounds()
	return Vector(
		math.random( math.floor( mins.x ), math.floor( maxs.x ) ),
		math.random( math.floor( mins.y ), math.floor( maxs.y ) ),
		0
	)
end

local function isWater( pos )
	local contents = util.PointContents( pos + Vector( 0, 0, 4 ) )
	return contents == CONTENTS_WATER or contents == CONTENTS_SLIME
end

function JP.TraceGround( pos )
	local tr = util.TraceLine( {
		start = pos + Vector( 0, 0, 32768 ),
		endpos = pos - Vector( 0, 0, 32768 ),
		mask = MASK_SOLID_BRUSHONLY,
	} )

	if not tr.Hit or tr.HitSky or isWater( tr.HitPos ) then return nil end
	return tr.HitPos
end

function JP.IsSpotClear( pos )
	if not SWGRP.Util.IsEmpty( pos + Vector( 0, 0, 24 ), {} ) then return false end

	for _, ent in ipairs( ents.FindInSphere( pos, 72 ) ) do
		if ent:GetClass() == "swgrp_junk_pile" then return false end
		if ent:IsPlayer() or ent:IsNPC() then return false end
	end

	return true
end

function JP.IsFarEnough( pos, placed )
	for _, other in ipairs( placed ) do
		if pos:DistToSqr( other ) < MIN_SPACING_SQR then
			return false
		end
	end
	return true
end

function JP.FindSpawnPos( placed )
	placed = placed or {}

	for _ = 1, 64 do
		local ground = JP.TraceGround( JP.RandomMapPoint() )
		if not ground then continue end
		if not JP.IsSpotClear( ground ) then continue end
		if not JP.IsFarEnough( ground, placed ) then continue end
		return ground
	end

	return nil
end

function JP.Clear()
	for _, ent in ipairs( ents.FindByClass( "swgrp_junk_pile" ) ) do
		ent:Remove()
	end
end

function JP.GetExistingPilePositions()
	local placed = {}
	for _, ent in ipairs( ents.FindByClass( "swgrp_junk_pile" ) ) do
		if IsValid( ent ) then
			table.insert( placed, ent:GetPos() )
		end
	end
	return placed
end

function JP.DropFromSky( nearPos, ang, groundPos )
	if not groundPos then
		groundPos = JP.FindSpawnPos( JP.GetExistingPilePositions() )
	end
	if not groundPos then
		groundPos = JP.TraceGround( nearPos or vector_origin ) or nearPos or vector_origin
	end

	ang = ang or Angle( 0, math.random( 0, 359 ), 0 )

	local heightCv = SWGRP.Config.JunkPileDropHeight
	local minH = 400
	local maxH = 650
	if heightCv then
		minH = math.max( 200, heightCv:GetInt() - 100 )
		maxH = math.max( minH + 50, heightCv:GetInt() + 100 )
	end

	local skyPos = groundPos + Vector( math.random( -40, 40 ), math.random( -40, 40 ), math.random( minH, maxH ) )

	local ent = ents.Create( "swgrp_junk_pile" )
	if not IsValid( ent ) then return nil end

	ent.SWGRP_SkyDrop = true
	ent:SetJunkModel( JP.PickModel() )
	ent:SetPos( skyPos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	local phys = ent:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( true )
		phys:Wake()
		phys:SetVelocity( Vector( math.random( -60, 60 ), math.random( -60, 60 ), math.random( -120, -40 ) ) )
		phys:AddAngleVelocity( Vector( math.random( -90, 90 ), math.random( -90, 90 ), math.random( -90, 90 ) ) )
	end

	ent:EmitSound( "physics/cardboard/cardboard_box_impact_hard" .. math.random( 1, 3 ) .. ".wav", 65, math.random( 95, 105 ), 0.6 )

	return ent
end

function JP.SpawnOne( pos, ang )
	return JP.DropFromSky( pos, ang, pos )
end

function JP.SpawnAll()
	if not enabled() then return end

	local count = targetCount()
	if count <= 0 then return end

	JP.Clear()

	local placed = {}
	local spawned = 0

	for _ = 1, count * 8 do
		if spawned >= count then break end

		local pos = JP.FindSpawnPos( placed )
		if not pos then continue end

		if JP.SpawnOne( pos ) then
			table.insert( placed, pos )
			spawned = spawned + 1
		end
	end

	print( string.format( "[SWGRP] Spawned %d refugee junk pile(s) on %s.", spawned, game.GetMap() ) )
end

hook.Add( "InitPostEntity", "SWGRP_JunkPiles", function()
	timer.Simple( 2, function()
		JP.SpawnAll()
	end )
end )

hook.Add( "PostCleanupMap", "SWGRP_JunkPiles", function()
	timer.Simple( 1, function()
		JP.SpawnAll()
	end )
end )

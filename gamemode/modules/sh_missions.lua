--[[---------------------------------------------------------------------------
    Mission Definitions
---------------------------------------------------------------------------]]

SWGRP.Missions = SWGRP.Missions or {}

function SWGRP.RegisterMission( data )
	data.id = data.id or #SWGRP.Missions + 1
	SWGRP.Missions[data.id] = data
end

SWGRP.RegisterMission( {
	id = 1,
	name = "Courier Run",
	description = "Transport data chips across the settlement.",
	type = "courier",
	reward = 200,
	xp = 30,
	duration = 180,
	faction = "neutral",
	allowed = nil,
} )

SWGRP.RegisterMission( {
	id = 2,
	name = "Pest Control",
	description = "Eliminate hostile wildlife threatening the colony.",
	type = "elimination",
	reward = 350,
	xp = 50,
	duration = 240,
	kills = 3,
	faction = "neutral",
} )

SWGRP.RegisterMission( {
	id = 3,
	name = "Resource Survey",
	description = "Collect mineral samples from the surrounding terrain.",
	type = "collection",
	reward = 275,
	xp = 40,
	duration = 200,
	collects = 5,
	faction = "neutral",
} )

SWGRP.RegisterMission( {
	id = 4,
	name = "Imperial Patrol",
	description = "Patrol designated sectors and report rebel activity.",
	type = "patrol",
	reward = 400,
	xp = 55,
	duration = 300,
	faction = "imperial",
	allowed = { TEAM_STORMTROOPER, TEAM_OFFICER, TEAM_COMMANDER },
	factionGain = { imperial = 5 },
} )

SWGRP.RegisterMission( {
	id = 5,
	name = "Rebel Sabotage",
	description = "Disrupt Imperial communications equipment.",
	type = "sabotage",
	reward = 450,
	xp = 60,
	duration = 300,
	faction = "rebel",
	allowed = { TEAM_REBEL, TEAM_REBELPILOT, TEAM_SMUGGLER },
	factionGain = { rebel = 5, imperial = -3 },
} )

SWGRP.RegisterMission( {
	id = 6,
	name = "Spice Run",
	description = "Move contraband through Imperial checkpoints. High risk.",
	type = "smuggle",
	reward = 600,
	xp = 70,
	duration = 360,
	faction = "underworld",
	allowed = { TEAM_SMUGGLER, TEAM_BOUNTYHUNTER },
	factionGain = { underworld = 8, imperial = -5 },
} )

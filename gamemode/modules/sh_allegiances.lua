--[[---------------------------------------------------------------------------
    Faction / Allegiance definitions for profession grouping
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}

SWGRP.Allegiance = {
	NEUTRAL     = "neutral",
	IMPERIAL    = "imperial",
	REBEL       = "rebel",
	UNDERWORLD  = "underworld",
}

SWGRP.AllegianceData = {
	[SWGRP.Allegiance.NEUTRAL] = {
		name = "Neutral Colonists",
		short = "Neutral",
		description = "Civilians, settlers, and independent tradesfolk unaligned with major powers.",
		color = Color( 80, 200, 120 ),
		icon = "icon16/user.png",
		sortOrder = 1,
	},
	[SWGRP.Allegiance.IMPERIAL] = {
		name = "Galactic Empire",
		short = "Imperial",
		description = "Imperial military, security forces, and planetary governance.",
		color = Color( 180, 180, 220 ),
		icon = "icon16/shield.png",
		sortOrder = 2,
	},
	[SWGRP.Allegiance.REBEL] = {
		name = "Rebel Alliance",
		short = "Rebel",
		description = "Resistance fighters opposing Imperial occupation.",
		color = Color( 255, 90, 70 ),
		icon = "icon16/flag_red.png",
		sortOrder = 3,
	},
	[SWGRP.Allegiance.UNDERWORLD] = {
		name = "Underworld",
		short = "Underworld",
		description = "Smugglers, bounty hunters, mercenaries, and black-market operatives.",
		color = Color( 150, 50, 200 ),
		icon = "icon16/bomb.png",
		sortOrder = 4,
	},
}

function SWGRP.GetAllegianceData( allegiance )
	return SWGRP.AllegianceData[allegiance]
end

function SWGRP.GetJobsByAllegiance( allegiance )
	local jobs = {}
	for teamId, job in pairs( SWGRP.Jobs ) do
		if job.allegiance == allegiance then
			jobs[teamId] = job
		end
	end
	return jobs
end

-- Infer allegiance from legacy category when not explicitly set
SWGRP.AllegianceFromCategory = {
	["Civilians"] = SWGRP.Allegiance.NEUTRAL,
	["Imperial Forces"] = SWGRP.Allegiance.IMPERIAL,
	["Rebel Alliance"] = SWGRP.Allegiance.REBEL,
	["Combat Professions"] = SWGRP.Allegiance.UNDERWORLD,
}

function SWGRP.GetJobAllegiance( job )
	if job.allegiance then return job.allegiance end
	return SWGRP.AllegianceFromCategory[job.category] or SWGRP.Allegiance.NEUTRAL
end

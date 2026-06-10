--[[---------------------------------------------------------------------------
    Crafting Recipes
---------------------------------------------------------------------------]]

SWGRP.Recipes = SWGRP.Recipes or {}

function SWGRP.RegisterRecipe( data )
	data.id = data.id or string.lower( string.gsub( data.name, "%s+", "_" ) )
	SWGRP.Recipes[data.id] = data
end

SWGRP.RegisterRecipe( {
	name = "Metal Plating",
	id = "metal_plating",
	materials = { metal = 3 },
	reward = { metal = 0 },
	credits = 25,
	xp = 10,
	allowed = { TEAM_ARTISAN, TEAM_MERCHANT },
	category = "Refining",
} )

SWGRP.RegisterRecipe( {
	name = "Energy Cell",
	id = "energy_cell",
	materials = { metal = 2, chemical = 1 },
	giveMaterials = { energy_cell = 1 },
	credits = 0,
	xp = 25,
	allowed = { TEAM_ARTISAN },
	category = "Manufacturing",
} )

SWGRP.RegisterRecipe( {
	name = "Med Patch",
	id = "med_patch",
	materials = { chemical = 2, fiber = 1 },
	heal = 50,
	credits = 0,
	xp = 20,
	allowed = { TEAM_ARTISAN, TEAM_DOCTOR, TEAM_MEDIC },
	category = "Medical",
} )

SWGRP.RegisterRecipe( {
	name = "Ration Pack",
	id = "ration_pack",
	materials = { fiber = 2, chemical = 1 },
	giveHunger = 40,
	credits = 0,
	xp = 15,
	allowed = { TEAM_ARTISAN, TEAM_CANTINA },
	category = "Survival",
} )

SWGRP.RegisterRecipe( {
	name = "Electronic Scanner",
	id = "electronics_scanner",
	materials = { electronics = 3, metal = 1 },
	credits = 150,
	xp = 40,
	allowed = { TEAM_ARTISAN },
	category = "Manufacturing",
} )

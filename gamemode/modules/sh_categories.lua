--[[---------------------------------------------------------------------------
    F4 Menu Categories - SWG Profession groupings
---------------------------------------------------------------------------]]

-- Job F4 categories now map to faction allegiance tabs
SWGRP.RegisterCategory( {
	name = "Neutral Colonists",
	categorises = "jobs",
	startExpanded = true,
	color = Color( 80, 200, 120 ),
	sortOrder = 1,
} )

SWGRP.RegisterCategory( {
	name = "Galactic Empire",
	categorises = "jobs",
	startExpanded = true,
	color = Color( 180, 180, 200 ),
	sortOrder = 2,
} )

SWGRP.RegisterCategory( {
	name = "Rebel Alliance",
	categorises = "jobs",
	startExpanded = false,
	color = Color( 255, 80, 80 ),
	sortOrder = 3,
} )

SWGRP.RegisterCategory( {
	name = "Underworld",
	categorises = "jobs",
	startExpanded = false,
	color = Color( 150, 50, 200 ),
	sortOrder = 4,
} )

SWGRP.RegisterCategory( {
	name = "Structures & Commerce",
	categorises = "entities",
	startExpanded = true,
	color = Color( 255, 180, 50 ),
	sortOrder = 10,
} )

SWGRP.RegisterCategory( {
	name = "Shipments",
	categorises = "shipments",
	startExpanded = false,
	color = Color( 255, 120, 50 ),
	sortOrder = 20,
} )

SWGRP.RegisterCategory( {
	name = "Ammunition",
	categorises = "ammo",
	startExpanded = false,
	color = Color( 150, 150, 150 ),
	sortOrder = 30,
} )

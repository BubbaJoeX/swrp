--[[---------------------------------------------------------------------------
    Contraband Types
---------------------------------------------------------------------------]]

SWGRP.ContrabandTypes = SWGRP.ContrabandTypes or {}

function SWGRP.RegisterContraband( data )
	SWGRP.ContrabandTypes[data.id] = data
end

SWGRP.RegisterContraband( {
	id = "spice",
	name = "Spice",
	value = 300,
	fine = 500,
	wanted = true,
} )

SWGRP.RegisterContraband( {
	id = "illegal_weapons",
	name = "Illegal Weapons",
	value = 400,
	fine = 750,
	wanted = true,
} )

SWGRP.RegisterContraband( {
	id = "data_chip",
	name = "Stolen Data Chip",
	value = 200,
	fine = 350,
	wanted = false,
} )

SWGRP.RegisterContraband( {
	id = "rebel_propaganda",
	name = "Rebel Propaganda",
	value = 100,
	fine = 250,
	wanted = false,
} )

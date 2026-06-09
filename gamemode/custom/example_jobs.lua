--[[---------------------------------------------------------------------------
    Custom Profession Example
    Copy this file and edit to add your own professions without modifying core.
    Remove the .example extension or create new .lua files in this folder.
---------------------------------------------------------------------------]]

--[[
SWGRP.RegisterJob( "Jedi Knight", {
    color = Color( 50, 100, 255 ),
    model = { "models/player/kleiner.mdl" },
    description = "Force-sensitive guardian of peace.",
    weapons = { "weapon_crowbar" },
    command = "jedi",
    max = 2,
    salary = 80,
    admin = 0,
    vote = true,
    category = "Combat Professions",
    allegiance = SWGRP.Allegiance.UNDERWORLD,
})
]]

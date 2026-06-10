--[[---------------------------------------------------------------------------
    Star Wars Galaxies RP - Global Configuration
---------------------------------------------------------------------------]]

SWGRP = SWGRP or {}
SWGRP.Config = SWGRP.Config or {}

local C = SWGRP.Config

-- Currency
C.CurrencyName       = "Credits"
C.CurrencySymbol     = "CR"
C.StartCredits       = CreateConVar( "swgrp_startcredits", "500", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.PaydayInterval     = CreateConVar( "swgrp_paydayinterval", "160", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.TaxEnabled         = CreateConVar( "swgrp_taxenabled", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.TaxRate            = CreateConVar( "swgrp_taxrate", "0.05", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.PropLimit          = CreateConVar( "swgrp_propcount", "100", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.MaxDoors           = CreateConVar( "swgrp_maxdoors", "20", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.SpawnAllowlistEnabled = CreateConVar( "swgrp_spawnallowlist", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )
-- Sandbox tools: 0 = disabled, 1 = everyone (DarkRP default), 2 = FAdmin Physgun/Toolgun privilege only
C.SandboxTools         = CreateConVar( "swgrp_sandbox_tools", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )

-- Economy
C.DoorCost           = 100
C.VehicleCost        = 1000
C.MinPrice           = 50
C.MaxPrice           = 50000
C.DropCreditLimit    = 5000
C.MaxCreditHarvesters = 2

-- Government
C.GovernorVote       = true
C.LockdownTime       = 300
C.LotteryTicketCost  = 100
C.MaxLaws            = 12

-- Law enforcement
C.WarrantTime        = 300
C.ArrestTime         = 120
C.WantedTime         = 600
C.BountyMin          = 200
C.BountyMax          = 50000

-- Chat ranges (units)
C.ChatRangeNormal    = 250
C.ChatRangeYell      = 550
C.ChatRangeWhisper   = 90
C.ChatRangeMe        = 250
C.ChatRangeAdvert    = 550

-- AFK
C.AFKTime            = 300
C.AFKDemote          = true

-- Demote vote
C.DemoteTime         = 60
C.DemoteVotesNeeded  = 0.66

-- Voteban
C.VoteBanTime        = 60
C.VoteBanVotesNeeded = 0.66

-- Hit contracts
C.HitMinPrice        = 500
C.HitMaxPrice        = 50000

-- Hunger
C.HungerEnabled      = CreateConVar( "swgrp_hungerenabled", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.HungerRate         = CreateConVar( "swgrp_hungerrate", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.HungerMax          = 100
C.HungerDamage       = 2
C.StarveDamage       = 5

-- Missions
C.MissionCooldown    = CreateConVar( "swgrp_missioncooldown", "120", FCVAR_ARCHIVE + FCVAR_REPLICATED )

-- Banking
C.BankTransferFee    = 0.02
C.MaxBankBalance     = 1000000

-- Factions
C.FactionMin         = -100
C.FactionMax         = 100

-- Profession XP
C.XPPerLevel         = 100
C.MaxProfessionLevel = 10

-- Crafting material limits
C.MaxMaterials       = 99

-- Contraband
C.ScanRange          = 200
C.ContrabandFine     = true

-- Jail positions (map-specific overrides via SWGRP.RegisterJailPos)
C.DefaultJailPos     = Vector( 0, 0, 0 )
C.DefaultJailAng     = Angle( 0, 0, 0 )
C.DefaultReleasePos  = Vector( 0, 0, 0 )

-- HUD colors (SWG amber terminal aesthetic)
C.HUDColorPrimary    = Color( 255, 180, 50 )
C.HUDColorSecondary  = Color( 200, 200, 200 )
C.HUDColorAccent     = Color( 80, 200, 255 )
C.HUDColorDanger     = Color( 255, 60, 60 )

-- New Life Rule
C.NLREnabled  = CreateConVar( "swgrp_nlr", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.NLRTime     = CreateConVar( "swgrp_nlrtime", "120", FCVAR_ARCHIVE + FCVAR_REPLICATED )
C.NLRDistance = 600

-- Adverts
C.AdvertCooldown = 5

-- Pocket
C.MaxPocket = 8

-- Keypads
C.KeypadCrackTime = 8

-- RP logging
C.LoggingEnabled = CreateConVar( "swgrp_logging", "1", FCVAR_ARCHIVE )

-- Disguise kit
C.DisguiseModels = {
	"models/player/group01/male_01.mdl",
	"models/player/group01/male_07.mdl",
	"models/player/group01/female_01.mdl",
	"models/player/group01/female_04.mdl",
	"models/player/group02/male_05.mdl",
}
C.DisguiseNames = {
	"Dock Worker", "Spaceport Vagrant", "Moisture Farmer", "Cargo Hauler",
	"Cantina Patron", "Trader", "Pilgrim", "Drifter",
}

-- Door groups configured after professions load (see modules/sh_doorgroups.lua)
C.DoorGroups = {}

-- FAdmin / spawn loadout (DarkRP-compatible keys on GM.Config)
C.DarkRPSkin = "Default"
C.DefaultWeapons = {
	"swgrp_keys",
	"weapon_physcannon",
	"gmod_camera",
	"gmod_tool",
	"weapon_physgun",
}
C.AdminWeapons = {
	"swgrp_admin_doortool",
	"swgrp_admin_buttontool",
	"swgrp_admin_jobspawntool",
}
C.AdminsCopWeapons = false

GM.Config = GM.Config or {}
GM.Config.DarkRPSkin = C.DarkRPSkin
GM.Config.DefaultWeapons = C.DefaultWeapons
GM.Config.AdminWeapons = C.AdminWeapons
GM.Config.AdminsCopWeapons = C.AdminsCopWeapons

-- Default laws
C.DefaultLaws = {
	"No murder or assault in civilian sectors.",
	"No unauthorized weapons in secure zones.",
	"Respect Imperial curfew during lockdown.",
	"Bounty hunters must present valid contracts.",
	"Smuggling is punishable by arrest.",
}

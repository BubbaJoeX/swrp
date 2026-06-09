# Star Wars Galaxies Roleplay (SWGRP)

A DarkRP-inspired Garry's Mod gamemode themed after **Star Wars Galaxies**. Built on Sandbox with modular Lua architecture, SQLite persistence, and a `custom/` extension folder (similar to DarkRP's modification addon pattern).

## Quick Start

1. Place `swgrp` in `garrysmod/gamemodes/`
2. Launch GMod → **Create Multiplayer Game**
3. Select gamemode **Star Wars Galaxies RP**
4. Configure server ConVars in the gamemode settings panel or via console

## Architecture

```
swgrp/
├── swgrp.txt                 # Gamemode manifest & ConVars
├── README.md                 # This file
├── gamemode/
│   ├── shared.lua            # Core loader (client + server)
│   ├── init.lua              # Server-only modules
│   ├── cl_init.lua           # Client-only modules
│   ├── config/
│   │   └── sh_config.lua     # Global configuration & ConVars
│   ├── libraries/
│   │   ├── sh_swgrp.lua      # Registration API (jobs, entities, etc.)
│   │   ├── sh_util.lua       # Utilities (doors, range chat, etc.)
│   │   ├── sh_player.lua     # Player meta extensions
│   │   ├── sh_network.lua    # Network string registry
│   │   ├── sh_hooks.lua      # Addon hook API
│   │   └── sv_database.lua   # SQLite persistence
│   ├── modules/              # Feature modules (see below)
│   ├── language/
│   │   └── sh_english.lua    # Localization strings
│   ├── vgui/                 # Custom VGUI panels
│   └── custom/               # Server owner extensions (not overwritten)
│       └── example_jobs.lua
└── entities/
    ├── entities/             # SENTs (harvesters, ATMs, etc.)
    └── weapons/              # SWEPs (keys, lockpick, batons)
```

## Registration API

| Function | Purpose |
|----------|---------|
| `SWGRP.RegisterJob(name, data)` | Define a profession |
| `SWGRP.RegisterCategory(data)` | F4 menu category |
| `SWGRP.RegisterEntity(class, data)` | Purchasable entity |
| `SWGRP.RegisterShipment(name, data)` | Weapon crate shipment |
| `SWGRP.RegisterAmmoType(name, data)` | Ammunition type |
| `SWGRP.RegisterChatCommand(cmd, data)` | Chat command |
| `SWGRP.RegisterDoorGroup(name, teams)` | Door access group |
| `SWGRP.RegisterJailPos(pos, ang)` | Jail spawn position |
| `SWGRP.RegisterRecipe(data)` | Crafting recipe |
| `SWGRP.RegisterMission(data)` | Mission terminal entry |
| `SWGRP.RegisterVehicle(data)` | Purchasable vehicle |
| `SWGRP.RegisterContraband(data)` | Contraband type |

## Professions (18)

| Category | Professions |
|----------|-------------|
| Civilians | Colonist, Refugee, Merchant, Artisan, Entertainer, Cantina Operator, Doctor |
| Combat | Smuggler, Bounty Hunter, Commando, Arms Dealer, Combat Medic |
| Imperial Forces | Stormtrooper, Imperial Officer, Security Commander, Planetary Governor |
| Rebel Alliance | Rebel Soldier, Rebel Pilot |

### Job Data Fields

```lua
SWGRP.RegisterJob("Example", {
    color = Color(255, 255, 255),
    model = {"models/player/group01/male_01.mdl"},
    description = "Job description shown in F4.",
    weapons = {"weapon_pistol"},
    command = "example",       -- Chat command: /example
    max = 4,                   -- 0 = unlimited
    salary = 50,               -- Credits per payday
    admin = 0,                 -- Minimum admin rank
    vote = false,              -- Requires player vote
    category = "Civilians",
    -- Special flags:
    governor = true,           -- Governor powers
    chief = true,              -- Can grant licenses
    stormtrooper = true,       -- Imperial security
    medic = true,              -- Can heal
    bountyhunter = true,       -- Collects bounties
    cook = true,               -- Food profession
    hobo = true,               -- Refugee class
    hasLicense = true,         -- Auto weapon permit
})
```

## Implemented Systems

### Economy
- **Credits (CR)** wallet with SQLite persistence
- **Payday** salary system with configurable interval
- **Imperial Tax** deducted from non-governor paychecks
- **Credit drops** via `/dropcredits` or `/moneydrop`
- **Death penalty** — 10% credits dropped on death
- **Credit Harvester** — passive income entity (SWG-themed money printer)

### Banking
- Separate **bank balance** from wallet credits
- **Galactic ATM** entity for deposit/withdraw/transfer
- Bank balance persisted in SQLite
- Commands: `/deposit`, `/withdraw`, `/balance`, `/transfer`

### Doors & Property
- Buy/sell map doors as structures
- Lock/unlock with **Structure Keys** SWEP
- Co-owner support (server-side)
- Door groups for Imperial/Cantina/Medical zones
- **Security Bypass** lockpick SWEP
- **Battering Ram** for warranted breaches

### Government
- **Planetary Governor** — laws, lockdown, agenda, lottery, broadcast
- Up to 12 planetary laws displayed on HUD
- **Imperial Lockdown** timed curfew
- **Lottery** ticket system every 10 minutes
- Governor agenda visible to government roles

### Law Enforcement
- **Wanted** system with timed expiry
- **Search warrants** for property breach
- **Arrest/detain** with jail positions
- **Weapon permits** — grant/revoke by officers
- **Stun Baton**, **Detention Baton**, **Release Baton**
- License check prevents unauthorized weapon pickup

### Bounty System
- Place contracts via `/hit` or F4 Bounties tab
- Bounty Hunters collect on target death
- Active bounties synced to clients

### Faction Standing (SWG-inspired)
- **Imperial**, **Rebel**, and **Underworld** reputation (-100 to +100)
- Actions shift standing (arrests, missions, contraband, scans)
- Standing affects mission availability and Imperial scan outcomes
- Displayed on HUD

### Profession XP & Leveling
- Per-profession experience earned from missions, crafting, paydays
- 10 levels per profession with XP thresholds
- Level displayed on HUD and F4 status tab
- Persisted in SQLite

### Hunger System
- Hunger depletes over time (refugees lose faster)
- **Ration Dispenser** and cantina food restore hunger
- Low hunger causes damage; starvation possible
- `/eat` to consume held rations

### Missions
- **Mission Terminal** entity and F4 Missions tab
- Types: Courier, Elimination, Collection, Imperial Patrol, Rebel Sabotage
- Rewards: credits + profession XP + faction standing
- One active mission per player

### Crafting
- **Artisan** and related professions craft from materials
- Material inventory (metal, chemical, fiber, electronics)
- Recipes registered via `SWGRP.RegisterRecipe()`
- F4 Crafting tab and `/craft` command

### Contraband & Smuggling
- Smugglers can acquire contraband items
- Imperial `/scan` detects nearby contraband
- Detection triggers wanted status or fines
- Contraband types: spice, weapons, data chips

### Vehicles
- Purchasable vehicles in F4 Vehicles tab
- Speeder (jeep), Transport (van), Imperial Patrol (airboat)
- Job-restricted entries

### Social & Chat
| Command | Description |
|---------|-------------|
| `/ooc` `/a` | Out of character global |
| `/me` | Roleplay action |
| `/advert` | Galactic advertisement |
| `/pm [name] [msg]` | Private message |
| `/yell` `/y` | Yell (long range) |
| `/whisper` `/w` | Whisper (short range) |
| `/g` | Profession group chat |
| `/radio` `/channel` | Category radio |
| `/broadcast` | Governor broadcast |
| `/dropcredits [amt]` | Drop credits |
| `/wanted [name] [reason]` | Mark wanted |
| `/unwanted [name]` | Clear wanted |
| `/warrant [name] [reason]` | Search warrant |
| `/givelicense [name]` | Grant weapon permit |
| `/takelicense [name]` | Revoke permit |
| `/hit [name] [price]` | Bounty contract |
| `/demote [name]` | Start demote vote |
| `/lockdown` | Start lockdown |
| `/unlockdown` | End lockdown |
| `/addlaw [text]` | Add planetary law |
| `/removelaw [n]` | Remove law by index |
| `/agenda [text]` | Set governor agenda |
| `/lottery` | Buy lottery ticket |
| `/heal` | Medic heal target |
| `/deposit [amt]` | Deposit to bank |
| `/withdraw [amt]` | Withdraw from bank |
| `/balance` | Check bank balance |
| `/transfer [name] [amt]` | Bank transfer |
| `/mission` | Open mission list |
| `/craft [recipe]` | Craft item |
| `/scan` | Imperial contraband scan |
| `/contraband` | View contraband |

### UI
| Key | Panel |
|-----|-------|
| F1 | Galactic Information Network (MOTD) |
| F4 | Profession Terminal (jobs, shop, missions, craft, bank, vehicles) |
| F3 | Mouse cursor |
| TAB | Galactic Census scoreboard |

### Other
- **AFK detection** with government auto-demote
- **Demote vote** system
- **Prop limit** and ownership protection
- **Job vote** for restricted professions
- **SQLite** auto-save every 5 minutes
- **Hook API** for addon integration

## Server ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `swgrp_startcredits` | 500 | First-join credits |
| `swgrp_paydayinterval` | 160 | Seconds between paydays |
| `swgrp_taxenabled` | 1 | Enable Imperial tax |
| `swgrp_taxrate` | 0.05 | Tax fraction |
| `swgrp_propcount` | 100 | Max props per player |
| `swgrp_maxdoors` | 20 | Max owned doors |
| `swgrp_hungerenabled` | 1 | Enable hunger system |
| `swgrp_hungerrate` | 1 | Hunger loss per tick |
| `swgrp_missioncooldown` | 120 | Seconds between missions |

## Map Setup

Register jail positions in `gamemode/custom/your_map.lua`:

```lua
-- rp_starwars_mos_eisley example
SWGRP.RegisterJailPos(Vector(100, 200, 64), Angle(0, 90, 0))
SWGRP.RegisterJailPos(Vector(120, 200, 64), Angle(0, 90, 0))
```

## Customization

Add files to `gamemode/custom/` (loaded after core registrations):

```lua
-- custom/my_jobs.lua
SWGRP.RegisterJob("Jedi Knight", { ... })
```

Do **not** edit core module files directly — use `custom/` to survive updates.

## Addon Hook API

```lua
-- In an addon:
hook.Add("SWGRPCanChangeJob", "MyAddon", function(ply, teamId)
    if some_condition then return false, "Blocked reason" end
end)

hook.Add("SWGRPPlayerPaid", "MyAddon", function(ply, salary, tax)
    -- Called on payday
end)

hook.Add("SWGRPPlayerArrested", "MyAddon", function(target, actor)
end)

hook.Add("SWGRPMissionCompleted", "MyAddon", function(ply, mission, reward)
end)
```

Available hooks: `SWGRPCanChangeJob`, `SWGRPJobChanged`, `SWGRPPlayerPaid`, `SWGRPPlayerArrested`, `SWGRPPlayerUnarrested`, `SWGRPPlayerWanted`, `SWGRPPlayerBoughtDoor`, `SWGRPPlayerSoldDoor`, `SWGRPMissionCompleted`, `SWGRPMissionAccepted`, `SWGRPCraftedItem`, `SWGRPContrabandFound`, `SWGRPPlayerDeposited`, `SWGRPPlayerWithdrew`.

## Entities

| Class | Description |
|-------|-------------|
| `swgrp_dropped_credits` | Physical credit pickup |
| `swgrp_credit_harvester` | Passive credit generator |
| `swgrp_ration_dispenser` | Food/hunger restore |
| `swgrp_med_station` | Health and armor restore |
| `swgrp_ammo_crate` | Ammunition resupply |
| `swgrp_armor_station` | Armor repair |
| `swgrp_shipment` | Weapon crate |
| `swgrp_galactic_atm` | Banking terminal |
| `swgrp_mission_terminal` | Accept missions |
| `swgrp_tipjar` | Credit tips for entertainers |
| `swgrp_holo_sign` | Customizable RP sign |

## Weapons

| Class | Description |
|-------|-------------|
| `swgrp_keys` | Buy/sell/lock doors |
| `swgrp_lockpick` | Bypass door locks |
| `swgrp_batteringram` | Warranted door breach |
| `swgrp_arrest_baton` | Detain players |
| `swgrp_unarrest_baton` | Release detainees |
| `swgrp_stun_baton` | Stun players |

## Not Yet Implemented (vs full DarkRP)

- FAdmin / FPP integration
- Pocket inventory system
- ULX command bridge
- Model selector in F4
- Advanced lockpick minigame UI
- Door map entity configuration
- Kidnapping / zip ties
- Voteban
- Letter entity mail system
- Full CPPI/FPP parity

## Credits

Built for Garry's Mod using the [Gamemode Creation](https://wiki.facepunch.com/gmod/Gamemode_Creation) framework, derived from Sandbox.

# Galaxies RP (SWGRP)

**Galaxies RP** — a DarkRP-inspired Garry's Mod gamemode themed after **Star Wars Galaxies**. Built on Sandbox with a modular Lua architecture, SQLite persistence, bundled **FAdmin** administration, **CSV-driven content** (jobs, entities, shipments, foods, spices, ammo, vehicles), and a `custom/` extension folder (similar to DarkRP's modification addon pattern).

> **New to SWGRP?** This README is the reference overview. For step-by-step installation, dedicated-server deployment, content authoring, gameplay walkthroughs, admin tools, and troubleshooting, see **[GUIDE.md](GUIDE.md)**.

## Quick Start

1. Place the `swgrp` folder in `garrysmod/gamemodes/`
2. Launch GMod → **Create Multiplayer Game** (or start a dedicated server)
3. Select gamemode **Galaxies RP**
4. Configure server ConVars in the gamemode settings panel or via console
5. (Optional) Edit `swgrp/data/*.csv` to add your own jobs, structures, shipments, ammo, and vehicles — no Lua required

> ⚠️ If the server boots into **Sandbox** instead of SWGRP, a Lua error occurred during load. Launch with `-condebug` and check `garrysmod/console.log` for the first red error. See [GUIDE.md → Troubleshooting](GUIDE.md#troubleshooting).

## Dedicated Server (summary)

| Component | How to deploy |
|-----------|----------------|
| **Gamemode (code + CSVs)** | Git clone into `garrysmod/gamemodes/swgrp/` — **not** Workshop |
| **Content (models, maps, SWEPs)** | Steam Workshop **collection** + `resource.AddWorkshop()` per addon |
| **Loading screen** | `deploy/install_loadscreen.ps1` + `sv_loadingurl` (see `deploy/server.cfg.example`) |

Full walkthrough: **[GUIDE.md → Dedicated Server Deployment](GUIDE.md#dedicated-server-deployment)**.

## Architecture

```
swgrp/
├── swgrp.txt                 # Gamemode manifest, ConVars & loadscreen URL
├── README.md                 # This file (reference overview)
├── GUIDE.md                  # Full setup / content / gameplay / admin guide
├── loadscreen/               # Galaxies RP loading screen (HTML)
├── deploy/                   # Dedicated-server helpers
│   ├── server.cfg.example    # Example hostname, gamemode, loading URL
│   ├── workshop.lua.example  # resource.AddWorkshop() template
│   └── install_loadscreen.ps1
├── data/                     # CSV content (master copies)
│   ├── jobs.csv              # Professions
│   ├── entities.csv          # Purchasable structures / equipment
│   ├── shipments.csv         # Weapon crates
│   ├── foods.csv             # Ration terminal items
│   ├── spices.csv            # Spice terminal craftables
│   ├── ammo.csv              # Ammunition types
│   └── vehicles.csv          # Purchasable vehicles
├── gamemode/
│   ├── shared.lua            # Core loader (client + server)
│   ├── init.lua              # Server-only module loader
│   ├── cl_init.lua           # Client-only module loader
│   ├── config/
│   │   └── sh_config.lua     # Global configuration & ConVars
│   ├── libraries/
│   │   ├── sh_swgrp.lua      # Registration API (jobs, entities, etc.)
│   │   ├── sh_content_loader.lua # CSV parser + loader (swgrp_reloadcontent)
│   │   ├── sh_modelmap.lua   # Model path resolution for previews
│   │   ├── sh_util.lua       # Utilities (doors, range chat, etc.)
│   │   ├── sh_player.lua     # Player meta extensions
│   │   ├── sh_network.lua    # Network string registry
│   │   ├── sh_hooks.lua      # Addon hook API
│   │   ├── sh_fadmin*.lua    # Bundled FAdmin compatibility shims
│   │   ├── mysqlite/         # FAdmin's MySQLite (SQLite fallback)
│   │   └── sv_database.lua   # SQLite persistence
│   ├── modules/              # Feature modules (sv_/cl_/sh_ per realm)
│   ├── language/
│   │   └── sh_english.lua    # Localization strings
│   ├── vgui/
│   │   └── swgrp_terminal.lua # Shared terminal/menu UI toolkit
│   └── custom/               # Server owner extensions (not overwritten)
│       ├── example_jobs.lua  # Lua extension example (skipped by loader)
│       └── data/             # Optional CSV overrides (appended to master)
└── entities/
    ├── entities/             # SENTs (harvesters, ATMs, terminals, etc.)
    └── weapons/              # SWEPs (keys, lockpick, batons, zip tie, etc.)
```

> The `gamemode/custom/` folder is the safe place for your changes. Files there load **after** core registration, and anything named `example*` is intentionally skipped by the loader.

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

## CSV Content (recommended)

Most content is defined in plain CSV files under `swgrp/data/` and loaded at startup by `sh_content_loader.lua`. This is the easiest way to add jobs/shop items without writing Lua. Server-owner overrides can be placed in `gamemode/custom/data/` (rows are **appended** to the master files).

| File | Defines | Key columns |
|------|---------|-------------|
| `jobs.csv` | Professions | `name, command, category, allegiance, color, models, description, weapons, salary, max, admin, vote, flags` |
| `entities.csv` | Purchasable structures | `class, name, model, price, max, cmd, allowed, category` |
| `shipments.csv` | Weapon crates | `name, model, preview_model, entities, price, amount, separate, price_separate, allowed, category` |
| `foods.csv` | Ration terminal consumables | `name, model, price, hunger, health, allowed, category` |
| `spices.csv` | Spice terminal craftables | `name, model, price, hunger, health, allowed, category` |
| `ammo.csv` | Ammunition | `name, ammo_type, model, price, amount, allowed, category` |
| `vehicles.csv` | Vehicles | `name, model, class, script, price, allowed, category` |

Formatting rules:
- **Lists** (`models`, `weapons`, `entities`) are `|`-separated.
- **`allowed`** is a quoted, comma-separated list of profession `command`s, or `*` / blank for everyone.
- **`color`** is `R G B` (space or comma separated).
- **`flags`** is a space/comma list: `hobo cook medic doctor bountyhunter hasLicense governor officer stormtrooper commander chief whitelist disguise captain`.
- Lines starting with `#` are comments. Reload at runtime (superadmin) with `swgrp_reloadcontent`.

Full column-by-column reference and examples: **[GUIDE.md → Authoring Content](GUIDE.md#authoring-content-csv)**.

## Professions (19)

| Category | Professions |
|----------|-------------|
| Civilians | Colonist, Refugee, Merchant, Artisan, Entertainer, Cantina Operator, Doctor |
| Combat Professions | Smuggler, Bounty Hunter, Commando, Arms Dealer, Combat Medic |
| Imperial Forces | Stormtrooper Captain, Stormtrooper, Imperial Officer, Security Commander, Planetary Governor |
| Rebel Alliance | Rebel Soldier, Rebel Pilot |

> Professions ship in `data/jobs.csv` — edit that file (or add rows in `custom/data/jobs.csv`) to change the roster. The Lua `SWGRP.RegisterJob` API below is still available for advanced/scripted jobs.

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
- **Entity ownership** — purchased structures are owned; only the owner (or admins) may physgun, grav gun, tool, or pocket them

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
| `/pocket` | Store aimed equipment or active weapon |
| `/droppocket` | Open pocket menu |

### Pocket
- **8-slot** inventory for weapons and SWGRP entities (shipments, spice, keypads, etc.)
- **T** — toggle pocket menu · **Alt+T** — quick-store what you're aiming at
- Drag-and-drop between slots; double-click a slot to drop
- Full item state preserved (weapon ammo, shipment contents, harvester credits, etc.)

### UI
| Key | Panel |
|-----|-------|
| F1 | Galactic Information Network (MOTD / help) |
| F2 | Manage / buy the structure (door) you are looking at |
| F3 | Colony Datapad — missions, crafting, status, banking, governance, bounties |
| F4 | Galactic Profession Terminal — professions, structures, vehicles, shipments, ammo |
| TAB | Galactic Census scoreboard |
| T | Pocket inventory |
| Alt+T | Quick-pocket |

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
| `swgrp_hungerrate` | 1 | Hunger loss per tick (every 30s) |
| `swgrp_missioncooldown` | 120 | Seconds between missions |
| `swgrp_sandbox_tools` | 1 | Sandbox tools: 0=off, 1=everyone, 2=FAdmin privilege only |

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
| `swgrp_keypad` | Security keypad linked to a door |
| `swgrp_letter` | Galactic letter / mail entity |
| `swgrp_spice` | Crafted spice pickup |
| `swgrp_spice_terminal` | Spice storage / crafting terminal |

## Weapons

| Class | Description |
|-------|-------------|
| `swgrp_keys` | Buy/sell/lock doors |
| `swgrp_lockpick` | Bypass door locks |
| `swgrp_batteringram` | Warranted door breach |
| `swgrp_arrest_baton` | Detain players |
| `swgrp_unarrest_baton` | Release detainees |
| `swgrp_stun_baton` | Stun players |
| `swgrp_zip_tie` | Restrain a target (underworld) |
| `swgrp_disguise` | Conceal identity (smuggler) |
| `swgrp_keypad_cracker` | Crack security keypads (underworld) |
| `swgrp_admin_doortool` | Admin door configuration (admin only) |
| `swgrp_admin_buttontool` | Admin map button ownership (admin only) |
| `swgrp_admin_jobspawntool` | Admin per-job spawn points (admin only) |

## Not Yet Implemented (vs full DarkRP)

- ULX/ULib command bridge (SWGRP ships **FAdmin** instead)
- Full CPPI/FPP parity (basic prop/entity ownership and limits only)
- Automated Workshop collection sync (maintain `workshop.lua` manually)

## Credits

Built for Garry's Mod using the [Gamemode Creation](https://wiki.facepunch.com/gmod/Gamemode_Creation) framework, derived from Sandbox.

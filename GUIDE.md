# SWGRP — Complete Server & Content Guide

This is the full, practical guide to running, configuring, extending, and troubleshooting **Galaxies RP (SWGRP)**. For a quick feature overview see [README.md](README.md).

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Dedicated Server Deployment](#dedicated-server-deployment)
4. [First Boot & Verifying the Gamemode Loaded](#first-boot)
5. [Server Configuration (ConVars)](#server-configuration)
6. [Controls & Menus](#controls--menus)
7. [Gameplay Guide](#gameplay-guide)
8. [Authoring Content (CSV)](#authoring-content-csv)
9. [Custom Lua Extensions](#custom-lua-extensions)
10. [Map Setup](#map-setup)
11. [Administration](#administration)
12. [Persistence & Database](#persistence--database)
13. [Hook API Reference](#hook-api-reference)
14. [Troubleshooting](#troubleshooting)
15. [FAQ](#faq)

---

## Overview

SWGRP is a DarkRP-inspired, Star Wars Galaxies–themed roleplay gamemode built on Sandbox. Key design points:

- **Modular Lua** — features live in `gamemode/modules/` split by realm (`sv_` server, `cl_` client, `sh_` shared).
- **CSV-driven content** — jobs, structures, shipments, ammo, and vehicles are defined in `data/*.csv`; no Lua needed for routine content.
- **SQLite persistence** — credits, bank, profession XP, faction standing, doors, and more are saved locally and auto-saved every 5 minutes.
- **Bundled FAdmin** — administration, scoreboard, and notifications ship in-box; MySQLite falls back to SQLite automatically.
- **`custom/` extension folder** — your changes survive updates by living outside the core files.

---

## Installation

### Listen server / singleplayer (testing)

1. Copy the `swgrp` folder into `garrysmod/gamemodes/`.
   Final path: `garrysmod/gamemodes/swgrp/`.
2. Start GMod → **Create Multiplayer Game**.
3. Pick a map (any map works; Star Wars RP maps are ideal).
4. Set **Gamemode** to **Galaxies RP** and start.

### Dedicated server (quick)

1. Deploy the gamemode via **git** into `garrysmod/gamemodes/swgrp/` (see [Dedicated Server Deployment](#dedicated-server-deployment)).
2. Set `+gamemode swgrp +map rp_yourmap` in your launch script.
3. Add `-condebug` for diagnostics (`garrysmod/console.log`).

### Content (models/materials)

Many professions and shop items reference custom models (stormtrooper bodies, SW props, E-11 SWEPs, food/spice models, etc.). Mount the relevant **Workshop addons** on **both** the server and clients. If a model is missing, previews fall back to default HL2 models — the gamemode still loads, but pink/error models mean a missing addon.

---

## Dedicated Server Deployment

Galaxies RP splits deployment into two parts:

| What | Where | How |
|------|-------|-----|
| **Gamemode** (Lua, CSVs, entities) | `garrysmod/gamemodes/swgrp/` | **Git** clone / pull — do **not** publish SWGRP to Workshop |
| **Content** (models, maps, SWEPs) | Steam Workshop | One **Workshop collection** + `workshop.lua` |
| **Loading screen** | `garrysmod/html/swgrp/` or hosted URL | `sv_loadingurl` |

### 1. Deploy the gamemode (git)

On your server:

```bash
cd garrysmod/gamemodes
git clone <your-repo-url> swgrp
# Updates:
cd swgrp && git pull
```

Launch with:

```cfg
gamemode swgrp
sv_defaultgamemode swgrp
+gamemode swgrp +map rp_yourmap
```

See `deploy/server.cfg.example` for a fuller template (`hostname`, loading URL, etc.).

### 2. Workshop collection (content only)

A Workshop **collection** is a Steam playlist of addon IDs. It does **not** bundle files into one download — the server and each client still fetch every addon separately.

**Create the collection:**

1. Open [Garry's Mod Workshop](https://steamcommunity.com/app/4000/workshop/) → **Browse → Collections → Create Collection**.
2. Name it (e.g. **Galaxies RP — Content**).
3. Set visibility to **Public** or **Unlisted** (private collections won't work with `host_workshop_collection`).
4. Add every addon your server needs — models, weapons, maps, props referenced in your CSVs.
5. **Do not add SWGRP** — the gamemode comes from git.

**Find the collection ID** from the URL:

```
https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890
```

**Server-side** — in `server.cfg` or your launch line:

```cfg
host_workshop_collection 1234567890
```

Or:

```bat
srcds.exe -console +gamemode swgrp +map rp_yourmap +host_workshop_collection 1234567890 -authkey YOUR_STEAM_WEB_API_KEY
```

You need a [Steam Web API key](https://steamcommunity.com/dev/apikey) for Workshop downloads on dedicated servers.

**Client downloads** — the collection mounts addons on the **server** at startup. To force **joining players** to download the same addons, copy `deploy/workshop.lua.example` to `garrysmod/lua/autorun/server/workshop.lua` and list **each addon ID** (not the collection ID):

```lua
resource.AddWorkshop( "111111111" ) -- Map
resource.AddWorkshop( "222222222" ) -- SW models
resource.AddWorkshop( "333333333" ) -- SW weapons
```

Keep `workshop.lua` in sync whenever you add/remove addons from the collection.

**Tips:**

- You can only use **one** collection ID on the server — merge all content into a single collection.
- Test from a clean GMod install (or alt account) to verify all addons download before going live.
- Mount **Counter-Strike: Source** content separately if you rely on CS:S props (`+host_workshop_collection` does not replace CSS mount).

### 3. Loading screen

Galaxies RP ships a custom HTML loading screen in `loadscreen/index.html` (amber terminal theme, server name, map, download progress).

**Local asset (good for LAN / dev):**

```powershell
# From the swgrp gamemode folder:
.\deploy\install_loadscreen.ps1
```

This copies the HTML to `garrysmod/html/swgrp/loadscreen.html`. Then in `server.cfg`:

```cfg
sv_loadingurl "asset://garrysmod/html/swgrp/loadscreen.html"
```

If `sv_loadingurl` is empty, the gamemode auto-applies this asset path on startup when the file exists.

**Public servers (recommended):** host `loadscreen/index.html` on any static URL and set:

```cfg
sv_loadingurl "https://your-domain.com/galaxiesrp/loadscreen.html?mapname=%m&steamid=%s"
```

`%m` = map name, `%s` = joining player's SteamID64.

### 4. Recommended server layout

```
garrysmod/
├── gamemodes/swgrp/              ← git (code, CSVs, loadscreen source, deploy/)
├── lua/autorun/server/
│   └── workshop.lua              ← resource.AddWorkshop() per addon
├── html/swgrp/
│   └── loadscreen.html           ← installed by install_loadscreen.ps1
└── cfg/server.cfg                ← hostname, gamemode, collection, loading URL
```

---

## First Boot

When SWGRP loads correctly you will see, in the server console:

```
[SWGRP] CSV content loaded: 19 jobs, 11 entities, 0 shipments, 0 ammo, 0 vehicles
[SWGRP] Server modules loaded.
[SWGRP] Star Wars Galaxies Roleplay initialized.
```

The gamemode title shown in menus is **Galaxies RP** (`swgrp.txt`).

To confirm in-game, open the console and run:

```
lua_run print(SWGRP and "SWGRP loaded" or "NOT loaded")
```

If it prints `NOT loaded` and you are in Sandbox, the gamemode failed to load — jump to [Troubleshooting](#troubleshooting).

---

## Server Configuration

Configure via the **Create Multiplayer Game** settings panel, or set ConVars in `server.cfg` / console. All values persist as ConVars.

| ConVar | Default | Description |
|--------|---------|-------------|
| `swgrp_startcredits` | 500 | Credits granted on a player's first join |
| `swgrp_paydayinterval` | 160 | Seconds between salary paydays |
| `swgrp_taxenabled` | 1 | Governor collects Imperial tax on paychecks |
| `swgrp_taxrate` | 0.05 | Fraction of salary taken as tax (0.05 = 5%) |
| `swgrp_propcount` | 100 | Max props per player |
| `swgrp_maxdoors` | 20 | Max structure doors a player may own |
| `swgrp_hungerenabled` | 1 | Enable the hunger system |
| `swgrp_hungerrate` | 1 | Hunger lost per tick (tick = every 30s) |
| `swgrp_missioncooldown` | 120 | Seconds between completing missions |
| `swgrp_sandbox_tools` | 1 | Sandbox tools: `0` off, `1` everyone (physgun/toolgun/gravgun), `2` FAdmin privilege only |

Example `server.cfg` snippet:

```cfg
swgrp_startcredits 1000
swgrp_paydayinterval 300
swgrp_taxrate 0.10
swgrp_sandbox_tools 2
```

---

## Controls & Menus

| Key | Function |
|-----|----------|
| **F1** | Galactic Information Network — MOTD / help |
| **F2** | Manage or buy the **structure (door)** you are looking at |
| **F3** | **Colony Datapad** — Missions, Crafting, Status, Banking, Governance, Bounties |
| **F4** | **Galactic Profession Terminal** — Professions, Structures, Vehicles, Shipments, Ammunition |
| **TAB** | Galactic Census scoreboard |
| **T** | Toggle **Pocket** inventory menu |
| **Alt+T** | **Quick-pocket** — store aimed equipment or your active weapon |

- **F4** is for *becoming* a profession and *buying* things (shop).
- **F3** is for *doing* things in your role (missions, crafting, banking, governance, bounties).
- Door management is context-sensitive: look at a door and press **F2**.
- **Pocket** also accepts `/pocket`, `/droppocket`, and drag-and-drop in the 8-slot menu.

---

## Gameplay Guide

### Choosing a profession
Open **F4 → Professions**, pick a faction on the left rail (Neutral / Imperial / Rebel / Underworld), select a job, then **Assume Profession**. If a job has multiple models you'll get an appearance picker. Restricted jobs may require a **vote** or a **whitelist**.

### Economy
- You earn **salary** every payday (`swgrp_paydayinterval`). Non-governors pay **Imperial tax** if enabled.
- Carry **wallet credits**; on death you drop ~10% as pickup-able credits.
- `/give [amount]` hands credits to the player you're looking at. `/dropcredits [amount]` drops them on the ground.
- The **Credit Harvester** structure generates passive income for its owner.

### Banking
Wallet and **bank** balances are separate; bank credits are safe on death. Use the **Galactic ATM** structure or the **F3 → Banking** tab.
- `/deposit [amt]`, `/withdraw [amt]`, `/balance`, `/transfer [name] [amt]`.
- Deposits respect the max bank balance — overflow is returned to your wallet rather than lost.

### Doors & structures
- Look at a door and press **F2** to buy, sell, lock/unlock, set a title, add co-owners, or set a structure flag.
- Console equivalents: `swgrp_buydoor`, `swgrp_selldoor`, `swgrp_toggledoor`.
- **Structure Keys** SWEP locks/unlocks owned doors. **Security Keypad** entity can control a door; the **Keypad Cracker** (underworld) breaks into them.
- **Security Bypass (lockpick)** and **Battering Ram** (warranted breach) provide forced entry.

### Law enforcement (Imperial)
Officer roles (Stormtrooper, Officer, Commander, Captain) carry batons and keys.
- `/wanted [name] [reason]`, `/unwanted [name]`, `/warrant [name] [reason]`.
- `/givelicense [name]`, `/takelicense [name]` — weapon permits. Unpermitted players can't pick up restricted weapons.
- **Arrest Baton** detains (sends to a jail position), **Release Baton** frees, **Stun Baton** stuns. All are melee-range only.
- `/scan` detects nearby **contraband**.

### Governor
The **Planetary Governor** leads the colony:
- `/lockdown` / `/unlockdown` — timed Imperial curfew (HUD banner).
- `/addlaw [text]`, `/removelaw [n]` — planetary laws (HUD list).
- `/agenda [text]` — agenda shown to government roles.
- `/broadcast` — galaxy-wide on-screen advert.
- Governance actions are also available in **F3 → Governance**.

### Smuggling & contraband
Underworld roles (Smuggler, etc.) can acquire **contraband** (spice, illegal weapons, data chips). Carrying it risks detection by Imperial `/scan`. The **Disguise Kit** conceals identity.

**Pocket** — 8-slot inventory for weapons and SWGRP entities. Press **T** for the menu, **Alt+T** to quick-store, or use `/pocket` / `/droppocket`. Drag between slots; double-click to drop. Only **your own** purchased/deployed entities can be pocketed (admins bypass ownership checks).

**Spice** — craft at a **Spice Storage Terminal** (`swgrp_spice_terminal`); pickups spawn as world entities (`swgrp_spice`).

### Structures & ownership
Purchased equipment (F4 **Equipment** tab, shipments, spice crafts, etc.) assigns an **owner**. Only that owner (or admins) may **physgun**, **grav gun**, **toolgun**, or **pocket** the entity. Sandbox-spawned props you place still get owner protection via `PlayerSpawnedProp`.

### Missions
Accept from **F3 → Missions** or a **Mission Terminal** structure. Types include Courier, Elimination, Collection, Imperial Patrol, and Rebel Sabotage. Rewards: credits + profession XP + faction standing. One active mission at a time; cooldown set by `swgrp_missioncooldown`.

### Crafting & materials
Artisan-type roles gather **materials** (metal, chemical, fiber, electronics) and craft via **F3 → Crafting** or `/craft [recipe]`. Recipes are registered with `SWGRP.RegisterRecipe`.

### Faction standing
Three reputations — **Imperial**, **Rebel**, **Underworld** (−100…+100). Arrests, missions, contraband, and scans shift them. Standing gates some missions and Imperial scan outcomes. Visible on the HUD and **F3 → Status**.

### Profession XP & leveling
Working, missions, crafting, and paydays grant per-profession XP across 10 levels. Level shows on the HUD and Status tab and persists in SQLite.

### Hunger
If enabled, hunger drains over time (Refugees faster). Eat with `/eat`, the **Ration Dispenser**, or cantina food. Starvation deals damage.

### Bounties
Place a contract via `/hit [name] [price]` or **F3 → Bounties**. Bounty Hunters collect on the target's death.

### New Life Rule (NLR)
After respawning, stay away from your death location for the NLR period; the gamemode finds you a clear spot and prevents immediate return.

---

## Authoring Content (CSV)

The fastest way to add content. Master files live in `swgrp/data/`. To override/extend without touching the master files, put same-named files in `gamemode/custom/data/` — their rows are **appended**.

General rules for every file:
- The **first non-comment line is the header row** (column names). Column order is flexible; names matter (case-insensitive).
- Lines beginning with `#` are comments and are ignored.
- Wrap any field containing a comma in **double quotes** (`"a,b,c"`); use `""` for a literal quote.
- **Lists** use `|` (pipe): `models`, `weapons`, `entities`.
- **`allowed`** = quoted, comma-separated profession `command`s, or `*`/blank = everyone.
- **`color`** = `R G B` (spaces or commas).
- Reload at runtime as a superadmin: `swgrp_reloadcontent` (rebuilds catalogs and updates job models live).

### `jobs.csv`

`name,command,category,allegiance,color,models,description,weapons,salary,max,admin,vote,flags`

| Column | Type | Notes |
|--------|------|-------|
| `name` | text | Display name (required) |
| `command` | text | Chat command + identifier, lowercase (required, unique). `/command` joins the job; also exposes `TEAM_<COMMAND>` |
| `category` | text | Tab grouping (e.g. `Civilians`, `Imperial Forces`) |
| `allegiance` | enum | `NEUTRAL`, `IMPERIAL`, `REBEL`, `UNDERWORLD` |
| `color` | `R G B` | Job color |
| `models` | list `|` | One or more player models; multiple enables the appearance picker |
| `description` | text | Shown in F4 |
| `weapons` | list `|` | Weapon classes given on spawn |
| `salary` | int | Credits per payday (default 45) |
| `max` | int | Slot cap; `0` = unlimited |
| `admin` | int | Minimum admin rank (0 = anyone) |
| `vote` | bool | `1`/`true` requires a colony vote to join |
| `flags` | list (space/comma) | Special abilities (see below) |

**Job flags:** `hobo`, `cook`, `medic`, `doctor`, `bountyhunter`, `hasLicense`, `governor`, `officer`, `stormtrooper`, `commander`, `chief`, `whitelist`, `disguise`, `captain`.

Example row:
```csv
Jedi Sentinel,sentinel,Combat Professions,REBEL,80 140 255,models/player/group03/male_07.mdl|models/player/group03/male_08.mdl,"A guardian of the old ways.",weapon_crowbar,90,2,0,1,
```

### `entities.csv`

`class,name,model,price,max,cmd,allowed,category`

| Column | Notes |
|--------|-------|
| `class` | SENT class to spawn (required) |
| `name` | Display name (required) |
| `model` | World/preview model |
| `price` | Cost in credits |
| `max` | Max owned per player (0 = unlimited) |
| `cmd` | Optional buy chat command |
| `allowed` | `"job1,job2"` or `*` |
| `category` | F4 grouping |

### `shipments.csv`

`name,model,preview_model,entities,price,amount,separate,price_separate,allowed,category`

| Column | Notes |
|--------|-------|
| `name` | Crate name (required) |
| `model` | Crate world model (defaults to an item crate) |
| `preview_model` | Optional model shown in the F4 preview |
| `entities` | `|`-separated weapon classes the crate contains (required) |
| `price` | Full-crate price |
| `amount` | Items per crate |
| `separate` | `1` to allow single-item purchase |
| `price_separate` | Single-item price (only used when `separate` = 1) |
| `allowed` | Restriction list or `*` |
| `category` | F4 grouping |

> The shop refuses single-item purchases on crates where `separate` is not set, so leaving `price_separate` blank can't be exploited for free items.

### `ammo.csv`

`name,ammo_type,model,price,amount,allowed,category`

| Column | Notes |
|--------|-------|
| `name` | Display name |
| `ammo_type` | GMod ammo id (`pistol`, `smg1`, `ar2`, `buckshot`, …) |
| `model` | Preview model |
| `price` | Cost |
| `amount` | Rounds given |
| `allowed` | Restriction list or `*` |
| `category` | F4 grouping |

### `vehicles.csv`

`name,model,class,script,price,allowed,category`

| Column | Notes |
|--------|-------|
| `name` | Display name |
| `model` | Vehicle model |
| `class` | `prop_vehicle_jeep`, `prop_vehicle_airboat`, etc. |
| `script` | Path under `scripts/vehicles/` |
| `price` | Cost |
| `allowed` | Restriction list or `*` |
| `category` | F4 grouping |

### `foods.csv`

Ration terminal consumables (instantly consumed on purchase at a **Ration Terminal**).

`name,model,price,hunger,health,allowed,category`

| Column | Notes |
|--------|-------|
| `name` | Display name |
| `model` | World/preview model |
| `price` | Cost in credits |
| `hunger` | Hunger restored |
| `health` | HP restored |
| `allowed` | Profession commands or `*` |
| `category` | Grouping (Food, Drink, Snack, …) |

### `spices.csv`

Spice terminal craftables (spawn a physical `swgrp_spice` pickup in-world).

Same columns as `foods.csv`. Craft at a **Spice Storage Terminal** while standing nearby.

### Override example

`gamemode/custom/data/jobs.csv` (only the rows you want to add — include a header row):
```csv
name,command,category,allegiance,color,models,description,weapons,salary,max,admin,vote,flags
Hutt Enforcer,enforcer,Combat Professions,UNDERWORLD,150 120 40,models/player/group03/male_09.mdl,"Muscle for hire.",weapon_pistol|swgrp_zip_tie,70,3,0,0,
```

---

## Custom Lua Extensions

Use `gamemode/custom/` for scripted content that CSV can't express (recipes, missions, complex jobs, map config). Files load **after** core registration; anything named `example*` is skipped.

```lua
-- gamemode/custom/my_content.lua
SWGRP.RegisterJob( "Jedi Knight", {
    color       = Color( 50, 100, 255 ),
    model       = { "models/player/kleiner.mdl" },
    description = "Force-sensitive guardian of peace.",
    weapons     = { "weapon_crowbar" },
    command     = "jedi",
    max         = 2,
    salary      = 80,
    vote        = true,
    category    = "Combat Professions",
    allegiance  = SWGRP.Allegiance.UNDERWORLD,
} )

SWGRP.RegisterRecipe( {
    id        = "med_pack",
    name      = "Field Med Pack",
    materials = { chemical = 3, fiber = 2 },
    result    = "weapon_medkit",
} )
```

Available registration functions: `RegisterJob`, `RegisterCategory`, `RegisterEntity`, `RegisterShipment`, `RegisterAmmoType`, `RegisterVehicle`, `RegisterChatCommand`, `RegisterDoorGroup`, `RegisterJailPos`, `RegisterRecipe`, `RegisterMission`, `RegisterContraband`.

> **Never edit core module files** — updates would overwrite them. Everything you need is reachable from `custom/`.

---

## Map Setup

Create one file per map under `gamemode/custom/`, gated on the map name so it only runs where intended.

### Jail / detention positions
```lua
-- gamemode/custom/map_rp_venator.lua
if game.GetMap() ~= "rp_venator_extensive_v1_4" then return end

SWGRP.RegisterJailPos( Vector( 100, 200, 64 ), Angle( 0, 90, 0 ) )
SWGRP.RegisterJailPos( Vector( 120, 200, 64 ), Angle( 0, 90, 0 ) )
```
If no jail positions are registered, detained players fall back to a random spawn point (never the world origin).

### Job spawn points (admin)
Use the **Job Spawn Tool** (`swgrp_admin_jobspawntool`, given to admins on spawn):

- **Left click** — add a spawn point for the selected profession
- **Right click** — open profession picker / management menu
- **Reload (R)** — remove nearest spawn for that profession

Spawns persist per map in SQLite (`swgrp_world`). Re-applied automatically on content reload.

### Q-menu spawn allowlist
Restrict what props/entities players can spawn from the Sandbox menu (`gamemode/custom/spawnallowlist.lua`):
```lua
SWGRP.SpawnAllowlist.Register( "props", "models/props_c17/oildrum001.mdl" )
SWGRP.SpawnAllowlist.RegisterMany( "weapons", { "weapon_pistol", "weapon_smg1" } )
```
Categories: `props`, `weapons`, `entities`, `vehicles`, `npcs`, `effects`, `ragdolls`.

---

## Administration

SWGRP ships **FAdmin** (the DarkRP admin mod). Use it for kick/ban/teleport/freeze/etc. and the admin scoreboard.

| Task | How |
|------|-----|
| Open admin menu | Hold **TAB**, click a player on the scoreboard |
| Whitelist a player to a job | `/whitelist [name] [job]` (admin) |
| Force/clear wanted | `/wanted` / `/unwanted` |
| Demote a player's job | `/demote [name]` starts a vote |
| Reload CSV content live | `swgrp_reloadcontent` (superadmin, console) |
| Sandbox tool access | `swgrp_sandbox_tools` ConVar |
| Configure a door in-world | **Door Admin Tool** — left-click a door |
| Configure map buttons | **Control Admin Tool** — left-click a button |
| Set profession spawn points | **Job Spawn Tool** — see [Map Setup](#map-setup) |

Admin SWEPs (`swgrp_admin_doortool`, `swgrp_admin_buttontool`, `swgrp_admin_jobspawntool`) are listed in `AdminWeapons` and given to admins on spawn.

After editing any `data/*.csv`, run `swgrp_reloadcontent` to apply changes without a map reload (existing players' job models are refreshed automatically).

---

## Persistence & Database

- Storage is **SQLite** (`garrysmod/sv.db`), via FAdmin's MySQLite with an automatic SQLite fallback (MySQL is intentionally disabled).
- Saved per player: credits, bank balance, profession XP/levels, faction standing, hunger, licenses, and related state.
- World state such as owned doors/structures is persisted and restored on map load.
- Auto-save runs every ~5 minutes and on disconnect.
- **Reset a player's data:** remove their rows from the relevant SQLite tables (use a SQLite browser on `sv.db` while the server is stopped), or provide an admin command in `custom/`.

---

## Hook API Reference

Integrate addons by hooking SWGRP events. "Can" hooks may return `false[, reason]` to block.

```lua
hook.Add( "SWGRPCanChangeJob", "MyAddon", function( ply, teamId )
    if banned( ply ) then return false, "You are restricted." end
end )

hook.Add( "SWGRPPlayerPaid", "MyAddon", function( ply, salary, tax ) end )
hook.Add( "SWGRPMissionCompleted", "MyAddon", function( ply, mission, reward ) end )
```

Available hooks: `SWGRPCanChangeJob`, `SWGRPJobChanged`, `SWGRPPlayerPaid`, `SWGRPPlayerArrested`, `SWGRPPlayerUnarrested`, `SWGRPPlayerWanted`, `SWGRPPlayerBoughtDoor`, `SWGRPPlayerSoldDoor`, `SWGRPMissionCompleted`, `SWGRPMissionAccepted`, `SWGRPCraftedItem`, `SWGRPContrabandFound`, `SWGRPPlayerDeposited`, `SWGRPPlayerWithdrew`.

---

## Troubleshooting

### Server boots into Sandbox instead of SWGRP
This means a **Lua error during gamemode load** aborted `init.lua`/`shared.lua`, so the engine fell back to the base (`sandbox`).

1. Add `-condebug` to the launch options and restart. All console output is written to `garrysmod/console.log`.
2. Open `console.log` and find the **first** red error / `SYNTAX ERROR` / `attempt to ...` after the gamemode begins loading. That file/line is the culprit.
3. Common causes:
   - A syntax error in a `custom/*.lua` file you added. (Files named `example*` are skipped, so use a different name when activating one.)
   - A malformed `data/*.csv` row (e.g. an unquoted comma inside a field).
   - A missing required column header in a CSV.
4. Quick sanity check from the in-game console:
   ```
   lua_run print(file.Exists("gamemodes/swgrp/gamemode/init.lua","GAME"))
   lua_run print(SWGRP and "ok" or "no swgrp table")
   ```

### F4 model preview shows the wrong/default model
The custom model isn't mounted or precached. Ensure the model path in `jobs.csv` exists on the client. SWGRP accepts models that exist on disk even if not yet precached, but a truly missing model falls back to the default citizen/Combine model.

### A profession/structure isn't appearing
- Confirm the row has the required fields (`jobs.csv` needs both `name` and `command`; `entities.csv` needs `class` and `name`).
- Run `swgrp_reloadcontent` and watch the console line `[SWGRP] CSV content loaded: …` for the counts.
- Check the server console for `Unknown profession in allowed list: …` — an `allowed` entry references a `command` that doesn't exist.

### "Only superadmins can reload content"
`swgrp_reloadcontent` is superadmin-only when run by a player. Run it from the server console (RCON/dedicated) or grant yourself superadmin in FAdmin.

### Players spawn at the map origin when jailed
Register jail positions for the map (see [Map Setup](#map-setup)). Without them, SWGRP uses a random spawn point rather than `Vector(0,0,0)`.

### Loading screen is blank or default gray
- Confirm `sv_loadingurl` is set in `server.cfg` or applied by the gamemode (`[SWGRP] Loading screen:` in console).
- For `asset://` URLs, run `deploy/install_loadscreen.ps1` so `garrysmod/html/swgrp/loadscreen.html` exists on the **client** too (or host the HTML on HTTPS for public servers).
- Loading URLs must start with `http` or `asset://` for GMod to display them.

### Workshop content missing (ERROR models / pink/black)
- Every model/SWEP referenced in CSVs must come from an addon in your Workshop collection.
- Verify `host_workshop_collection` is set and the collection is **public or unlisted**.
- Ensure `lua/autorun/server/workshop.lua` lists each addon ID with `resource.AddWorkshop()`.
- Restart the server after updating the collection so addons re-download.

---

## FAQ

**Do I need DarkRP installed?** No. SWGRP is standalone and bundles its own FAdmin/MySQLite compatibility.

**Can I use MySQL?** It's intentionally disabled; SWGRP uses local SQLite. The MySQLite layer is present but configured to fall back to SQLite.

**How do I add a job without coding?** Add a row to `data/jobs.csv` (or `custom/data/jobs.csv`) and run `swgrp_reloadcontent`.

**How do I run a dedicated server?** Git-deploy `gamemodes/swgrp/`, create a Workshop collection for content, set `host_workshop_collection`, copy `deploy/workshop.lua.example` → `lua/autorun/server/workshop.lua`, and configure `deploy/server.cfg.example`. See [Dedicated Server Deployment](#dedicated-server-deployment).

**Should SWGRP be on Workshop?** No. Keep the gamemode in git; use Workshop only for models, maps, weapons, and other content addons.

**Where do my edits go so updates don't wipe them?** Everything in `gamemode/custom/` (Lua) and `gamemode/custom/data/` (CSV overrides) is yours and is loaded on top of the core.

**How do I see what loaded?** The server console prints CSV counts and module-loaded lines on boot; `swgrp_reloadcontent` reprints the CSV counts.

---

*May the Force be with you.*

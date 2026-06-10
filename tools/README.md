# Galaxies RP — GMA asset scanner

Matches assets referenced in SWGRP **CSV files** and **Lua scripts** against Workshop **`.gma`** addon archives. Use this when building your Steam Workshop collection.

## Requirements

- Python 3.8+ (no extra packages)

## Quick start

1. Subscribe to / download the Workshop addons you want to evaluate (or copy `.gma` files into a folder).
2. Point the tool at your Workshop content folder or any directory containing `.gma` files:

```powershell
# From the swgrp gamemode root:
python tools/scan_gma_assets.py --gma-dir "D:\SteamLibrary\steamapps\workshop\content\4000"
```

Typical Workshop path on Windows:

```
...\steamapps\workshop\content\4000\<workshop_id>\
```

The tool searches **recursively** for any `.gma` files under `--gma-dir`.

3. Optional: save JSON for automation:

```powershell
python tools/scan_gma_assets.py --gma-dir "...\content\4000" --json deploy/gma_scan.json
```

## What it scans

| Source | Assets extracted |
|--------|------------------|
| `data/*.csv`, `gamemode/custom/data/*.csv` | Models, weapons, vehicle scripts, entity classes |
| `gamemode/**/*.lua`, `entities/**/*.lua` | Models, vehicle scripts, hardcoded paths (skips FAdmin/MySQLite) |

## What it matches in each `.gma`

| Requirement | Match rule |
|-------------|------------|
| Model `.mdl` | Same path in GMA file list (plus `.vvd` / `.phy` / `.vtx` siblings) |
| Weapon class | `lua/weapons/<class>.lua` or `lua/weapons/<class>/` |
| Vehicle script | `scripts/vehicles/...` path |
| Entity class | `lua/entities/<class>/` (non-`swgrp_*` only) |

## Filters (default)

- **HL2 / base content** (`weapon_pistol`, `models/player/group01/…`, etc.) is **excluded** from missing/covered counts.
- **`swgrp_*` weapons and entities** are listed as **gamemode-local** (ship via git, not Workshop).

Flags:

```powershell
python tools/scan_gma_assets.py --gma-dir "..." --include-vanilla
python tools/scan_gma_assets.py --gma-dir "..." --include-gamemode
```

## Output

- **Top addons** — ranked by how many requirements each GMA satisfies (useful for collection planning)
- **Missing** — assets not found in any scanned GMA (add addons or fix CSV paths)
- **Gamemode-local** — `swgrp_*` content that belongs in git, not Workshop

Exit code `2` when anything is missing (handy for CI).

## Workflow with dedicated server

1. Run this scan against your subscribed addons.
2. Add the top matching addons to your [Workshop collection](../GUIDE.md#2-workshop-collection-content-only).
3. Copy IDs into `deploy/workshop.lua.example` → `garrysmod/lua/autorun/server/workshop.lua`.
4. Keep **SWGRP** out of the collection — deploy with git only.

See also [GUIDE.md → Dedicated Server Deployment](../GUIDE.md#dedicated-server-deployment).

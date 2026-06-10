#!/usr/bin/env python3
"""
Scan Garry's Mod .gma addon archives and match them against assets referenced
by Galaxies RP (SWGRP) CSV data and Lua scripts.

Usage:
  python tools/scan_gma_assets.py --gma-dir "D:/Steam/.../workshop/content/4000"
  python tools/scan_gma_assets.py --gma-dir ./addons --json report.json

Workshop folder layout (Windows):
  .../steamapps/workshop/content/4000/<workshop_id>/...
  Any .gma files under --gma-dir are parsed (searched recursively).
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import struct
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple

# ---------------------------------------------------------------------------
# GMA parser (GMAD v1–v3, read file list only — no extraction)
# ---------------------------------------------------------------------------

GMA_FILE_DIR = 0x01


def _read_cstring(f) -> str:
    buf = bytearray()
    while True:
        chunk = f.read(1)
        if not chunk or chunk == b"\x00":
            break
        buf.extend(chunk)
    return buf.decode("utf-8", errors="replace")


@dataclass
class GmaInfo:
    path: str
    workshop_id: Optional[str]
    title: str
    author: str
    version: int
    files: Set[str] = field(default_factory=set)
    weapon_scripts: Set[str] = field(default_factory=set)
    entity_scripts: Set[str] = field(default_factory=set)
    models: Set[str] = field(default_factory=set)

    def __post_init__(self) -> None:
        for entry in self.files:
            lower = entry.lower()
            if lower.endswith(".mdl"):
                self.models.add(lower)
            if lower.startswith("lua/weapons/"):
                rest = lower[len("lua/weapons/") :]
                if rest.endswith(".lua"):
                    rest = rest[:-4]
                cls = rest.split("/")[0]
                if cls:
                    self.weapon_scripts.add(cls)
            if lower.startswith("lua/entities/"):
                rest = lower[len("lua/entities/") :]
                if rest.endswith(".lua"):
                    rest = rest[:-4]
                cls = rest.split("/")[0]
                if cls:
                    self.entity_scripts.add(cls)


def parse_gma(path: Path, workshop_id: Optional[str] = None) -> GmaInfo:
    with path.open("rb") as f:
        if f.read(4) != b"GMAD":
            raise ValueError(f"Not a GMA file: {path}")

        version = struct.unpack("B", f.read(1))[0]
        f.read(8)  # steamid
        f.read(8)  # timestamp
        author = _read_cstring(f)
        title = _read_cstring(f)
        if version >= 3:
            _read_cstring(f)  # description

        files: Set[str] = set()
        while True:
            size = struct.unpack("<Q", f.read(8))[0]
            f.read(8)  # crc
            flags = struct.unpack("B", f.read(1))[0]
            name = _read_cstring(f)
            if name == "":
                break
            files.add(name.replace("\\", "/").lower())
            if not (flags & GMA_FILE_DIR):
                f.seek(size, 1)

    return GmaInfo(
        path=str(path),
        workshop_id=workshop_id,
        title=title or path.stem,
        author=author,
        version=version,
        files=files,
    )


def infer_workshop_id(gma_path: Path) -> Optional[str]:
    for part in reversed(gma_path.parts):
        if part.isdigit() and len(part) >= 6:
            return part
    stem = gma_path.stem
    if stem.isdigit():
        return stem
    return None


def find_gma_files(root: Path) -> List[Tuple[Path, Optional[str]]]:
    out: List[Tuple[Path, Optional[str]]] = []
    for path in root.rglob("*"):
        if path.suffix.lower() == ".gma" and path.is_file():
            out.append((path, infer_workshop_id(path)))
    return sorted(out, key=lambda x: x[0].name)


# ---------------------------------------------------------------------------
# Asset requirement extraction (CSV + Lua)
# ---------------------------------------------------------------------------

VANILLA_MODEL_PREFIXES = (
    "models/player/group01/",
    "models/player/group02/",
    "models/player/group03/",
    "models/player/corpse1.mdl",
    "models/props_c17/",
    "models/props_junk/",
    "models/props_lab/",
    "models/hunter/",
    "models/items/item_item_crate.mdl",
    "models/weapons/c_",
    "models/weapons/w_pistol",
    "models/weapons/w_smg",
    "models/weapons/w_crowbar",
    "models/weapons/w_toolgun",
    "models/weapons/w_physcannon",
)

VANILLA_WEAPONS = {
    "weapon_pistol",
    "weapon_smg1",
    "weapon_crowbar",
    "weapon_medkit",
    "weapon_physgun",
    "weapon_physcannon",
    "gmod_tool",
    "gmod_camera",
    "weapon_stunstick",
}

SWGRP_WEAPON_PREFIXES = ("swgrp_",)

MODEL_RE = re.compile(r"models/[a-zA-Z0-9_./-]+\.mdl", re.IGNORECASE)
SCRIPT_RE = re.compile(r"scripts/vehicles/[a-zA-Z0-9_./-]+\.txt", re.IGNORECASE)

LUA_SKIP_DIRS = {
    "fadmin",
    "mysqlite",
    "libraries/mysqlite",
}


@dataclass
class AssetRef:
    kind: str  # model | weapon | vehicle_script | entity_class
    value: str
    source: str

    @property
    def key(self) -> str:
        return f"{self.kind}:{self.value.lower()}"


def normalize_model(path: str) -> str:
    return path.replace("\\", "/").lower()


def is_vanilla_model(model: str) -> bool:
    m = normalize_model(model)
    return any(m.startswith(p) or m == p.rstrip("/") for p in VANILLA_MODEL_PREFIXES)


def is_gamemode_weapon(weapon: str) -> bool:
    w = weapon.lower()
    return w.startswith(SWGRP_WEAPON_PREFIXES)


def is_vanilla_weapon(weapon: str) -> bool:
    return weapon.lower() in VANILLA_WEAPONS


def read_csv_rows(path: Path) -> List[dict]:
    if not path.is_file():
        return []
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        return [{k.strip(): (v or "").strip() for k, v in row.items() if k} for row in reader]


def split_pipe(value: str) -> List[str]:
    if not value or value == "*":
        return []
    return [p.strip() for p in value.split("|") if p.strip()]


def collect_csv_requirements(csv_path: Path, label: str, refs: List[AssetRef]) -> None:
    name = csv_path.name.lower()

    for row in read_csv_rows(csv_path):
        if name == "jobs.csv":
            for m in split_pipe(row.get("models", "")):
                refs.append(AssetRef("model", normalize_model(m), f"{label}:jobs.models"))
            for w in split_pipe(row.get("weapons", "")):
                refs.append(AssetRef("weapon", w.lower(), f"{label}:jobs.weapons"))

        elif name == "entities.csv":
            cls = row.get("class", "")
            if cls and not cls.startswith("#"):
                refs.append(AssetRef("entity_class", cls.lower(), f"{label}:entities.class"))
            m = row.get("model", "")
            if m:
                refs.append(AssetRef("model", normalize_model(m), f"{label}:entities.model"))

        elif name == "shipments.csv":
            for col in ("model", "preview_model"):
                m = row.get(col, "")
                if m:
                    refs.append(AssetRef("model", normalize_model(m), f"{label}:shipments.{col}"))
            for w in split_pipe(row.get("entities", "")):
                refs.append(AssetRef("weapon", w.lower(), f"{label}:shipments.entities"))

        elif name in ("foods.csv", "spices.csv"):
            m = row.get("model", "")
            if m:
                refs.append(AssetRef("model", normalize_model(m), f"{label}:{name}.model"))

        elif name == "ammo.csv":
            m = row.get("model", "")
            if m:
                refs.append(AssetRef("model", normalize_model(m), f"{label}:ammo.model"))

        elif name == "vehicles.csv":
            m = row.get("model", "")
            if m:
                refs.append(AssetRef("model", normalize_model(m), f"{label}:vehicles.model"))
            script = row.get("script", "")
            if script:
                refs.append(
                    AssetRef(
                        "vehicle_script",
                        script.replace("\\", "/").lower(),
                        f"{label}:vehicles.script",
                    )
                )
            cls = row.get("class", "")
            if cls:
                refs.append(AssetRef("entity_class", cls.lower(), f"{label}:vehicles.class"))


def should_scan_lua(path: Path) -> bool:
    rel = path.as_posix().lower()
    return not any(skip in rel for skip in LUA_SKIP_DIRS)


def collect_lua_requirements(lua_path: Path, refs: List[AssetRef]) -> None:
    try:
        text = lua_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return

    rel = lua_path.as_posix()
    for m in MODEL_RE.findall(text):
        refs.append(AssetRef("model", normalize_model(m), rel))

    for s in SCRIPT_RE.findall(text):
        refs.append(AssetRef("vehicle_script", s.lower(), rel))

    parts = [p.lower() for p in lua_path.parts]
    fname = lua_path.name.lower()
    if fname in ("shared.lua", "init.lua", "cl_init.lua"):
        return

    stem = lua_path.stem.lower()
    if lua_path.parent.name.lower() == "weapons" and "weapons" in parts:
        refs.append(AssetRef("weapon", stem, rel))
    elif lua_path.parent.name.lower() == "entities" and parts.count("entities") >= 2:
        refs.append(AssetRef("entity_class", stem, rel))


def collect_all_requirements(root: Path) -> List[AssetRef]:
    refs: List[AssetRef] = []

    csv_dirs = [
        (root / "data", "data"),
        (root / "gamemode" / "custom" / "data", "custom/data"),
    ]
    for directory, label in csv_dirs:
        if not directory.is_dir():
            continue
        for csv_file in sorted(directory.glob("*.csv")):
            collect_csv_requirements(csv_file, label, refs)

    lua_roots = [
        root / "gamemode",
        root / "entities",
    ]
    for base in lua_roots:
        if not base.is_dir():
            continue
        for lua_file in base.rglob("*.lua"):
            if should_scan_lua(lua_file):
                collect_lua_requirements(lua_file, refs)

    return refs


def dedupe_refs(refs: List[AssetRef]) -> List[AssetRef]:
    seen: Set[str] = set()
    out: List[AssetRef] = []
    for ref in refs:
        if ref.key in seen:
            continue
        seen.add(ref.key)
        out.append(ref)
    return out


# ---------------------------------------------------------------------------
# Matching
# ---------------------------------------------------------------------------


def model_in_gma(model: str, gma: GmaInfo) -> bool:
    m = normalize_model(model)
    if m in gma.files or m in gma.models:
        return True
    # Some addons store uppercase paths; files set is already lowercased
    stem = m[:-4] if m.endswith(".mdl") else m
    for ext in (".vvd", ".phy", ".dx90.vtx", ".sw.vtx", ".vtx"):
        if stem + ext in gma.files:
            return True
    return False


def weapon_in_gma(weapon: str, gma: GmaInfo) -> bool:
    w = weapon.lower()
    if w in gma.weapon_scripts:
        return True
    prefixes = (
        f"lua/weapons/{w}.lua",
        f"lua/weapons/{w}/",
    )
    return any(any(f.startswith(p) for f in gma.files) for p in prefixes)


def script_in_gma(script: str, gma: GmaInfo) -> bool:
    s = script.lower()
    return s in gma.files or any(f.endswith(s) for f in gma.files)


def entity_in_gma(cls: str, gma: GmaInfo) -> bool:
    c = cls.lower()
    if c.startswith("swgrp_"):
        return False  # gamemode ships these — not workshop
    if c in gma.entity_scripts:
        return True
    return any(f.startswith(f"lua/entities/{c}/") or f == f"lua/entities/{c}.lua" for f in gma.files)


def match_ref(ref: AssetRef, gmas: List[GmaInfo]) -> List[GmaInfo]:
    hits: List[GmaInfo] = []
    for gma in gmas:
        ok = False
        if ref.kind == "model":
            ok = model_in_gma(ref.value, gma)
        elif ref.kind == "weapon":
            if is_gamemode_weapon(ref.value):
                continue
            ok = weapon_in_gma(ref.value, gma)
        elif ref.kind == "vehicle_script":
            ok = script_in_gma(ref.value, gma)
        elif ref.kind == "entity_class":
            ok = entity_in_gma(ref.value, gma)
        if ok:
            hits.append(gma)
    return hits


def filter_ref(ref: AssetRef, include_vanilla: bool, include_gamemode: bool) -> bool:
    if ref.kind == "model" and not include_vanilla and is_vanilla_model(ref.value):
        return False
    if ref.kind == "weapon":
        if not include_gamemode and is_gamemode_weapon(ref.value):
            return False
        if not include_vanilla and is_vanilla_weapon(ref.value):
            return False
    if ref.kind == "entity_class" and ref.value.startswith("swgrp_"):
        return include_gamemode
    return True


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------


def print_report(
    refs: List[AssetRef],
    gmas: List[GmaInfo],
    include_vanilla: bool,
    include_gamemode: bool,
) -> dict:
    filtered = [r for r in refs if filter_ref(r, include_vanilla, include_gamemode)]

    covered: Dict[str, List[GmaInfo]] = {}
    missing: List[AssetRef] = []
    gamemode_local: List[AssetRef] = []

    for ref in filtered:
        if ref.kind == "weapon" and is_gamemode_weapon(ref.value):
            gamemode_local.append(ref)
            continue
        if ref.kind == "entity_class" and ref.value.startswith("swgrp_"):
            gamemode_local.append(ref)
            continue

        hits = match_ref(ref, gmas)
        if hits:
            covered[ref.key] = hits
        else:
            missing.append(ref)

    gma_scores: Dict[str, int] = defaultdict(int)
    for hits in covered.values():
        for gma in hits:
            gid = gma.workshop_id or gma.title
            gma_scores[gid] += 1

    print("=" * 72)
    print("Galaxies RP — GMA asset scan")
    print("=" * 72)
    print(f"GMA archives scanned : {len(gmas)}")
    print(f"Unique requirements  : {len(filtered)} (after filters)")
    print(f"Covered              : {len(covered)}")
    print(f"Missing from GMAs    : {len(missing)}")
    print(f"Gamemode-local       : {len(gamemode_local)} (swgrp_* — not Workshop)")
    print()

    if gma_scores:
        print("Top addons by matched assets:")
        print("-" * 72)
        ranked = sorted(gma_scores.items(), key=lambda x: (-x[1], x[0]))
        for gid, count in ranked[:25]:
            title = next(
                (g.title for g in gmas if (g.workshop_id or g.title) == gid),
                "",
            )
            print(f"  {count:4d}  {gid:>12}  {title}")
        print()

    if missing:
        print("MISSING (add Workshop addons that contain these):")
        print("-" * 72)
        by_kind: Dict[str, List[AssetRef]] = defaultdict(list)
        for ref in sorted(missing, key=lambda r: (r.kind, r.value)):
            by_kind[ref.kind].append(ref)

        for kind in ("model", "weapon", "vehicle_script", "entity_class"):
            items = by_kind.get(kind, [])
            if not items:
                continue
            print(f"\n[{kind}] ({len(items)})")
            for ref in items:
                print(f"  {ref.value}")
                print(f"    via {ref.source}")
        print()

    if covered and len(covered) <= 40:
        print("COVERED:")
        print("-" * 72)
        for ref_key in sorted(covered.keys()):
            ref = next(r for r in filtered if r.key == ref_key)
            gma_list = covered[ref_key]
            ids = ", ".join(g.workshop_id or g.title for g in gma_list[:5])
            print(f"  {ref.kind}: {ref.value}")
            print(f"    -> {ids}")
        print()

    if gamemode_local:
        print("GAMEMODE-LOCAL (shipped in swgrp git — do not add to Workshop collection):")
        print("-" * 72)
        shown = sorted({r.value for r in gamemode_local})
        for val in shown[:30]:
            print(f"  {val}")
        if len(shown) > 30:
            print(f"  ... and {len(shown) - 30} more")
        print()

    return {
        "gma_count": len(gmas),
        "requirement_count": len(filtered),
        "covered_count": len(covered),
        "missing_count": len(missing),
        "missing": [
            {"kind": r.kind, "value": r.value, "source": r.source} for r in missing
        ],
        "addon_scores": dict(gma_scores),
        "gmas": [
            {
                "workshop_id": g.workshop_id,
                "title": g.title,
                "path": g.path,
                "file_count": len(g.files),
            }
            for g in gmas
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Match SWGRP CSV/Lua asset references against .gma Workshop addons."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="SWGRP gamemode root (default: parent of tools/)",
    )
    parser.add_argument(
        "--gma-dir",
        type=Path,
        required=True,
        help="Folder to search recursively for .gma files (e.g. steamapps/workshop/content/4000)",
    )
    parser.add_argument(
        "--json",
        type=Path,
        default=None,
        help="Write full report JSON to this path",
    )
    parser.add_argument(
        "--include-vanilla",
        action="store_true",
        help="Include HL2 / base-game models and weapons in the report",
    )
    parser.add_argument(
        "--include-gamemode",
        action="store_true",
        help="Include swgrp_* weapons/entities (normally excluded from Workshop matching)",
    )
    args = parser.parse_args()

    root = args.root or Path(__file__).resolve().parent.parent
    gma_dir = args.gma_dir

    if not gma_dir.is_dir():
        print(f"Error: --gma-dir not found: {gma_dir}", file=sys.stderr)
        return 1

    gma_paths = find_gma_files(gma_dir)
    if not gma_paths:
        print(f"No .gma files under {gma_dir}", file=sys.stderr)
        return 1

    gmas: List[GmaInfo] = []
    for path, wid in gma_paths:
        try:
            gmas.append(parse_gma(path, wid))
        except (ValueError, struct.error, OSError) as exc:
            print(f"Warning: skip {path}: {exc}", file=sys.stderr)

    refs = dedupe_refs(collect_all_requirements(root))
    report = print_report(
        refs,
        gmas,
        include_vanilla=args.include_vanilla,
        include_gamemode=args.include_gamemode,
    )

    if args.json:
        args.json.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(f"Wrote JSON report to {args.json}")

    return 0 if report["missing_count"] == 0 else 2


if __name__ == "__main__":
    sys.exit(main())

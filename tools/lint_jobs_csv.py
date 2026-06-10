#!/usr/bin/env python3
"""Lint gamemodes/swgrp data/jobs.csv (+ custom merge)."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_JOBS = ROOT / "data" / "jobs.csv"
CUSTOM_JOBS = ROOT / "gamemode" / "custom" / "data" / "jobs.csv"

REQUIRED_COLUMNS = (
    "name",
    "command",
    "category",
    "allegiance",
    "color",
    "models",
    "description",
    "weapons",
    "salary",
    "max",
    "admin",
    "vote",
    "flags",
)

VALID_ALLEGIANCES = frozenset(
    {"NEUTRAL", "IMPERIAL", "REBEL", "UNDERWORLD", "neutral", "imperial", "rebel", "underworld"}
)

VALID_FLAGS = frozenset(
    {
        "hobo",
        "cook",
        "medic",
        "doctor",
        "bountyhunter",
        "haslicense",
        "governor",
        "officer",
        "stormtrooper",
        "commander",
        "chief",
        "whitelist",
        "disguise",
        "captain",
        "hireable",
    }
)

COLOR_RE = re.compile(r"^\s*(\d{1,3})[\s,]+(\d{1,3})[\s,]+(\d{1,3})\s*$")
COMMAND_RE = re.compile(r"^[a-z0-9_]+$")
MODEL_RE = re.compile(r"^models/", re.I)


class LintError:
    def __init__(self, path: Path, line: int, message: str) -> None:
        self.path = path
        self.line = line
        self.message = message

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.message}"


def read_jobs(path: Path) -> list[tuple[int, dict[str, str]]]:
    if not path.is_file():
        return []

    rows: list[tuple[int, dict[str, str]]] = []
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            return rows

        for i, raw in enumerate(reader, start=2):
            row = {k.strip(): (v or "").strip() for k, v in raw.items() if k}
            if not row.get("name") and not row.get("command"):
                continue
            rows.append((i, row))
    return rows


def split_pipe(value: str) -> list[str]:
    if not value or value == "*":
        return []
    return [p.strip() for p in value.split("|") if p.strip()]


def split_flags(value: str) -> list[str]:
    if not value:
        return []
    return [f.strip() for f in re.split(r"[,\\s]+", value) if f.strip()]


def lint_file(path: Path, rows: list[tuple[int, dict[str, str]]], commands_seen: dict[str, tuple[Path, int]]) -> list[LintError]:
    errors: list[LintError] = []

    if not rows and path == DATA_JOBS:
        errors.append(LintError(path, 1, "no job rows found"))
        return errors

    with path.open(encoding="utf-8-sig") as f:
        header_line = f.readline().strip()
    header_cols = [c.strip() for c in header_line.split(",")]
    for col in REQUIRED_COLUMNS:
        if col not in header_cols:
            errors.append(LintError(path, 1, f"missing required column '{col}' in header"))

    for line_no, row in rows:
        name = row.get("name", "")
        command = row.get("command", "").lower()

        if not name:
            errors.append(LintError(path, line_no, "missing name"))
        if not command:
            errors.append(LintError(path, line_no, "missing command"))
            continue

        if not COMMAND_RE.match(command):
            errors.append(
                LintError(
                    path,
                    line_no,
                    f"command '{command}' must be lowercase alphanumeric (underscore ok)",
                )
            )

        if command in commands_seen:
            prev_path, prev_line = commands_seen[command]
            errors.append(
                LintError(
                    path,
                    line_no,
                    f"duplicate command '{command}' (first at {prev_path}:{prev_line})",
                )
            )
        else:
            commands_seen[command] = (path, line_no)

        allegiance = row.get("allegiance", "")
        if allegiance and allegiance not in VALID_ALLEGIANCES:
            errors.append(
                LintError(
                    path,
                    line_no,
                    f"invalid allegiance '{allegiance}' (use NEUTRAL, IMPERIAL, REBEL, UNDERWORLD)",
                )
            )

        color = row.get("color", "")
        if color:
            m = COLOR_RE.match(color)
            if not m:
                errors.append(LintError(path, line_no, f"invalid color '{color}' (expected R G B)"))
            else:
                for part in m.groups():
                    if int(part) > 255:
                        errors.append(LintError(path, line_no, f"color channel out of range: {part}"))

        models_raw = row.get("models", "")
        if models_raw.endswith("|") or models_raw.startswith("|"):
            errors.append(LintError(path, line_no, "models list has a leading or trailing pipe"))
        models = split_pipe(models_raw)
        if not models:
            errors.append(LintError(path, line_no, "no models defined"))
        for model in models:
            if not MODEL_RE.match(model):
                errors.append(LintError(path, line_no, f"model '{model}' should start with models/"))

        for flag in split_flags(row.get("flags", "")):
            if flag.lower() not in VALID_FLAGS:
                errors.append(LintError(path, line_no, f"unknown flag '{flag}'"))

        for field in ("salary", "max", "admin"):
            val = row.get(field, "")
            if val and not re.fullmatch(r"-?\d+", val):
                errors.append(LintError(path, line_no, f"{field} must be an integer, got '{val}'"))

        vote = row.get("vote", "")
        if vote and vote not in {"0", "1", "true", "false", "yes", "no", "y", ""}:
            errors.append(LintError(path, line_no, f"vote must be 0/1 or true/false, got '{vote}'"))

        weapons_raw = row.get("weapons", "")
        if weapons_raw.endswith("|") or weapons_raw.startswith("|"):
            errors.append(LintError(path, line_no, "weapons list has a leading or trailing pipe"))

    return errors


def main() -> int:
    commands_seen: dict[str, tuple[Path, int]] = {}
    all_errors: list[LintError] = []

    data_rows = read_jobs(DATA_JOBS)
    all_errors.extend(lint_file(DATA_JOBS, data_rows, commands_seen))

    custom_rows = read_jobs(CUSTOM_JOBS)
    all_errors.extend(lint_file(CUSTOM_JOBS, custom_rows, commands_seen))

    if all_errors:
        print(f"jobs.csv lint: {len(all_errors)} error(s)")
        for err in all_errors:
            print(err)
        return 1

    total = len(data_rows) + len(custom_rows)
    print(f"jobs.csv lint: OK ({total} job row(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())

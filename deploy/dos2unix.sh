#!/usr/bin/env bash
# Convert Windows line endings under the swgrp gamemode tree (run on Linux srcds host).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v dos2unix >/dev/null 2>&1; then
	echo "Installing dos2unix..."
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update && sudo apt-get install -y dos2unix
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y dos2unix
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y dos2unix
	else
		echo "Install dos2unix manually, then re-run this script."
		exit 1
	fi
fi

echo "Converting line endings under: $ROOT"

find "$ROOT" -type f \( \
	-name '*.lua' -o \
	-name '*.csv' -o \
	-name '*.txt' -o \
	-name '*.md' -o \
	-name '*.html' -o \
	-name '*.cfg' -o \
	-name '*.json' -o \
	-name '*.example' -o \
	-name '*.ps1' \
\) -print0 | xargs -0 dos2unix

echo "Done. Restart srcds after deploying."

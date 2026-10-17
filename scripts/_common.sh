#!/usr/bin/env bash
# Shared helpers for the generator scripts. Not meant to be run directly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$ROOT/Templates"
FEATURES_SRC="$ROOT/Modules/Sources/Features"
FEATURES_TESTS="$ROOT/Modules/Tests/FeaturesTests"
MODULE="Features"

# File header (same format as Xcode). Override per developer: AUTHOR="Jane Doe" make feature ...
AUTHOR="${AUTHOR:-Komsit Chusangthong}"
PROJECT_NAME="$(basename "$(ls -d "$ROOT"/*.xcodeproj | head -1)" .xcodeproj)"
TODAY="$(date +%d/%m)/$(( $(date +%Y) + 543 )) BE"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "› $*"; }

require_pascal_case() {
  [[ "$1" =~ ^[A-Z][A-Za-z0-9]*$ ]] || die "'$1' must be PascalCase (e.g. Profile, EventDetail)"
}

# render <source file> <destination dir> <key=value>...
# Copies a template file, replacing ___VARIABLE_key___ in its name and content,
# and ___FILEHEADER___ with the standard header (author + Buddhist-era date).
render() {
  local src="$1" dest_dir="$2"; shift 2
  local name; name="$(basename "$src")"
  local pair key value
  for pair in "$@"; do
    key="${pair%%=*}"; value="${pair#*=}"
    name="${name//___VARIABLE_${key}___/$value}"
  done
  mkdir -p "$dest_dir"
  local dest="$dest_dir/$name"
  [[ -e "$dest" ]] && die "${dest#$ROOT/} already exists"
  cp "$src" "$dest"
  for pair in "$@"; do
    key="${pair%%=*}"; value="${pair#*=}"
    KEY="___VARIABLE_${key}___" VALUE="$value" perl -pi -e 's/\Q$ENV{KEY}\E/$ENV{VALUE}/g' "$dest"
  done
  local header
  header="$(printf '//\n//  %s\n//  %s\n//\n//  Created by %s on %s.\n//' "$name" "$PROJECT_NAME" "$AUTHOR" "$TODAY")"
  HEADER="$header" perl -0pi -e 's/___FILEHEADER___/$ENV{HEADER}/' "$dest"
  echo "  + ${dest#$ROOT/}"
}

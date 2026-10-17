#!/usr/bin/env bash
# Installs the VIPER scene templates into Xcode (File > New > File... > "VIPER").
# Re-run after pulling template changes. Restart Xcode to see them.
# Only replaces templates shipped by this kit; other templates in the folder are kept.
source "$(dirname "$0")/_common.sh"

DEST="$HOME/Library/Developer/Xcode/Templates/File Templates/VIPER"
mkdir -p "$DEST"
for template in "$TEMPLATES/Xcode/VIPER/"*.xctemplate; do
  name="$(basename "$template")"
  rm -rf "${DEST:?}/$name"
  cp -R "$template" "$DEST/"
done
info "Installed to $DEST"
ls "$DEST"

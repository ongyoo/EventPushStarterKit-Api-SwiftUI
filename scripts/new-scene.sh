#!/usr/bin/env bash
# Adds a VIPER scene (screen) to an existing feature folder.
#
#   scripts/new-scene.sh <Feature> <Scene> [--uikit]
#
#   scripts/new-scene.sh Profile EditProfile           # SwiftUI view
#   scripts/new-scene.sh Profile Settings --uikit      # Storyboard view controller
source "$(dirname "$0")/_common.sh"

[[ $# -ge 2 ]] || die "usage: new-scene.sh <Feature> <Scene> [--uikit]"
FEATURE="$1"; SCENE="$2"; STYLE="${3:-}"
require_pascal_case "$FEATURE"; require_pascal_case "$SCENE"

FEATURE_DIR="$FEATURES_SRC/$FEATURE"
SCENE_DIR="$FEATURE_DIR/Scenes/$SCENE"
[[ -d "$FEATURE_DIR" ]] || die "feature $FEATURE not found. Create it first: make feature NAME=$FEATURE"
[[ -e "$SCENE_DIR" ]] && die "scene $SCENE already exists in $FEATURE"
# One module: type names must be unique across features.
if grep -rqs "\b${SCENE}Presenter\b" "$FEATURES_SRC"; then
  die "a scene named $SCENE already exists in another feature (one module = one namespace)"
fi

if [[ "$STYLE" == "--uikit" ]]; then
  TEMPLATE="$TEMPLATES/Xcode/VIPER/UIKit Storyboard Scene.xctemplate"
  TESTS="$TEMPLATES/Tests/UIKit"
else
  TEMPLATE="$TEMPLATES/Xcode/VIPER/SwiftUI Scene.xctemplate"
  TESTS="$TEMPLATES/Tests/SwiftUI"
fi

VARS=("sceneName=$SCENE" "moduleName=$MODULE")
info "Scene $SCENE -> $FEATURE (${STYLE:-swiftui})"
for file in "$TEMPLATE"/*.swift "$TEMPLATE"/*.storyboard; do
  [[ -e "$file" ]] || continue
  render "$file" "$SCENE_DIR" "${VARS[@]}"
done
for file in "$TESTS"/*.swift; do
  render "$file" "$FEATURES_TESTS/$FEATURE" "${VARS[@]}"
done

cat <<MSG

Next:
  1. Implement ${SCENE}Interactor (call a repository) and adjust ${SCENE}Item.
  2. Let the feature coordinator conform to ${SCENE}Routing and show it:
       navigator.push(${SCENE}Builder.build(router: self))
  3. make test
MSG

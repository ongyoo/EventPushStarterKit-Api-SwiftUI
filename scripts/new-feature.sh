#!/usr/bin/env bash
# Creates a feature folder (Coordinator + first scene + tests) in the
# Features module. Nothing to register: the folder is picked up automatically.
#
#   scripts/new-feature.sh <Name> [--uikit]
#
#   scripts/new-feature.sh Profile            # first screen in SwiftUI
#   scripts/new-feature.sh Wallet --uikit     # first screen in Storyboard
source "$(dirname "$0")/_common.sh"

[[ $# -ge 1 ]] || die "usage: new-feature.sh <Name> [--uikit]"
NAME="${1%Feature}"; STYLE="${2:-}"
require_pascal_case "$NAME"
[[ -e "$FEATURES_SRC/$NAME" ]] && die "feature $NAME already exists"

info "Feature $NAME"
render "$TEMPLATES/Feature/___VARIABLE_featureName___Coordinator.swift" "$FEATURES_SRC/$NAME" "featureName=$NAME"
render "$TEMPLATES/FeatureTests/___VARIABLE_featureName___CoordinatorTests.swift" "$FEATURES_TESTS/$NAME" "featureName=$NAME"
"$ROOT/scripts/new-scene.sh" "$NAME" "$NAME" ${STYLE:+"$STYLE"} | sed -n '/^  +/p'

cat <<MSG

Next:
  1. Start it from a flow in the App layer (Modules/Sources/App/Flows), e.g.:
       let coordinator = ${NAME}Coordinator(navigator: navigator)
       coordinator.onOutput = { [weak self] output in ... }
       startChild(coordinator)
  2. Add its deep link to the flow's route(_:) if needed.
  3. make test
MSG

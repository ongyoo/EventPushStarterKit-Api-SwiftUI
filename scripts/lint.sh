#!/usr/bin/env bash
# Crash-safety lint: fails on code patterns that can crash at runtime.
# Runs in CI (make lint) and before commits. No third-party tool needed.
#
# Allowed exceptions: add `// lint:allow` at the end of the line, with a reason.
source "$(dirname "$0")/_common.sh"

SOURCES=("$ROOT/Modules/Sources" "$ROOT/App/Sources" "$ROOT/Packages/LiquidGlassKit/Sources" "$ROOT/Packages/ServerDrivenUI/Sources")
[[ -d "$ROOT/Android/SwiftCore/Sources" ]] && SOURCES+=("$ROOT/Android/SwiftCore/Sources")
status=0

check() {
  local message="$1" pattern="$2"
  local hits
  hits="$(grep -rnE --include='*.swift' "$pattern" "${SOURCES[@]}" | grep -v 'lint:allow' | grep -vE '^\S+:[0-9]+:\s*(//|///|\*)' || true)"
  if [[ -n "$hits" ]]; then
    echo "✘ $message"
    echo "$hits" | sed "s#$ROOT/#  #"
    status=1
  fi
}

check "Force try (try!)"                          'try!'
check "Force cast (as!)"                          '\bas! '
check "fatalError / preconditionFailure"          '\b(fatalError|preconditionFailure)\('
check "Force unwrap after call/subscript (x()!)"  '[)\]]![^=]'
check "Implicitly unwrapped property (non-outlet)" '^\s*(private |fileprivate |internal |public )?(weak )?var \w+: [^=]*!\s*$'
check "unowned (crashes if the object is gone)"   '\bunowned\b'

if [[ $status -eq 0 ]]; then
  echo "✔ Crash-safety lint passed"
fi

# Layer arrows (Modules/Package.swift) on every import.
if ! layers="$(python3 "$ROOT/scripts/check-layers.py" 2>&1)"; then
  echo "$layers" | sed "s#$ROOT/#  #"
  status=1
else
  echo "$layers"
fi
exit $status

#!/usr/bin/env bash
# Runs every test with code coverage and prints a per-layer report.
#
#   scripts/coverage.sh [simulator name or id]
#
# "Logic" = every layer minus pure rendering code (SwiftUI views,
# view controllers, components, the DesignSystem module). Rendering is
# verified with previews / UI tests; "All code" shows the full number.
source "$(dirname "$0")/_common.sh"

DESTINATION="${1:-}"
if [[ -z "$DESTINATION" ]]; then
  DESTINATION="$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [^(]+\(([0-9A-F-]{36})\)' | grep -oE '[0-9A-F-]{36}')"
fi
[[ "$DESTINATION" =~ ^[0-9A-F-]{36}$ ]] && DESTINATION="id=$DESTINATION" || DESTINATION="name=$DESTINATION"

OUT="$ROOT/.build/coverage"
rm -rf "$OUT"; mkdir -p "$OUT"
info "Testing Modules on $DESTINATION"
(cd "$ROOT/Modules" && xcodebuild test -scheme Modules-Package -destination "platform=iOS Simulator,$DESTINATION" \
  -enableCodeCoverage YES -resultBundlePath "$OUT/Tests.xcresult" -derivedDataPath "$OUT/DerivedData" -quiet) \
  || die "tests failed"

xcrun xccov view --report --json "$OUT/Tests.xcresult" > "$OUT/coverage.json"
python3 - "$OUT/coverage.json" "${MIN_LOGIC_COVERAGE:-0}" <<'PY'
import json, re, sys
report = json.load(open(sys.argv[1])); minimum = float(sys.argv[2])
# Pure rendering files (verified with previews / UI tests, not unit tests).
UI = re.compile(r'/Sources/DesignSystem/|/Components/|(View|ViewController)\.swift$')
LAYERS = ("Core", "Navigation", "DesignSystem", "DataSources", "Platform", "Domain", "DataLayer", "Features", "App")

# Static modules are linked into several test bundles: merge per source file,
# keeping the best coverage seen (a lower bound of the real union).
files = {}
for target in report["targets"]:
    for f in target["files"]:
        path = f["path"]
        if "/Modules/Sources/" not in path: continue
        best = files.get(path)
        if not best or f["coveredLines"] > best["coveredLines"]:
            files[path] = f

def layer_of(path):
    parts = path.split("/Modules/Sources/")[1].split("/")
    return parts[1] if parts[0] == "Data" else parts[0]   # Data/ groups DataLayer + DataSources

def pct(c, t): return 100.0 * c / t if t else 100.0
stats = {name: {"logic": [0, 0], "all": [0, 0]} for name in LAYERS}
below = []
for path, f in files.items():
    layer = layer_of(path)
    if layer not in stats: continue
    s = stats[layer]
    s["all"][0] += f["coveredLines"]; s["all"][1] += f["executableLines"]
    if not UI.search(path):
        s["logic"][0] += f["coveredLines"]; s["logic"][1] += f["executableLines"]
        if f["executableLines"] and f["coveredLines"] < f["executableLines"]:
            below.append((pct(f["coveredLines"], f["executableLines"]), path.split("/Modules/Sources/")[1], f["executableLines"] - f["coveredLines"]))

print(f"\n{'Layer':<14}{'Logic':>9}{'All code':>11}")
total = [0, 0]; total_all = [0, 0]
for name in LAYERS:
    s = stats[name]
    total[0] += s["logic"][0]; total[1] += s["logic"][1]
    total_all[0] += s["all"][0]; total_all[1] += s["all"][1]
    print(f"{name:<14}{pct(*s['logic']):>8.1f}%{pct(*s['all']):>10.1f}%")
print(f"{'TOTAL':<14}{pct(*total):>8.1f}%{pct(*total_all):>10.1f}%")
if below:
    print("\nLogic files below 100% (lowest first):")
    for cov, name, lines in sorted(below)[:20]:
        print(f"  {cov:5.1f}%  {name}  ({lines} lines)")
if pct(*total) < minimum:
    sys.exit(f"\nLogic coverage {pct(*total):.1f}% is below {minimum}%")
PY

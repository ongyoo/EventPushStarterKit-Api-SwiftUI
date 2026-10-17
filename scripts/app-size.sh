#!/usr/bin/env bash
# Builds a Release app for iPhone (arm64, unsigned) and reports its size:
# install size, estimated download, and who uses the bytes (link map).
#
#   scripts/app-size.sh                 # report
#   MAX_DOWNLOAD_KB=3000 scripts/app-size.sh   # fail if the estimate grows past a budget (CI)
source "$(dirname "$0")/_common.sh"

OUT="$ROOT/.build/size"
APP_NAME="$PROJECT_NAME"
rm -rf "$OUT"; mkdir -p "$OUT"

info "Building Release (arm64)…"
xcodebuild -project "$ROOT/$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath "$OUT/DerivedData" \
  CODE_SIGNING_ALLOWED=NO LD_GENERATE_MAP_FILE=YES -quiet build || die "build failed"

APP="$OUT/DerivedData/Build/Products/Release-iphoneos/$APP_NAME.app"
LINKMAP="$(find "$OUT/DerivedData/Build/Intermediates.noindex" -name "$APP_NAME-LinkMap*.txt" | head -1)"

# What the App Store ships: symbols stripped (done automatically when archiving).
cp -R "$APP" "$OUT/"
xcrun strip -rSTx "$OUT/$APP_NAME.app/$APP_NAME" 2>/dev/null || true
(cd "$OUT" && zip -qr -9 app.zip "$APP_NAME.app")

python3 - "$OUT/$APP_NAME.app" "$OUT/app.zip" "$LINKMAP" "${MAX_DOWNLOAD_KB:-0}" <<'PY'
import collections, os, re, sys
app, archive, linkmap, budget = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])

def tree_size(path):
    return sum(os.path.getsize(os.path.join(d, f)) for d, _, files in os.walk(path) for f in files)

install = tree_size(app)
download = os.path.getsize(archive)
binary = os.path.getsize(os.path.join(app, os.path.basename(app)[:-4]))
print(f"\nInstall size (stripped)     {install/1024:8.0f} KB")
print(f"  of which executable       {binary/1024:8.0f} KB")
print(f"Download estimate (zip -9)  {download/1024:8.0f} KB   (App Store thinning/compression is similar)")

objects, sizes, section = {}, collections.Counter(), None
for line in open(linkmap, errors="ignore"):
    if line.startswith("# Object files:"): section = "obj"; continue
    if line.startswith("# Sections:"): section = "sec"; continue
    if line.startswith("# Symbols:"): section = "sym"; continue
    if line.startswith("# Dead Stripped Symbols:"): break
    if section == "obj":
        m = re.match(r"\[\s*(\d+)\]\s+(.*)", line)
        if m: objects[int(m.group(1))] = m.group(2)
    elif section == "sym":
        m = re.match(r"0x[0-9A-F]+\s+0x([0-9A-F]+)\s+\[\s*(\d+)\]", line)
        if m: sizes[int(m.group(2))] += int(m.group(1), 16)

def group(path):
    for lib in ("Alamofire", "Kingfisher"):
        if lib in path: return lib
    for package in ("LiquidGlassKit", "ServerDrivenUI"):
        if f"/{package}.o" in path or f"/{package}.build/" in path: return package
    for module in ("Core", "Navigation", "DesignSystem", "DataSources", "Platform", "Domain", "DataLayer", "Features", "App"):
        if f"/{module}.o" in path or f"/{module}.build/" in path: return f"Modules/{module}"
    if ".build/" in path and "Objects-normal" in path: return "App target"
    return "System / linker"

groups = collections.Counter()
for index, size in sizes.items():
    groups[group(objects.get(index, ""))] += size
total = sum(groups.values())
print("\nCode + data by owner (before compression):")
for name, size in groups.most_common():
    print(f"  {name:22s} {size/1024:7.0f} KB  {100*size/total:5.1f}%")

if budget and download / 1024 > budget:
    sys.exit(f"\nDownload estimate {download/1024:.0f} KB exceeds the budget of {budget} KB")
PY

#!/usr/bin/env bash
# Creates a NEW app from this starter kit: every layer (Core, Navigation,
# DesignSystem, DataSources, Platform) + empty Domain / DataLayer + an App layer with
# one Home tab (generated feature). The sample's own features are not copied.
#
#   scripts/new-project.sh <AppName> <bundle.id> <destination dir> [team id]
#
#   scripts/new-project.sh ShopApp com.acme.shop ~/Projects ABCDE12345
source "$(dirname "$0")/_common.sh"

[[ $# -ge 3 ]] || die "usage: new-project.sh <AppName> <bundle.id> <destination dir> [team id]"
APP="$1"; BUNDLE_ID="$2"; DEST_PARENT="$3"; TEAM="${4:-}"
require_pascal_case "$APP"
[[ "$BUNDLE_ID" =~ ^[A-Za-z0-9.-]+$ ]] || die "invalid bundle id '$BUNDLE_ID'"
DEST="$DEST_PARENT/$APP"
[[ -e "$DEST" ]] && die "$DEST already exists"
SCHEME="$(echo "$APP" | tr '[:upper:]' '[:lower:]')"
OLD_NAME="EventPushStarterKit"

info "Creating $APP at $DEST"
mkdir -p "$DEST"
rsync -a \
  --exclude '.git' --exclude '.build' --exclude '.swiftpm' --exclude 'DerivedData' \
  --exclude 'xcuserdata' --exclude '.DS_Store' --exclude 'Package.resolved' \
  --exclude "/Modules/Sources/Features/*" --exclude "/Modules/Tests/FeaturesTests/*" \
  --exclude "/Modules/Sources/Domain/*" --exclude "/Modules/Tests/DomainTests/*" \
  --exclude "/Modules/Sources/Data/DataLayer/*" --exclude "/Modules/Tests/DataLayerTests/*" \
  --exclude "/Modules/Sources/App/*" --exclude "/Modules/Tests/AppTests/*" \
  --exclude "/scripts/strings.py" --exclude "/Templates/Extensions/LiveActivity" \
  --exclude "/docs/media" --exclude "/README.md" \
  --exclude "/Android" --exclude "/docs/SWIFT_ANDROID.md" \
  "$ROOT/" "$DEST/"

# The Swift-on-Android case study is not part of new apps: drop its make targets.
sed -i '' -e '/^android:/,/^clean:/{/^clean:/!d;}' -e 's/ android android-run android-test//' \
  -e 's| Android/SwiftCore/.build Android/app/build||' "$DEST/Makefile"

# Starting point per layer: App (composition root + one tab), empty Domain /
# DataLayer, Features with shared strings + test support only.
M="$DEST/Modules"; F="$M/Sources/Features"; T="$M/Tests/FeaturesTests"
mkdir -p "$T/Support"
cp -R "$TEMPLATES/Project/App/." "$M/Sources/App/"
cp -R "$TEMPLATES/Project/AppTests/." "$M/Tests/AppTests/"
cp -R "$TEMPLATES/Project/DataLayer/." "$M/Sources/Data/DataLayer/"
cp -R "$TEMPLATES/Project/DataLayerTests/." "$M/Tests/DataLayerTests/"
mkdir -p "$F/Shared" "$F/Resources"
cp "$TEMPLATES/Project/Shared/L10n.swift" "$F/Shared/"
cp "$TEMPLATES/Project/Resources/Localizable.xcstrings" "$F/Resources/"
cp "$TEMPLATES/Project/Intents/AppShortcuts.swift" "$DEST/App/Sources/Intents/AppShortcuts.swift"
cp -R "$TEMPLATES/Project/Domain/." "$DEST/Modules/Sources/Domain/"
cp -R "$TEMPLATES/Project/DomainTests/." "$DEST/Modules/Tests/DomainTests/"
source "$ROOT/scripts/_common.sh" && render "$TEMPLATES/Project/Support/TestSupport.swift" "$T/Support" > /dev/null

# DataLayer has no fixtures yet: an empty resource bundle would fail code signing.
perl -0pi -e 's/            dependencies: \["Core", "Domain", "DataSources"\],\n            path: "Sources\/Data\/DataLayer",\n            resources: \[\.process\("Resources"\)\]\n/            dependencies: ["Core", "Domain", "DataSources"],\n            path: "Sources\/Data\/DataLayer"\n            \/\/ Add `resources: [.process("Resources")]` with your first JSON fixture.\n/' "$DEST/Modules/Package.swift"

info "Renaming project"
mv "$DEST/$OLD_NAME.xcodeproj" "$DEST/$APP.xcodeproj"
perl -pi -e "s/$OLD_NAME/$APP/g" "$DEST/$APP.xcodeproj/project.pbxproj"
rm -rf "$DEST/$APP.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"

info "Configuring identity"
APP="$APP" BUNDLE_ID="$BUNDLE_ID" SCHEME="$SCHEME" TEAM="$TEAM" perl -pi -e '
  s/^APP_DISPLAY_NAME = .*/APP_DISPLAY_NAME = $ENV{APP}/;
  s/^PRODUCT_BUNDLE_IDENTIFIER = .*/PRODUCT_BUNDLE_IDENTIFIER = $ENV{BUNDLE_ID}/;
  s/^DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = $ENV{TEAM}/;
  s/^DEEP_LINK_SCHEME = .*/DEEP_LINK_SCHEME = $ENV{SCHEME}/;
  s/^UNIVERSAL_LINK_HOST = .*/UNIVERSAL_LINK_HOST = example.com/;
' "$DEST/Config/Base.xcconfig"
for config in Debug Release; do
  perl -pi -e 's{^API_BASE_URL = .*}{API_BASE_URL = https:/\$()/api.example.com}' "$DEST/Config/$config.xcconfig"
done
perl -pi -e 's/^USE_MOCK_API = YES/USE_MOCK_API = NO/' "$DEST/Config/Debug.xcconfig"

info "Updating file headers"
find "$DEST" -name '*.swift' -print0 | xargs -0 perl -pi -e "s{^//  $OLD_NAME\$}{//  $APP}"

cat > "$DEST/README.md" <<README
# $APP

Built from the EventPush Starter Kit: layered modular architecture (App ·
Features · Domain · Data (DataLayer + DataSources) · Platform + Core, Navigation,
DesignSystem), VIPER screens, coordinators, deep links.

\`\`\`bash
open $APP.xcodeproj
make help            # feature / scene / test / coverage / lint / size
\`\`\`

Start with [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
README

info "Generating Home feature"
"$DEST/scripts/new-feature.sh" Home > /dev/null

(cd "$DEST" && git init -q && git add -A && git commit -q -m "Initial commit from starter kit") || true

cat <<MSG

Done: $DEST
  open "$DEST/$APP.xcodeproj"

Next:
  - Set API_BASE_URL in Config/Debug.xcconfig and Config/Release.xcconfig
  - make feature NAME=Profile
  - make scene FEATURE=Home NAME=Search
  - Read README.md, then docs/ARCHITECTURE.md
MSG

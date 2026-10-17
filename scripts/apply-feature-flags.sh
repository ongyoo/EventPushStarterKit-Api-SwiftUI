#!/bin/sh
# Xcode "Run Script" build phase: adds the Info.plist keys of the optional
# capabilities switched on in Config/Features.xcconfig, and removes the others.
# Runs on the BUILT Info.plist, so the source Config/Info.plist stays a plain
# plist that Xcode can edit safely.
set -eu

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
BUDDY=/usr/libexec/PlistBuddy

remove() { "$BUDDY" -c "Delete :$1" "$PLIST" >/dev/null 2>&1 || true; }
add() { "$BUDDY" -c "Add :$1" "$PLIST"; }

remove UIBackgroundModes
remove BGTaskSchedulerPermittedIdentifiers
remove NSSupportsLiveActivities

if [ "${FEATURE_BACKGROUND_TASKS:-NO}" = "YES" ] || [ "${FEATURE_SILENT_PUSH:-NO}" = "YES" ]; then
  add "UIBackgroundModes array"
fi
if [ "${FEATURE_BACKGROUND_TASKS:-NO}" = "YES" ]; then
  add "UIBackgroundModes: string fetch"
  add "UIBackgroundModes: string processing"
  # Must match BackgroundTaskID.refresh / .processing
  add "BGTaskSchedulerPermittedIdentifiers array"
  add "BGTaskSchedulerPermittedIdentifiers: string ${PRODUCT_BUNDLE_IDENTIFIER}.refresh"
  add "BGTaskSchedulerPermittedIdentifiers: string ${PRODUCT_BUNDLE_IDENTIFIER}.processing"
fi
if [ "${FEATURE_SILENT_PUSH:-NO}" = "YES" ]; then
  add "UIBackgroundModes: string remote-notification"
fi
if [ "${FEATURE_LIVE_ACTIVITIES:-NO}" = "YES" ]; then
  add "NSSupportsLiveActivities bool true"
fi

echo "Feature flags applied: notifications=${FEATURE_LOCAL_NOTIFICATIONS:-NO} background=${FEATURE_BACKGROUND_TASKS:-NO} push=${FEATURE_SILENT_PUSH:-NO} liveActivities=${FEATURE_LIVE_ACTIVITIES:-NO} siri=${FEATURE_SIRI:-NO}"

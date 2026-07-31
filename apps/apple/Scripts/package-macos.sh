#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h:h:h}"
output_path="${1:-$repo_root/Tempo.zip}"
archive_path="${RUNNER_TEMP:-/tmp}/Tempo.xcarchive"
app_path="$archive_path/Products/Applications/Tempo.app"
widget_path="$app_path/Contents/PlugIns/TempoMacWidgets.appex"
app_info="$app_path/Contents/Info.plist"
widget_info="$widget_path/Contents/Info.plist"
app_entitlements="$repo_root/apps/apple/Sources/TimeMacApp/TempoMac.entitlements"
widget_entitlements="$repo_root/apps/apple/Sources/TimeMacWidgets/TempoMacWidgets.entitlements"
local_widget_preference_suite="fun.bhushan.time.widget-shared"
local_widget_entitlements="$(mktemp "${RUNNER_TEMP:-/tmp}/TempoMacWidgets.XXXXXX")"

trap 'rm -f "$local_widget_entitlements"' EXIT

: "${CONVEX_URL:?Set CONVEX_URL to the same Convex deployment used by the web app}"

if [[ "$CONVEX_URL" != https://*.convex.cloud ]]; then
  echo "CONVEX_URL must be an HTTPS URL on convex.cloud" >&2
  exit 1
fi

cd "$repo_root"
rm -rf "$archive_path" "$output_path"

xcodebuild -quiet \
  -project apps/apple/Time.xcodeproj \
  -scheme TempoMac \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$archive_path" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CONVEX_URL="$CONVEX_URL" \
  archive

test -x "$app_path/Contents/MacOS/Tempo"
test -x "$widget_path/Contents/MacOS/TempoMacWidgets"
/usr/libexec/PlistBuddy \
  -c "Add :TempoWidgetPreferenceSuite string $local_widget_preference_suite" \
  "$app_info"
/usr/libexec/PlistBuddy \
  -c "Add :TempoWidgetPreferenceSuite string $local_widget_preference_suite" \
  "$widget_info"
cp "$widget_entitlements" "$local_widget_entitlements"
/usr/libexec/PlistBuddy \
  -c "Add :com.apple.security.temporary-exception.shared-preference.read-only array" \
  -c "Add :com.apple.security.temporary-exception.shared-preference.read-only:0 string $local_widget_preference_suite" \
  "$local_widget_entitlements"
codesign --force --sign - --entitlements "$local_widget_entitlements" "$widget_path"
codesign --force --sign - --entitlements "$app_entitlements" "$app_path"
codesign --verify --deep --strict "$app_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$output_path"

echo "$output_path"

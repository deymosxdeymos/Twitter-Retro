#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
build="$root/build"
mkdir -p "$build"

if ! xcodebuild \
    -project "$root/Twitter.xcodeproj" \
    -scheme Twitter \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$build/DerivedData" \
    -clonedSourcePackagesDirPath "$build/SourcePackages" \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    build > "$build/retro-build.log" 2>&1; then
    tail -80 "$build/retro-build.log"
    exit 1
fi

stage="$(mktemp -d "$build/ipa.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/Payload"
ditto --norsrc --noextattr \
    "$build/DerivedData/Build/Products/Release-iphoneos/Twitter.app" \
    "$stage/Payload/Twitter.app"

minimum_os="$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$stage/Payload/Twitter.app/Info.plist")"
if [[ "$minimum_os" != '27.0' ]]; then
    echo "Expected iOS 27.0 minimum; found $minimum_os" >&2
    exit 1
fi

(cd "$stage" && COPYFILE_DISABLE=1 /usr/bin/zip -qry Twitter.ipa Payload)
unzip -tq "$stage/Twitter.ipa"
mv "$stage/Twitter.ipa" "$build/Twitter-Retro-iPhone-iOS27.0.ipa"
ls -lh "$build/Twitter-Retro-iPhone-iOS27.0.ipa"

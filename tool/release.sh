#!/usr/bin/env bash
# Build the release APK and copy it to build/release/mushaf-hafiz-v<version>.apk, then print its size and sha256.
#
# Usage:   tool/release.sh
# Needs:   Flutter on PATH, the generated Quran assets (tool/build_quran_assets.py and tool/build_ayah_assets.py),
#          and android/key.properties (docs/release/SIGNING.md) so the APK is signed with the release key.
# Options: ALLOW_DEBUG_SIGNED=1 tool/release.sh   builds without android/key.properties (debug key); the file is then
#          named ...-debug-signed.apk and MUST NOT be published.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# 1.0.0+1 in pubspec.yaml -> 1.0.0 (the part after + is the build number, not shown in the file name).
full_version="$(awk '/^version:/ { print $2; exit }' pubspec.yaml)"
if [ -z "$full_version" ]; then
  echo "release.sh: cannot read the version from pubspec.yaml" >&2
  exit 1
fi
version="${full_version%%+*}"

# The generated assets are git-ignored; a build without them is not a Mushaf.
if [ ! -f assets/mushaf/meta.json ] || [ ! -d assets/ayah/text ]; then
  echo "release.sh: assets/mushaf or assets/ayah is missing. Run, after putting the sources in data-raw/:" >&2
  echo "  uv run --with 'fonttools[woff]' python tool/build_quran_assets.py" >&2
  echo "  uv run python tool/build_ayah_assets.py" >&2
  exit 1
fi
fonts="$(find assets/fonts/qpc-v2 -maxdepth 1 -name 'p*.ttf' 2>/dev/null | wc -l | tr -d ' ' || true)"
if [ "$fonts" != "604" ]; then
  echo "release.sh: expected 604 fonts in assets/fonts/qpc-v2, found $fonts" >&2
  exit 1
fi

suffix=""
if [ ! -f android/key.properties ]; then
  if [ "${ALLOW_DEBUG_SIGNED:-0}" != "1" ]; then
    echo "release.sh: android/key.properties is missing, so the APK would be signed with the DEBUG key." >&2
    echo "  Create the release key first (docs/release/SIGNING.md), or run" >&2
    echo "  ALLOW_DEBUG_SIGNED=1 tool/release.sh   for a test build that must not be published." >&2
    exit 1
  fi
  suffix="-debug-signed"
  echo "WARNING: no android/key.properties: this APK is signed with the debug key. Do not publish it." >&2
fi

echo "Building mushaf-hafiz v${version} (flutter build apk --release) ..."
flutter build apk --release

built="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$built" ]; then
  echo "release.sh: $built was not produced" >&2
  exit 1
fi

mkdir -p build/release
out="build/release/mushaf-hafiz-v${version}${suffix}.apk"
cp "$built" "$out"

bytes="$(wc -c < "$out" | tr -d ' ')"
hash="$(sha256sum "$out" | awk '{ print $1 }')"
printf '%s  %s\n' "$hash" "$(basename "$out")" > "$out.sha256"

echo
echo "APK:    $out"
echo "Size:   ${bytes} bytes ($(awk -v b="$bytes" 'BEGIN { printf "%.1f MiB", b / 1048576 }'))"
echo "sha256: ${hash}"
echo "(also written to $out.sha256)"

# Best effort: show which certificate signed it (apksigner ships with the Android build-tools).
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
apksigner="$(find "$sdk/build-tools" -name apksigner -type f 2>/dev/null | sort | tail -1 || true)"
if [ -n "$apksigner" ]; then
  echo
  echo "Signing certificate:"
  "$apksigner" verify --print-certs "$out" 2>&1 | grep -E 'certificate (DN|SHA-256)' || true
fi

cat <<EOF

Other formats (not run by this script):
  App bundle:  flutter build appbundle --release   (build/app/outputs/bundle/release/app-release.aab;
               only for Google Play, which is not planned. GitHub, itch.io and APKPure take the APK.)
Before uploading: see docs/release/PUBLISH_CHECKLIST.md
EOF

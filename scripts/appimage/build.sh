#!/usr/bin/env bash
# Usage: scripts/appimage/build.sh <version> <libmpv-dir> [update-information]
# Expects a finished `flutter build linux` and the output of scripts/libmpv/build.sh in <libmpv-dir>.
# Writes Crossonic-<version>-linux-x86-64.AppImage (and .zsync with update information) to the cwd.
set -euo pipefail

VERSION="${1:?usage: $0 <version> <libmpv-dir> [update-information]}"
LIBMPV_DIR="$(cd "${2:?usage: $0 <version> <libmpv-dir> [update-information]}" && pwd)"
UPDATE_INFORMATION="${3:-}"

APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64"
RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

APP_ID="org.crossonic.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"
OUTPUT="$PWD/Crossonic-$VERSION-linux-x86-64.AppImage"

if [ ! -x "$BUNDLE_DIR/Crossonic" ]; then
  echo "No release bundle at $BUNDLE_DIR, run flutter build linux first" >&2
  exit 1
fi
if [ ! -f "$LIBMPV_DIR/libmpv.so.2" ]; then
  echo "No libmpv.so.2 in $LIBMPV_DIR, run scripts/libmpv/build.sh first" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

download() {
  curl -fsSL --retry 3 -o "$2" "$1"
  echo "$3  $2" | sha256sum -c --quiet -
}

download "$APPIMAGETOOL_URL" "$WORK_DIR/appimagetool" "$APPIMAGETOOL_SHA256"
download "$RUNTIME_URL" "$WORK_DIR/runtime" "$RUNTIME_SHA256"
chmod +x "$WORK_DIR/appimagetool"

APPDIR="$WORK_DIR/AppDir"
mkdir -p "$APPDIR/usr/lib/crossonic" "$APPDIR/usr/bin" \
  "$APPDIR/usr/share/applications" "$APPDIR/usr/share/metainfo" \
  "$APPDIR/usr/share/licenses/crossonic"
cp -a "$BUNDLE_DIR/." "$APPDIR/usr/lib/crossonic/"
ln -s ../lib/crossonic/Crossonic "$APPDIR/usr/bin/Crossonic"

# The app loads lib/libmpv.so.2 next to its executable before falling back to the system libmpv.
cp -a "$LIBMPV_DIR"/*.so* "$APPDIR/usr/lib/crossonic/lib/"
cp "$ROOT_DIR/LICENSE" "$APPDIR/usr/share/licenses/crossonic/LICENSE"
cp -r "$LIBMPV_DIR/licenses" "$APPDIR/usr/share/licenses/crossonic/third-party"

install -m 644 "$SCRIPT_DIR/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"
# appimagetool only validates metainfo named .appdata.xml.
install -m 644 "$SCRIPT_DIR/$APP_ID.metainfo.xml" "$APPDIR/usr/share/metainfo/$APP_ID.appdata.xml"
for size in 32 64 128 256 512; do
  install -Dm 644 "$ROOT_DIR/assets/icon/desktop/crossonic-$size.png" \
    "$APPDIR/usr/share/icons/hicolor/${size}x${size}/apps/$APP_ID.png"
done

# A symlink to the binary would work too but the process would be named AppRun.
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
exec "$(dirname "$(readlink -f "$0")")/usr/lib/crossonic/Crossonic" "$@"
EOF
chmod 755 "$APPDIR/AppRun"
ln -s "usr/share/applications/$APP_ID.desktop" "$APPDIR/$APP_ID.desktop"
ln -s "usr/share/icons/hicolor/256x256/apps/$APP_ID.png" "$APPDIR/$APP_ID.png"
ln -s "$APP_ID.png" "$APPDIR/.DirIcon"

ARGS=(--comp zstd --runtime-file "$WORK_DIR/runtime")
if [ -n "$UPDATE_INFORMATION" ]; then
  ARGS+=(--updateinformation "$UPDATE_INFORMATION")
fi

# Extract-and-run so appimagetool does not need FUSE on CI runners.
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 VERSION="$VERSION" \
  "$WORK_DIR/appimagetool" "${ARGS[@]}" "$APPDIR" "$OUTPUT"

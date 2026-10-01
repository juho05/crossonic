#!/usr/bin/env bash
# Usage: scripts/appimage/check-deps.sh <AppImage>
# Fails if a binary in the AppImage needs a host library outside HOST_LIBS
# or glibc/libstdc++ symbols newer than the supported baseline
set -euo pipefail

APPIMAGE="$(realpath "${1:?usage: $0 <AppImage>}")"
MAX_GLIBC="${MAX_GLIBC:-2.35}"
MAX_GLIBCXX="${MAX_GLIBCXX:-3.4.30}"

# Libraries every supported desktop system provides.
HOST_LIBS=(
  ld-linux-x86-64.so.2 libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1
  libstdc++.so.6 libgcc_s.so.1 libz.so.1
  libglib-2.0.so.0 libgobject-2.0.so.0 libgio-2.0.so.0
  libgtk-3.so.0 libgdk-3.so.0 libgdk_pixbuf-2.0.so.0 libatk-1.0.so.0
  libpango-1.0.so.0 libpangocairo-1.0.so.0 libcairo.so.2 libcairo-gobject.so.2
  libharfbuzz.so.0 libfontconfig.so.1 libfreetype.so.6 libfribidi.so.0 libepoxy.so.0
  libX11.so.6 libXi.so.6
  libgnutls.so.30 libasound.so.2 libpulse.so.0
)
# <binary>:<library> pairs that are never loaded on Linux.
IGNORED=(
  libdartjni.so:libjvm.so
)

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"
"$APPIMAGE" --appimage-extract >/dev/null

ELF_FILES=()
while IFS= read -r -d '' FILE; do
  if readelf -h "$FILE" >/dev/null 2>&1; then
    ELF_FILES+=("$FILE")
  fi
done < <(find squashfs-root -type f -print0)

BUNDLED=" "
for FILE in "${ELF_FILES[@]}"; do
  BUNDLED+="$(basename "$FILE") "
  SONAME="$(readelf -d "$FILE" | sed -n 's/.*(SONAME).*\[\(.*\)\]/\1/p')"
  [ -n "$SONAME" ] && BUNDLED+="$SONAME "
done

version_gt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

ERRORS=0
USED_HOST_LIBS=()
for FILE in "${ELF_FILES[@]}"; do
  NAME="$(basename "$FILE")"
  for NEEDED in $(readelf -d "$FILE" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
    if [[ "$BUNDLED" == *" $NEEDED "* || " ${IGNORED[*]} " == *" $NAME:$NEEDED "* ]]; then
      continue
    fi
    if [[ " ${HOST_LIBS[*]} " == *" $NEEDED "* ]]; then
      USED_HOST_LIBS+=("$NEEDED")
    else
      echo "::error::$NAME needs $NEEDED which is neither bundled nor in HOST_LIBS"
      ERRORS=$((ERRORS + 1))
    fi
  done

  SYMBOLS="$(objdump -T "$FILE" 2>/dev/null || true)"
  GLIBC="$(grep -oE 'GLIBC_[0-9]+(\.[0-9]+)+' <<<"$SYMBOLS" | sed 's/GLIBC_//' | sort -uV | tail -n1 || true)"
  if [ -n "$GLIBC" ] && version_gt "$GLIBC" "$MAX_GLIBC"; then
    echo "::error::$NAME needs GLIBC_$GLIBC, newer than GLIBC_$MAX_GLIBC"
    ERRORS=$((ERRORS + 1))
  fi
  GLIBCXX="$(grep -oE 'GLIBCXX_[0-9]+(\.[0-9]+)+' <<<"$SYMBOLS" | sed 's/GLIBCXX_//' | sort -uV | tail -n1 || true)"
  if [ -n "$GLIBCXX" ] && version_gt "$GLIBCXX" "$MAX_GLIBCXX"; then
    echo "::error::$NAME needs GLIBCXX_$GLIBCXX, newer than GLIBCXX_$MAX_GLIBCXX"
    ERRORS=$((ERRORS + 1))
  fi
done

echo "Checked ${#ELF_FILES[@]} ELF files. Host libraries in use:"
printf '%s\n' "${USED_HOST_LIBS[@]}" | sort -u | sed 's/^/  /'

if [ "$ERRORS" -gt 0 ]; then
  echo "$ERRORS dependency problem(s) found" >&2
  exit 1
fi

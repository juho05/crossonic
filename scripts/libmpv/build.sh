#!/usr/bin/env bash
# Usage: scripts/libmpv/build.sh <output-dir>
# Builds an audio-only LGPL libmpv with FFmpeg, libplacebo and libass from source and writes
# libmpv.so.2 together with all non-system libraries it needs to <output-dir>.
set -euo pipefail

OUTPUT_DIR="$(mkdir -p "${1:?usage: $0 <output-dir>}" && cd "$1" && pwd)"
if [ -n "$(ls -A "$OUTPUT_DIR")" ]; then
  echo "$OUTPUT_DIR is not empty" >&2
  exit 1
fi

MESON_VERSION="1.12.1"
MESON_SHA256="ab0a6ca09f8ef70c564c8241fb5a23957886a0b53fb58412b5e07eaf07dba743"
FFMPEG_VERSION="8.1.3"
FFMPEG_SHA256="7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3"
LIBASS_VERSION="0.17.5"
LIBASS_SHA256="2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc"
LIBPLACEBO_VERSION="7.360.1"
LIBPLACEBO_SHA256="d05fdf90bea2f629eaa2d115e909fd356388ac639e54f77b87a018a6d76224bd"
MPV_VERSION="0.41.0"
MPV_SHA256="ee21092a5ee427353392360929dc64645c54479aefdb5babc5cfbb5fad626209"

# Libraries that are expected on every desktop system and must not be bundled.
SYSTEM_LIBS=(
  ld-linux-x86-64.so.2 libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1
  libstdc++.so.6 libgcc_s.so.1 libz.so.1 libgnutls.so.30
  libfreetype.so.6 libharfbuzz.so.0 libfribidi.so.0
  libasound.so.2 libpulse.so.0
)

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
PREFIX="$WORK_DIR/prefix"
JOBS="$(nproc)"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib"

fetch() {
  local url="$1" sha256="$2" dir="$WORK_DIR/$3"
  curl -fsSL --retry 3 -o "$WORK_DIR/archive" "$url"
  echo "$sha256  $WORK_DIR/archive" | sha256sum -c --quiet -
  mkdir -p "$dir"
  tar -xf "$WORK_DIR/archive" -C "$dir" --strip-components=1
  rm "$WORK_DIR/archive"
}

fetch "https://github.com/mesonbuild/meson/releases/download/$MESON_VERSION/meson-$MESON_VERSION.tar.gz" "$MESON_SHA256" meson
fetch "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz" "$FFMPEG_SHA256" ffmpeg
fetch "https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.xz" "$LIBASS_SHA256" libass
fetch "https://github.com/haasn/libplacebo/archive/refs/tags/v$LIBPLACEBO_VERSION.tar.gz" "$LIBPLACEBO_SHA256" libplacebo
fetch "https://github.com/mpv-player/mpv/archive/refs/tags/v$MPV_VERSION.tar.gz" "$MPV_SHA256" mpv

meson() {
  python3 "$WORK_DIR/meson/meson.py" "$@"
}

(
  cd "$WORK_DIR/ffmpeg"
  # media_kit sets vid=no, so only audio components are ever used.
  AUDIO_DECODERS="$(sed -n '/\/\* audio codecs \*\//,/\/\* subtitles \*\//s/.*ff_\(.*\)_decoder;.*/\1/p' \
    libavcodec/allcodecs.c | paste -sd,)"
  [ -n "$AUDIO_DECODERS" ]
  AUDIO_PARSERS="aac,aac_latm,ac3,adx,ahx,amr,cook,dca,dolby_e,dvaudio,flac,ftr,g723_1,g729,gsm,misc4"
  AUDIO_PARSERS+=",mlp,mpegaudio,opus,sbc,sipr,tak,vorbis,xma"
  AUDIO_DEMUXERS="aac,ac3,aiff,amr,ape,apac,asf,au,bonk,caf,dsf,dts,dtshd,eac3,flac,hls,iff,laf,loas"
  AUDIO_DEMUXERS+=",matroska,mlp,mov,mp3,mpc,mpc8,mpegts,ogg,oma,osq,qoa,rka,rm,shorten,tak,truehd,tta"
  AUDIO_DEMUXERS+=",w64,wavarc,wav,wv,xwma"
  ./configure --prefix="$PREFIX" --libdir="$PREFIX/lib" \
    --enable-shared --disable-static --enable-pic \
    --disable-programs --disable-doc --disable-debug \
    --disable-avdevice --disable-encoders --disable-muxers \
    --disable-decoders --enable-decoder="$AUDIO_DECODERS" \
    --disable-parsers --enable-parser="$AUDIO_PARSERS" \
    --disable-demuxers --enable-demuxer="$AUDIO_DEMUXERS" \
    --disable-hwaccels --disable-indevs --disable-outdevs \
    --disable-autodetect --enable-gnutls --enable-zlib
  make -j"$JOBS"
  make install
)

(
  cd "$WORK_DIR/libass"
  ./configure --prefix="$PREFIX" --libdir="$PREFIX/lib" \
    --enable-shared --disable-static \
    --disable-fontconfig --disable-require-system-font-provider --disable-libunibreak
  make -j"$JOBS"
  make install
)

(
  cd "$WORK_DIR/libplacebo"
  meson setup build --prefix="$PREFIX" --libdir=lib --buildtype=release \
    -Dvulkan=disabled -Dopengl=disabled -Dglslang=disabled -Dshaderc=disabled \
    -Dlcms=disabled -Ddovi=disabled -Dlibdovi=disabled -Dunwind=disabled -Dxxhash=disabled \
    -Ddemos=false -Dtests=false
  meson install -C build
)

(
  cd "$WORK_DIR/mpv"
  meson setup build --prefix="$PREFIX" --libdir=lib --buildtype=release \
    -Dauto_features=disabled -Dgpl=false -Dlibmpv=true -Dcplayer=false -Dbuild-date=false \
    -Dlua=disabled -Dgl=disabled -Dpulse=enabled -Dalsa=enabled -Dzlib=enabled
  meson install -C build
)

# Copy libmpv and every library it needs from the prefix, refusing unknown system libraries.
QUEUE=(libmpv.so.2)
while [ "${#QUEUE[@]}" -gt 0 ]; do
  LIB="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")
  [ -e "$OUTPUT_DIR/$LIB" ] && continue
  cp -L "$PREFIX/lib/$LIB" "$OUTPUT_DIR/$LIB"
  for NEEDED in $(readelf -d "$OUTPUT_DIR/$LIB" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
    if [ -e "$PREFIX/lib/$NEEDED" ]; then
      QUEUE+=("$NEEDED")
    elif [[ ! " ${SYSTEM_LIBS[*]} " =~ " $NEEDED " ]]; then
      echo "$LIB depends on $NEEDED which is neither built nor in SYSTEM_LIBS" >&2
      exit 1
    fi
  done
done

for LIB in "$OUTPUT_DIR"/*.so*; do
  strip --strip-unneeded "$LIB"
  patchelf --set-rpath '$ORIGIN' "$LIB"
done

mkdir -p "$OUTPUT_DIR/licenses"
cp "$WORK_DIR/ffmpeg/COPYING.LGPLv2.1" "$OUTPUT_DIR/licenses/ffmpeg.txt"
cp "$WORK_DIR/libass/COPYING" "$OUTPUT_DIR/licenses/libass.txt"
cp "$WORK_DIR/libplacebo/LICENSE" "$OUTPUT_DIR/licenses/libplacebo.txt"
cp "$WORK_DIR/mpv/LICENSE.LGPL" "$OUTPUT_DIR/licenses/mpv.txt"

ls -l "$OUTPUT_DIR"

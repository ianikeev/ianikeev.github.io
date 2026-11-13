#!/usr/bin/env bash
# Render the whole favicon / app-icon set from two masters:
#   * a filled silhouette for the small tab icons
#   * a detailed / line-art drawing for the large opaque app tiles
#
#   ./bin/render-icons.sh                          # the defaults below
#   ./bin/render-icons.sh my-tab.svg my-tile.png   # or name them explicitly
#
# Requires: inkscape (for SVG masters) and ImageMagick 7 (`magick`).
# Re-run this after any change to the master artwork. Outputs are committed,
# so the build itself never needs inkscape.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC=${1:-assets/images/logo/niori-tab.svg}
# Optional second master for the large opaque tiles (apple-touch, android, mstile).
# Use a detailed / line-art drawing here; the tab icons above stay simple so they
# survive 16px. Falls back to SRC when absent.
TILE_SRC=${2:-assets/images/logo/niori_icon.png}
OUT=assets
TEAL='#0f766e'   # $main-color-1  (light tab strips, transparent background)
NAVY='#1b2a41'   # hero navy       (opaque app tiles, white glyph)
FAVICON_PCT=88   # tab icons: no launcher padding is added, so nearly fill the box
GLYPH_PCT=72     # app tiles: launchers crop/mask, so keep a safe margin

command -v magick >/dev/null || { echo "error: magick not found" >&2; exit 1; }
[[ -f $SRC ]] || { echo "error: no such file: $SRC" >&2; exit 1; }
if [[ ! -f $TILE_SRC ]]; then
  echo "warning: no tile master at $TILE_SRC - falling back to $SRC for the tiles." >&2
  echo "         a simple silhouette will make the large tiles look like the tab icon." >&2
  TILE_SRC=$SRC
fi

# rasterise SRC DEST  - inkscape for vectors, magick for rasters. Using magick on
# an SVG would silently fall back to its low-quality internal renderer.
rasterise() {
  case "$(printf %s "${1##*.}" | tr 'A-Z' 'a-z')" in
    svg) command -v inkscape >/dev/null || { echo "error: inkscape not found (needed for $1)" >&2; exit 1; }
         inkscape "$1" --export-type=png --export-filename="$2" --export-width=1024 >/dev/null ;;
    *)   magick "$1" -strip -background none -resize 1024x1024 "$2" ;;
  esac
}

RASTER=''
case "$(printf %s "${SRC##*.}" | tr 'A-Z' 'a-z')" in svg) ;; *) RASTER=1 ;; esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "==> rendering $SRC"
rasterise "$SRC" "$tmp/raw.png"
# Trim to the ink bounds so the size percentages below apply to the artwork
# itself, not to whatever padding happened to be in the source viewBox.
magick "$tmp/raw.png" -strip -trim +repage -resize 1024x1024 -background none \
  -gravity center -extent 1024x1024 "$tmp/master.png"

# Tile master: flatten onto white, invert to greyscale and use that as the ink
# mask, so dark ink becomes light on the navy tiles. This works for a filled
# silhouette (black shape -> bright mask) and for line art (dark strokes bright,
# white interior dark) alike.
echo "==> preparing tile master $TILE_SRC"
rasterise "$TILE_SRC" "$tmp/tile-raw.png"
magick "$tmp/tile-raw.png" -strip -background white -alpha remove -alpha off \
  -colorspace gray -negate -trim +repage -resize 1024x1024 -background black \
  -gravity center -extent 1024x1024 "$tmp/tile.png"

# Guard against a light-on-dark or blank tile master, which would negate to an
# empty mask and ship solid navy tiles without any warning.
ink=$(magick "$tmp/tile.png" -format '%[fx:mean]' info:)
awk -v i="$ink" 'BEGIN { if (i < 0.01) { print "error: tile master produced an almost empty ink mask (" i ") - is the artwork dark on a light background?" > "/dev/stderr"; exit 1 } }'
if awk -v i="$ink" 'BEGIN { exit !(i > 0.90) }'; then
  echo "warning: tile master ink mask is nearly solid ($ink) - the tiles may look like a blob." >&2
fi

# glyph() SIZE COLOUR OUT   - glyph in COLOUR, transparent background
glyph() {
  local size=$1 colour=$2 out=$3 g=$(( $1 * FAVICON_PCT / 100 ))
  magick "$tmp/master.png" -resize "${g}x${g}" -background none \
    -gravity center -extent "${size}x${size}" -alpha extract "$tmp/mask.png"
  magick -size "${size}x${size}" "xc:$colour" "$tmp/mask.png" \
    -alpha off -compose CopyOpacity -composite -depth 8 "$out"
}

# tile() WxH BGCOLOUR OUT   - light glyph on an opaque background
# (narrowest side drives the glyph size, so the 310x150 tile stays centred)
tile() {
  local w=${1%x*} h=${1#*x} bg=$2 out=$3
  local g=$(( (w < h ? w : h) * GLYPH_PCT / 100 ))
  magick "$tmp/tile.png" -resize "${g}x${g}" -background black \
    -gravity center -extent "${w}x${h}" -alpha off "$tmp/mask.png"
  magick -size "${w}x${h}" xc:white "$tmp/mask.png" \
    -alpha off -compose CopyOpacity -composite "$tmp/ink.png"
  magick -size "${w}x${h}" "xc:$bg" "$tmp/ink.png" \
    -compose Over -composite -depth 8 "$out"
}

echo "==> browser icons (transparent teal)"
glyph 16 "$TEAL" "$OUT/favicon-16x16.png"
glyph 32 "$TEAL" "$OUT/favicon-32x32.png"
glyph 48 "$TEAL" "$tmp/favicon-48.png"
magick "$OUT/favicon-16x16.png" "$OUT/favicon-32x32.png" "$tmp/favicon-48.png" "$OUT/favicon.ico"

echo "==> app tiles (opaque navy, white glyph)"
tile 180x180 "$NAVY" "$OUT/apple-touch-icon.png"
tile 192x192 "$NAVY" "$OUT/android-chrome-192x192.png"
tile 512x512 "$NAVY" "$OUT/android-chrome-512x512.png"
tile 70x70   "$NAVY" "$OUT/mstile-70x70.png"
tile 144x144 "$NAVY" "$OUT/mstile-144x144.png"
tile 150x150 "$NAVY" "$OUT/mstile-150x150.png"
tile 310x310 "$NAVY" "$OUT/mstile-310x310.png"
tile 310x150 "$NAVY" "$OUT/mstile-310x150.png"

echo "==> svg icon + safari pinned tab"
if [ -n "$RASTER" ]; then
  # Leaving these behind would ship the previous run's vector art while the
  # head include links them unconditionally.
  rm -f "$OUT/favicon.svg" "$OUT/safari-pinned-tab.svg"
  echo "    removed favicon.svg + safari-pinned-tab.svg: a raster master cannot" >&2
  echo "    produce them - both need vector paths. Supply an SVG for those two." >&2
else
  # Strip comments and every fill, then set one on the root: works whatever
  # colour the master uses, and never ships an unresolved currentColor.
  strip_fills() {
    sed -E '/<!--/,/-->/d; s/ fill="[^"]*"//g' | sed -E "s/<svg /<svg fill=\"$1\" /; s/<svg>/<svg fill=\"$1\">/"
  }
  strip_fills "$TEAL" < "$SRC" > "$OUT/favicon.svg"
  strip_fills '#000' < "$SRC" > "$OUT/safari-pinned-tab.svg"
  for f in "$OUT/favicon.svg" "$OUT/safari-pinned-tab.svg"; do
    [[ -s "$f" ]] || { echo "error: $f is empty - check the transform" >&2; exit 1; }
    if grep -q 'currentColor' "$f"; then
      echo "error: $f still contains currentColor - fix the transform" >&2; exit 1
    fi
    if ! grep -qE 'fill="(#0f766e|#000)"' "$f"; then
      echo "error: $f has no explicit root fill - the svg root tag was not matched (multi-line tag?)" >&2
      exit 1
    fi
    if grep -qiE '<linearGradient|<radialGradient|<image|<style|stroke=' "$f"; then
      echo "warning: $f keeps gradients/strokes - check it by hand" >&2
    fi
  done
fi

echo
echo "done - $(ls -1 "$OUT"/favicon* "$OUT"/apple-touch-icon.png "$OUT"/android-chrome-* "$OUT"/mstile-* "$OUT"/safari-pinned-tab.svg 2>/dev/null | wc -l) files written to $OUT/"
echo "note: _includes/svg/logo.svg (the header mark) comes from bin/trace-silhouette.py, not this script."

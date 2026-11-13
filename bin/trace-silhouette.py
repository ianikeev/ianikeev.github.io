#!/usr/bin/env python3
"""Turn raster line art into the two vector marks the site needs.

One drawing cannot serve both ends of the size range:

* At 16px the linework merges into a blob, so the tab icon needs shapes that are
  separated by *design* - the artwork's own clove seams, widened to a fixed
  share of the icon and carved out of the silhouette.
* At 44px (the header mark) the linework reads perfectly well, and losing it
  would throw away the whole point of the drawing, so that is traced as-is.

Writes, from one piece of artwork, so they cannot drift apart:
  assets/images/logo/niori-tab.svg   seamed mark, for bin/render-icons.sh
  _includes/svg/logo.svg             full linework, inline, fill: currentColor

  ./bin/trace-silhouette.py                        # defaults below
  ./bin/trace-silhouette.py art.png tab.svg        # other artwork

Knobs: GAP_PCT (how wide the seams become, as a share of the icon),
EPSILON (simplification tolerance in source pixels), MIN_AREA (speck filter),
THRESHOLD (ink cut-off). Requires ImageMagick for the masks; stdlib otherwise.
"""
import math
import shutil
import subprocess
import sys
import tempfile

SRC = sys.argv[1] if len(sys.argv) > 1 else 'assets/images/logo/niori_icon.png'
OUT_TAB = sys.argv[2] if len(sys.argv) > 2 else 'assets/images/logo/niori-tab.svg'
OUT_HEADER = '_includes/svg/logo.svg'

BOX = 32.0        # viewBox of both outputs
SEAM_PCT = 8.0    # how wide each carved seam becomes, as a % of the icon width
SEAM_KEEP = 3     # how many interior seams to keep (the rest is fine detail)
SEAM_SEP_PCT = 12 # minimum spacing between kept seams, as a % of the icon width
EPSILON = 1.4         # seam-mark simplification tolerance, source pixels
MIN_AREA = 60.0       # drop seam-mark contours smaller than this, source px^2
EPSILON_DETAIL = 2.4  # linework tolerance: keeps the inline header mark light
MIN_AREA_DETAIL = 40.0 # drop linework specks smaller than this, source px^2
THRESHOLD = 50    # ink cut-off (percent)


def magick(*args):
    return subprocess.run(['magick'] + list(args), capture_output=True, check=True).stdout


def size_of(path):
    out = subprocess.run(['magick', 'identify', '-format', '%w %h', path],
                         capture_output=True, check=True, text=True).stdout.split()
    return int(out[0]), int(out[1])


def masks(path, w, h, tmp):
    """Return (bulb silhouette, dark-ink strokes) as byte planes."""
    alpha = f'{tmp}/alpha.png'
    ink = f'{tmp}/ink.png'
    magick(path, '-strip', '-alpha', 'extract', '-threshold', f'{THRESHOLD}%', alpha)
    magick(path, '-strip', '-background', 'white', '-alpha', 'remove', '-alpha', 'off',
           '-colorspace', 'gray', '-threshold', f'{THRESHOLD}%', '-negate', ink)
    return magick(alpha, '-depth', '8', 'gray:-'), magick(ink, '-depth', '8', 'gray:-')


def seam_tracks(bulb, ink, w, h):
    """Group the drawing's interior strokes into a few vertical seam paths.

    Only strokes strictly inside the bulb count - the outermost runs are the
    outline, and the silhouette already carries those. Samples are clustered by
    x with a gap threshold, so one curved clove line stays one track instead of
    fragmenting across fixed bins.
    """
    samples, rows_with_ink = [], 0
    for y in range(h):
        base = y * w
        runs, start = [], None
        for x in range(w):
            opaque = bulb[base + x] >= 128
            dark = ink[base + x] >= 128
            if dark and start is None and opaque:
                start = x
            elif start is not None and (not dark or not opaque):
                runs.append((start, x - 1))
                start = None
        if start is not None:
            runs.append((start, w - 1))
        if not runs:
            continue
        rows_with_ink += 1
        for a, b in (runs[1:-1] if len(runs) > 2 else []):
            if b - a >= 1:                      # ignore single-pixel noise
                samples.append((y, (a + b) / 2.0))
    if not samples:
        return [], rows_with_ink

    # Cluster sample x positions: consecutive values closer than `gap` belong to
    # the same stroke, however much it curves.
    gap = w * 0.06
    xs = sorted({round(x) for _, x in samples})
    groups, current = [], [xs[0]]
    for x in xs[1:]:
        if x - current[-1] <= gap:
            current.append(x)
        else:
            groups.append(current)
            current = [x]
    groups.append(current)

    margin = w * 0.015
    ranked = []
    for group in groups:
        lo, hi = min(group) - margin, max(group) + margin
        members = [(y, x) for y, x in samples if lo <= x <= hi]
        support = len({y for y, _ in members})
        if support:
            ranked.append((support, (min(group) + max(group)) / 2.0, members))
    ranked.sort(key=lambda r: -r[0])

    min_support = max(8, rows_with_ink // 10)
    width_spread = w * 0.08
    min_sep = w * SEAM_SEP_PCT / 100.0
    paths, taken = [], []
    for support, centre, members in ranked:
        if support < min_support:
            continue
        if any(abs(centre - c) < min_sep for c in taken):
            continue
        taken.append(centre)
        by_row = {}
        for y, x in members:
            # Assign each row to its nearest kept centre, so two nearby strokes
            # cannot be averaged into a seam painted through blank interior.
            if min(taken, key=lambda c: abs(x - c)) != centre:
                continue
            by_row.setdefault(y, []).append(x)
        # A row whose samples spread across the bulb is not one stroke.
        track = [(y, sum(v) / len(v)) for y, v in sorted(by_row.items())
                 if max(v) - min(v) <= width_spread]
        if len(track) >= max(4, rows_with_ink // 10):
            paths.append(track)
        if len(paths) >= SEAM_KEEP:
            break
    return paths, rows_with_ink


def build_mask(path, w, h, tmp):
    """Bulb silhouette minus widened interior seams, as rows of 0/1."""
    bulb, ink = masks(path, w, h, tmp)
    tracks, _ = seam_tracks(bulb, ink, w, h)
    half = max(1, round(w * SEAM_PCT / 200.0))

    # Paint each track into a seam mask, then clear it out of the silhouette.
    # Tracks are near-vertical by construction, so a per-row span is exactly a
    # round-capped stroke of width 2*half, without needing an SVG round-trip.
    seams = bytearray(w * h)
    for track in tracks:
        for y, x in track:
            base = y * w
            for px in range(max(0, int(x - half)), min(w, int(x + half) + 1)):
                seams[base + px] = 1

    return [[255 if (bulb[y * w + x] >= 128 and not seams[y * w + x]) else 0
             for x in range(w)] for y in range(h)], len(tracks)


def contours(rows, w, h):
    """Marching-squares contours of the mask: a list of closed loops."""
    top = lambda x, y: (x + 0.5, float(y))
    right = lambda x, y: (float(x + 1), y + 0.5)
    bottom = lambda x, y: (x + 0.5, float(y + 1))
    left = lambda x, y: (float(x), y + 0.5)
    table = {
        1: [(left, top)], 2: [(top, right)], 3: [(left, right)],
        4: [(right, bottom)], 5: [(left, top), (right, bottom)],
        6: [(top, bottom)], 7: [(left, bottom)], 8: [(bottom, left)],
        9: [(bottom, top)], 10: [(top, right), (bottom, left)],
        11: [(right, bottom)], 12: [(right, left)], 13: [(top, right)],
        14: [(left, top)],
    }
    segs = []
    for y in range(h - 1):
        r0, r1 = rows[y], rows[y + 1]
        for x in range(w - 1):
            case = ((r0[x] >= 128) | ((r0[x + 1] >= 128) << 1)
                    | ((r1[x + 1] >= 128) << 2) | ((r1[x] >= 128) << 3))
            for make in table.get(case, ()):
                segs.append((make[0](x, y), make[1](x, y)))

    # Chain the segments into closed loops.
    adj = {}
    for a, b in segs:
        adj.setdefault(a, []).append(b)
        adj.setdefault(b, []).append(a)
    loops, used = [], set()
    for start in adj:
        for first in adj[start]:
            if (start, first) in used:
                continue
            loop, cur, prev = [start], first, start
            used.add((start, first)); used.add((first, start))
            while cur != start:
                loop.append(cur)
                nxt = [p for p in adj[cur] if p != prev and (cur, p) not in used]
                if not nxt:
                    break
                prev, cur = cur, nxt[0]
                used.add((prev, cur)); used.add((cur, prev))
            if len(loop) > 2:
                loops.append(loop)
    return loops


def rdp(points, eps):
    if len(points) < 3:
        return points
    (x1, y1), (x2, y2) = points[0], points[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = math.hypot(dx, dy)
    worst, index = 0.0, 0
    for i in range(1, len(points) - 1):
        px, py = points[i]
        dist = (math.hypot(px - x1, py - y1) if norm == 0
                else abs(dy * px - dx * py + x2 * y1 - y2 * x1) / norm)
        if dist > worst:
            worst, index = dist, i
    if worst <= eps:
        return [points[0], points[-1]]
    return rdp(points[:index + 1], eps)[:-1] + rdp(points[index:], eps)


def area(loop):
    return abs(sum(loop[i][0] * loop[i - 1][1] - loop[i - 1][0] * loop[i][1]
                   for i in range(len(loop)))) / 2.0


def to_path(loops, box_bbox):
    minx, miny, maxx, maxy = box_bbox
    span = max(maxx - minx, maxy - miny)
    pad = BOX * 0.04
    scale = (BOX - 2 * pad) / span
    ox = (BOX - (maxx - minx) * scale) / 2 - minx * scale
    oy = (BOX - (maxy - miny) * scale) / 2 - miny * scale
    parts, nodes = [], 0
    for loop in loops:
        for i, (x, y) in enumerate(loop):
            parts.append(f'{"M" if i == 0 else "L"}{x * scale + ox:.2f} {y * scale + oy:.2f}')
            nodes += 1
        parts.append('Z')
    return ''.join(parts), nodes, len(loops)


def linework(ink, w, h):
    """Contours of the drawing's strokes - the detailed mark for larger sizes."""
    rows = [[ink[y * w + x] for x in range(w)] for y in range(h)]
    loops = []
    for loop in contours(rows, w, h):
        simplified = rdp(loop, EPSILON_DETAIL)
        if len(simplified) > 2 and area(simplified) >= MIN_AREA_DETAIL:
            loops.append(simplified)
    loops.sort(key=area, reverse=True)
    return loops


def main():
    w, h = size_of(SRC)
    tmp = tempfile.mkdtemp(prefix='.trace-', dir='.')
    try:
        bulb, ink = masks(SRC, w, h, tmp)
        seamed, kept = build_mask(SRC, w, h, tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    def emit(path, loops, fill, comment, box_bbox):
        d, nodes, count = to_path(loops, box_bbox)
        if fill == 'currentColor':
            sizing = ' width="24px" height="24px" aria-hidden="true"'
        else:
            sizing = ' role="img" aria-label="Niori"'
        svg = ''.join([
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {BOX:g} {BOX:g}"',
            sizing, '>\n',
            '  <!-- GENERATED by bin/trace-silhouette.py from ', SRC,
            ' - do not hand-edit.\n',
            '       ', comment, ' -->\n',
            '  <path fill="', fill, '" fill-rule="evenodd" d="', d, '"/>\n',
            '</svg>\n',
        ])
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(svg)
        return count, nodes

    tab_loops = []
    for loop in contours(seamed, w, h):
        simplified = rdp(loop, EPSILON)
        if len(simplified) > 2 and area(simplified) >= MIN_AREA:
            tab_loops.append(simplified)
    if not tab_loops:
        raise SystemExit('error: no contours found - is the artwork dark on a light background?')
    tab_loops.sort(key=area, reverse=True)

    xs = [x for x in range(w) if any(bulb[y * w + x] >= 128 for y in range(h))]
    ys = [y for y in range(h) if any(bulb[y * w + x] >= 128 for x in range(w))]
    box_bbox = (min(xs), min(ys), max(xs), max(ys))

    detail_loops = linework(ink, w, h)
    if not detail_loops:
        raise SystemExit('error: no linework found - is the artwork dark on a light background?')

    if not kept:
        print('warning: no interior seams found - the tab mark is a plain silhouette.\n'
              '         Adjust SEAM_PCT / SEAM_SEP_PCT if the artwork does have clove lines.',
              file=sys.stderr)
    print(f'traced {SRC} ({w}x{h})')
    n = emit(OUT_TAB, tab_loops,
             '#000',
             f'Outline of the artwork with {kept} of its own clove seams carved out,\n'
             '       so the cloves stay separate instead of merging at small sizes.',
             box_bbox)
    print(f'  tab       {n[0]} contours, {n[1]} nodes -> {OUT_TAB}')
    n = emit(OUT_HEADER, detail_loops,
             'currentColor',
             'The full linework: the header mark renders at ~44px, where the\n'
             '       detail reads. fill: currentColor lets _sass/custom.scss pick the\n'
             '       colour per header theme.',
             box_bbox)
    print(f'  linework  {n[0]} contours, {n[1]} nodes -> {OUT_HEADER}')


main()

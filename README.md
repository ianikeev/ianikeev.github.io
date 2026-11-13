# twoladsandacat.com - site skeleton (Jekyll + TeXt theme, self-contained)

This repository is a COMPLETE, ready-to-run Jekyll site: the full TeXt
theme (layouts, includes, styles, data) is committed here, so it builds
locally with plain `bundle exec jekyll serve` and on GitHub Pages
without `remote_theme` or theme-gem whitelisting.

## What is inside

| Path | Purpose |
|------|---------|
| `_layouts/`, `_includes/`, `_sass/`, `assets/`, `_data/` | The TeXt theme runtime files (untouched except `_data/navigation.yml`, `_data/licenses.yml`, `_includes/head/favicon.html`, `_includes/svg/logo.svg` and `_sass/custom.scss`). |
| `_sass/skins/_clinic.scss` | Custom "clinic" skin (calm teal/navy), activated by `text_skin: clinic`. |
| `index.md` | Landing page — dark hero, "the project" panel, latest 3 posts, quiet links to the rest. |
| `building.md` | `/building/` — what the app is, its constraints, and its status. |
| `blog.md` | Blog listing at `/blog/` - all posts via the `articles` layout. |
| `fiction.md` | Fiction index at `/fiction/` - card grid of everything in `_fiction/`. |
| `_fiction/` | Stories; each file becomes `/fiction/<file-name>/` (layout + sidebar from `_config.yml` defaults). |
| `_posts/` | Blog posts, `YYYY-MM-DD-title.md`; the `article` layout comes from defaults. |
| `downloads/index.md` | Downloads placeholder at `/downloads/` (not in the nav until there is a file). |
| `about.md` | About page at `/about/`. |
| `404.html`, `archive.html` | Error page and date archive (theme layouts). |
| `_config.yml` | Site settings adapted from the theme's canonical config. |
| `assets/images/logo/niori_icon.png` | **Source artwork** for the site mark (line art). Everything else in the icon set is generated from it. |
| `assets/images/logo/niori-tab.svg` | Generated filled silhouette of that artwork — the tab-icon master. |
| `bin/trace-silhouette.py` | Derives the silhouette + header mark from the artwork. Not published (in `exclude:`). |
| `bin/render-icons.sh` | Renders every favicon/app icon from the silhouette and the artwork. Not published (in `exclude:`). |
| `Gemfile` | jekyll + feed/sitemap/paginate/jemoji + webrick (needed by `jekyll serve` on Ruby 3+). |

## Icons

Everything comes from **one piece of artwork**, but it cannot be used as-is at
both ends of the size range. Measured on this artwork: at 44px the linework is
fully legible, at 16px it collapses into an unreadable blob. So
`bin/trace-silhouette.py` derives two vector marks from it, and
`bin/render-icons.sh` renders the raster set.

| File | Role |
|---|---|
| `assets/images/logo/niori_icon.png` | **Source artwork** (line art). The only file to replace. |
| `_includes/svg/logo.svg` | *Generated* — the **full linework**, inline, `fill: currentColor`. Renders at ~44px in the header, where the detail reads. |
| `assets/images/logo/niori-tab.svg` | *Generated* — the outline with its **own clove seams carved out**, widened to a fixed share of the icon. Drives 16/32 PNGs, `favicon.ico`, `favicon.svg`, `safari-pinned-tab.svg`. |
| `assets/apple-touch-icon.png`, `android-chrome-*`, `mstile-*` | *Generated* tiles from the raw artwork, opaque navy with a light glyph. |

After replacing the artwork, run both steps:

```bash
./bin/trace-silhouette.py    # artwork -> header linework + seamed tab mark
./bin/render-icons.sh        # seamed mark + artwork -> 13 icon files
```

`render-icons.sh` needs inkscape and ImageMagick 7; `trace-silhouette.py` needs
only ImageMagick. Tab icons come out transparent teal, tiles opaque navy, and
`safari-pinned-tab.svg` flat black because Safari recolours it itself. All
output is committed, so **the build never needs either tool** and GitHub Pages
never runs them.

Why the seams are *carved* rather than drawn: a 16px icon has room for roughly
1px of gap, so the drawing's own strokes have to be widened to a fixed share of
the icon — widening all of them at once swallows the bulb. Only the strongest
few interior strokes are kept as seams (found by clustering the artwork's
interior stroke positions), which leaves 2–3 cloves visible at 16px.

The artwork must be **dark ink on a light or transparent background**: the tab
seams are found from the dark strokes, and the tiles invert luminance (which is
what turns dark strokes into a light glyph on navy).

Knobs: `TEAL` / `NAVY` / `FAVICON_PCT` / `GLYPH_PCT` in `render-icons.sh`, and
`SEAM_PCT` (seam width) / `SEAM_KEEP` (how many seams) / `SEAM_SEP_PCT`
(minimum spacing) / `EPSILON`+`MIN_AREA` (tab mark) / `EPSILON_DETAIL`+
`MIN_AREA_DETAIL` (inline linework weight) / `BOX` / `THRESHOLD` in
`trace-silhouette.py`.

The header mark is drawn at 36px (`_sass/custom.scss`) rather than the theme's
~30px, because the traced clove lines need the extra room to read.

## Run locally

```bash
bundle install
bundle exec jekyll serve
# open http://localhost:4000
```

## Publish

Commit everything (including `_layouts/` and friends) and push to the
repository that GitHub Pages serves. No `remote_theme` line is needed
or wanted in `_config.yml`.

## Extend

- New story: add `my-story.md` to `_fiction/`; add a child entry under
  `fiction:` in `_data/navigation.yml` so it appears in the sidebar.
- New post: add `YYYY-MM-DD-title.md` to `_posts/` (date must be in
  the past). It shows up on `/blog/` and in the latest-posts list on
  the landing page automatically.
- **App name: `app.name` in `_config.yml`** (currently `Niori`).
  It appears on `/`, `/building/` and `/about/`; change that one line
  and all three follow.
- **Content licence: `license` in `_config.yml`** (currently
  `CC-BY-NC-SA-4.0`), shown in each post's footer. The key must exist
  in `_data/licenses.yml` or the block silently renders nothing —
  add an entry there for any licence not already listed.
- Downloads: drop files in `assets/downloads/`, link them from
  `downloads/index.md`, and add it back to `_data/navigation.yml`.
- Hero background image: add `background_image: { src: /assets/img/... }`
  under `article_header:` in `index.md`.
- Branding: the header mark is `_includes/svg/logo.svg`, generated from the
  artwork by `bin/trace-silhouette.py` and drawn with `fill: currentColor`,
  so `_sass/custom.scss` sets its colour per header theme — it flips to white
  on dark headers automatically. Re-run the script rather than editing it.
- Accent colours live in `_sass/skins/_clinic.scss`. `_sass/custom.scss`
  is imported last, so it can restyle selectors but cannot redefine
  `$main-color-1` and friends — add a skin instead.

## Rules that keep this site building

1. Never set a `layout:` name that is not one of: 404, archive, article,
   articles, base, home, landing, none, page (see `_layouts/`).
2. Keep page bodies empty unless there is real content - everything
   below the front matter renders on the page.
3. Keep post dates in the past; Jekyll skips future-dated posts.

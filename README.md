# twoladsandacat.com - site skeleton (Jekyll + TeXt theme, self-contained)

This repository is a COMPLETE, ready-to-run Jekyll site: the full TeXt
theme (layouts, includes, styles, data) is committed here, so it builds
locally with plain `bundle exec jekyll serve` and on GitHub Pages
without `remote_theme` or theme-gem whitelisting.

## What is inside

| Path | Purpose |
|------|---------|
| `_layouts/`, `_includes/`, `_sass/`, `assets/`, `_data/` | The TeXt theme runtime files (untouched except `_data/navigation.yml`). |
| `index.md` | Homepage - `layout: landing` (hero banner + Fiction / Blog / Downloads sections). Body is intentionally empty. |
| `blog.md` | Blog listing at `/blog/` - all posts via the `articles` layout. |
| `fiction.md` | Fiction index at `/fiction/` - card grid of everything in `_fiction/`. |
| `_fiction/` | Stories; each file becomes `/fiction/<file-name>/` (layout + sidebar from `_config.yml` defaults). |
| `_posts/` | Blog posts, `YYYY-MM-DD-title.md`; the `article` layout comes from defaults. |
| `downloads/index.md` | Downloads placeholder at `/downloads/`. |
| `about.md` | About page at `/about/`. |
| `404.html`, `archive.html` | Error page and date archive (theme layouts). |
| `_config.yml` | Site settings adapted from the theme's canonical config. |
| `Gemfile` | jekyll + feed/sitemap/paginate/jemoji + webrick (needed by `jekyll serve` on Ruby 3+). |

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
  the past).
- Downloads: drop files in `assets/downloads/` and link them from
  `downloads/index.md`.
- Hero background image: add `background_image: { src: /assets/img/... }`
  under `article_header:` in `index.md`.

## Rules that keep this site building

1. Never set a `layout:` name that is not one of: 404, archive, article,
   articles, base, home, landing, none, page (see `_layouts/`).
2. Keep page bodies empty unless there is real content - everything
   below the front matter renders on the page.
3. Keep post dates in the past; Jekyll skips future-dated posts.

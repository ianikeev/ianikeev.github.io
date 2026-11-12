# Starter files for twoladsandacat.com (Jekyll + TeXt theme)

Copy these files into your repository root. They merge cleanly with the
existing theme files.

## What is included

| File | Purpose |
|------|---------|
| `_config.yml` | Site settings, blog pagination, fiction collection. Merge into your existing config if you cloned the full theme. |
| `_data/navigation.yml` | Header menu (Home/Blog/Fiction/Downloads/About) + fiction sidebar menu. |
| `index.md` | Landing page (`layout: landing`). Comment at the bottom shows the one-line switch to a blog-style homepage. |
| `blog.md` | Blog listing - all posts via the `articles` layout. |
| `fiction.md` | Fiction index - card grid of everything in `_fiction/`. |
| `_fiction/the-first-story.md` | Sample story. Layout + sidebar come from the `defaults` block. |
| `_posts/2026-11-13-welcome-to-twoladsandacat.md` | Sample post. |
| `downloads/index.md` | Downloads placeholder page. |
| `about.md` | About page. |

## Install steps

1. Copy the files into your repository root (keep the folder structure).
2. Edit `_config.yml`: set `author.name`, and merge values into your
   existing config if you cloned the full theme repository.
3. Preview: `bundle exec jekyll serve` then open http://localhost:4000
4. Commit and push - GitHub Pages rebuilds automatically.

## Notes

- `_config.yml` and `_data/navigation.yml` must exist before the pages
  that reference them (fiction collection, sidebar menu).
- The fictional sidebar grows automatically: add a new child entry in
  `_data/navigation.yml` when you add a story (or navigate via the
  fiction index instead).

# Starter files v2 for twoladsandacat.com (Jekyll + TeXt theme)

This package FIXES the homepage bug in v1.

## What was wrong

In v1, `index.md` carried instructional text BELOW its YAML front matter.
In Jekyll, everything below the front matter `---` markers is the page
body, and every TeXt layout renders the body as visible content. That is
why the note appeared on your homepage.

Rule to remember: a page file should contain ONLY front matter and
intentional content - never notes, unless you want them displayed.

## What changed in v2

| File | Change |
|------|--------|
| `index.md` | Rewritten: `layout: home` with a hero `article_header` and an EMPTY body. Shows a dark header + the paginated post list. |
| `landing-alternative.md` | New: optional pure landing page (`layout: landing`, empty body). Rename to `index.md` to use it. |
| `_data/navigation.yml` | Blog entry removed (homepage is now the blog list); comment shows how to re-add an Archive link. |
| `_fiction/the-first-story.md` | Placeholder meta-note removed from the visible story body. |
| `STARTER-README.md` | Updated with the fix explanation and this file map. |

Unchanged: `_config.yml`, `blog.md`, `fiction.md`, `downloads/index.md`,
`about.md`, and the sample post.

## Homepage options

- Option A (installed by default, recommended): `index.md` uses
  `layout: home` - hero header + paginated post list in one page.
- Option B (optional): rename `landing-alternative.md` to `index.md` for
  a dedicated landing page without the post list. Keep the body EMPTY.
  If its sections do not render as expected on your theme version,
  go back to Option A.

## Install / fix steps

1. Copy `index.md`, `landing-alternative.md`, `_data/navigation.yml`,
   and `_fiction/the-first-story.md` over your existing files.
2. Preview: `bundle exec jekyll serve` then open http://localhost:4000
3. Check the homepage (header + post list), /fiction/, /downloads/.
4. Commit and push - GitHub Pages rebuilds automatically.

## Notes

- If the two action buttons in the header do not render on your theme
  version, delete the `actions:` block in `index.md` - the header still
  works without it.
- `_config.yml` and `_data/navigation.yml` must be present before pages
  that reference them (fiction collection, sidebar menu).

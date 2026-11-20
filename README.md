# twoladsandacat.com

The source repository for [Two Lads and a Cat](https://twoladsandacat.com), a personal website about building Niori — a medical information manager — in the open, alongside fiction and other writing.

The site is built with [Eleventy](https://www.11ty.dev/) and [Grease](https://github.com/adamstddrd/grease), a lightweight starter with a responsive design, light and dark modes, and selectable themes.

## Requirements

- Node.js 24
- npm
- Emacs (required for publishing Org-mode files)
- GNU Texinfo (required for building the Niori manual)

The Org integration uses Emacs' built-in HTML exporter in batch mode. It runs during the Eleventy build; no Emacs packages or personal configuration are required. The Niori manual uses GNU Texinfo to generate website HTML and an Emacs Info manual.

## Getting started

Install dependencies:

```bash
npm ci
```

Start the local development server:

```bash
npm run start
```

Eleventy serves the site locally and watches for changes.

## Building

Build the production site:

```bash
npm run publish:prod
```

The generated site is written to `_public/`.

For a staging build:

```bash
npm run publish:stage
```

## Content

All site content lives in `_source/`.

| Path | Purpose |
|---|---|
| `_source/index.html` | Homepage |
| `_source/about.md` | About page |
| `_source/building.md` | Niori project overview |
| `_source/blog.html` | Blog listing |
| `_source/posts/` | Blog posts |
| `_source/fiction.html` | Fiction listing |
| `_source/fiction/` | Fiction and stories |
| `_source/downloads/` | Downloads page |
| `_source/archive.html` | Post archive |
| `_source/_data/` | Site configuration and navigation data |
| `_source/_layouts/` | Page layouts |
| `_source/_includes/` | Reusable template components |
| `_source/assets/` | CSS, JavaScript, images and fonts |
| `_source/_utilities/` | Build-time utilities, including the Org exporter |

### Adding a post

Create a Markdown file in `_source/posts/`, using the date in its filename:

```text
_source/posts/YYYY-MM-DD-title.md
```

For example:

```markdown
---
layout: post.html
title: My new post
date: 2026-11-20 09:00:00
categories: notes
tags: [example]
---

The post content goes here.

<!--more-->

The rest of the post goes here.
```

The `<!--more-->` marker separates the introductory excerpt from the full content in the Atom feed.

Post permalinks are generated from the category, date and filename, preserving the existing Jekyll URL structure.

### Adding fiction

Create a Markdown file in `_source/fiction/`:

```markdown
---
layout: fiction.html
title: My story
key: my-story
permalink: /fiction/my-story/
---

The story goes here.
```

The fiction listing is generated from the fiction collection.

### Writing in Org mode

Org files are supported as a native content format. Add an `.org` file under `_source/` and use normal Eleventy front matter for its metadata and layout.

The build invokes Emacs in batch mode to export Org content to HTML. Org export options can be set using normal Org directives, such as `#+OPTIONS:`.

## Site configuration

Site-wide data is kept in `_source/_data/`.

- `site.json` — site title and description.
- `app.json` — Niori's name, description and current status.
- `navigation.json` — header navigation.
- `modes.json` — available display modes.
- `themes.json` — available Grease themes.

The global Eleventy configuration, including collections, permalink handling and the Org extension, is in `eleventy.config.js`.

## Grease and frontend architecture

The site uses [Grease](https://github.com/adamstddrd/grease) as its frontend
starter. The project is customized locally; the website does not depend on
a remotely hosted Grease runtime.

The CSS is organized around cascade layers for foundational styles,
components and utilities. Components use compact BEM-like class conventions,
while layout utilities provide grid and flexbox composition. Custom media
queries define the responsive breakpoints.

Typography uses a fluid type scale and locally hosted fonts:

- Erewhon for body text.
- IBM Plex Sans for headings and interface elements.
- Inconsolata for code and preformatted text.

The color system supports independent light, dark and system display modes,
with selectable palettes: Modus, Modus Tinted, Ef Elea, Ef Maris and Ef Trio.
The Modus palettes are based on the CC0-licensed
[Modus themes](https://github.com/protesilaos/modus-themes).
The Ef palettes are based on
[Protesilaos's Ef themes](https://github.com/protesilaos/ef-themes).

JavaScript is organized into ES modules and bundled with esbuild. Grease's
existing utilities and components are adapted as needed by the site.

## Assets and icons

Static assets are stored in `_source/assets/`. The site uses a custom Niori icon, with PNG and ICO versions.

The root-level `CNAME` is copied into the Eleventy source as `_source/CNAME` and published to preserve the custom domain.

The web app manifest is `_source/site.webmanifest`.

## Feeds and discovery

The site generates:

- `/feed.xml` — Atom feed.
- `/sitemap.xml` — XML sitemap.
- `/404.html` — custom not-found page.

The sitemap excludes pages marked `noindex`.

## Publishing

GitHub Actions builds and deploys the site to GitHub Pages.

The workflow is `.github/workflows/deploy.yml`.

It runs when changes are pushed to `main`, or when manually triggered from the Actions tab. The workflow installs Node.js, Emacs and GNU Texinfo, runs `npm ci`, builds the production site and deploys `_public/`.

The custom domain is configured through the published `CNAME` file.

## Licences

The website's original software licence is MIT. Third-party notices for the Grease starter are recorded in `THIRD-PARTY-NOTICES.md`.

Blog posts are published under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International licence (CC BY-NC-SA 4.0).


## Niori manual

The canonical source for the Niori application manual is
`docs/niori.texi`. It is written in GNU Texinfo, which produces two
formats from the same source:

- HTML, embedded in the website documentation at `/docs/`.
- An Info manual at `docs/build/niori.info`, readable in Emacs.

Edit `docs/niori.texi` to update the manual. The
[GNU Texinfo manual](https://www.gnu.org/software/texinfo/manual/texinfo/)
explains the markup and cross-reference syntax.

Build both formats manually with:

```bash
npm run docs:build
```

The website's `start`, `publish:stage` and `publish:prod` commands run
this step automatically. After editing the Texinfo source while the
development server is running, run `npm run docs:build` again.

To read the generated manual in Emacs, run `M-x info`, press `g`, and
enter:

```text
(docs/build/niori.info)Top
```

The generated files are build artifacts and are not committed. The
`.texi` source is the version-controlled manual.

Org mode remains a separate format for individual website content;
Texinfo is the source format for the Niori application manual.

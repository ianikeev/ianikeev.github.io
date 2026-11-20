# twoladsandacat.com

The source repository for [Two Lads and a Cat](https://twoladsandacat.com), a personal website about building Niori — a medical information manager — in the open, alongside fiction and other writing.

The site is built with [Eleventy](https://www.11ty.dev/) and [Grease](https://github.com/adamstddrd/grease), a lightweight starter with a responsive design, light and dark modes, and selectable themes.

## Requirements

- Node.js 24
- npm
- Emacs (required for publishing Org-mode files)

The Org integration uses Emacs' built-in HTML exporter in batch mode. It runs during the Eleventy build; no Emacs packages or personal configuration are required.

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

## Assets and icons

Static assets are stored in `_source/assets/`. The site uses a custom Niori icon, with PNG and ICO versions.

The root-level `CNAME` is copied into the Eleventy source as `_source/CNAME` and published to preserve the custom domain.

The web app manifest is `_source/site.webmanifest`.

## Feeds and discovery

The site generates:

- `/feed.xml` — Atom feed.
- `/sitemap.xml` — XML sitemap.
- `/404.html` — custom not-found page.

The sitemap excludes pages marked `noindex`, including the documentation and kitchen-sink demo pages.

## Publishing

GitHub Actions builds and deploys the site to GitHub Pages.

The workflow is `.github/workflows/deploy.yml`.

It runs when changes are pushed to `main`, or when manually triggered from the Actions tab. The workflow installs Node.js and Emacs, runs `npm ci`, builds the production site and deploys `_public/`.

The custom domain is configured through the published `CNAME` file.

## Licences

The website's original software licence is MIT. Third-party notices for the Grease starter are recorded in `THIRD-PARTY-NOTICES.md`.

Blog posts are published under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International licence (CC BY-NC-SA 4.0).

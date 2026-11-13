---
layout: page
title: What I'm building
permalink: /building/
article_header:
  type: overlay
  align: center
  theme: dark
  height: 40vh
  background_color: "#1B2A41"
---

<!-- The project name is read from `app.name` in _config.yml; swap it there. -->

## The problem

Your medical history is scattered across clinic portals, PDFs, photos of paper
reports, emails, and your own memory. None of it talks to any of the rest of it,
and most of it lives in systems you cannot export from.

## The idea

**{{ site.app.name }}** — {{ site.app.one_liner }}. One place to collect your
own records, understand what is in them, and walk into an appointment with a
clear history instead of a folder of scans. Yours to keep, in a format you can
take with you.

I am writing the whole thing up as I go: what I decide, what I get wrong, and
why. That is what the [build log](/blog/) is.

## The constraints I am designing against

- **You own the data.** Export is a first-class feature, not a hostage
  negotiation.
- **Offline and local first.** A medical record should not stop working
  because a server is down or a subscription lapsed.
- **Dull where it counts.** Nothing clever decides what your medication list
  says. I would rather be boring and correct.
- **Readable in ten years.** Plain files, documented formats, no lock-in.

## Where it is

{{ site.app.status }} There is nothing to download yet — when there is,
it will show up here and in the build log.

## Follow along

- [The build log](/blog/) — progress, decisions, and dead ends.
- [All posts](/archive.html) — the same thing, by date.
- [About](/about/) — who is writing this.

---
layout: landing
title: Building in the open
excerpt: >-
  A medical information manager, built in public — decisions, dead ends,
  and the occasional tangent.
permalink: /
header:
  theme: dark
  background: "#1B2A41"
full_width: false
article_header:
  height: 60vh
  theme: dark
  background_color: "#1B2A41"
  actions:
    - text: Read the build log
      url: /blog/
      type: primary
    - text: What is it?
      url: /building/
      type: outline-theme-dark
---

<section class="landing-intro">
  <p class="landing-eyebrow">The project</p>
  <h2>{{ site.app.name }} — {{ site.app.one_liner }}</h2>
  <p>
    Medical information ends up scattered across PDFs, patient portals, emails
    and memory. I'm building one place where a person's own medical history
    lives together — and writing down every decision as I go, including the
    ones I get wrong.
  </p>
  <ul>
    <li><strong>The problem</strong> — your records belong to clinics, portals
      and inboxes, not to you.</li>
    <li><strong>Where it is</strong> — {{ site.app.status }}</li>
    <li><strong>How to follow</strong> — the <a href="/blog/">build log</a>,
      plus the occasional <a href="/fiction/">story</a>.</li>
  </ul>
  <p><a href="/building/">More on what I'm building →</a></p>
</section>

<section class="landing-posts">
  {%- assign recent = site.posts | slice: 0, 3 -%}
  <h2>Latest from the build log</h2>
  {%- if recent.size > 0 -%}
    {%- include article-list.html articles=recent type='brief' show_info=true -%}
  {%- else -%}
    <p>Nothing published yet — the first post is coming soon.</p>
  {%- endif -%}
  <p><a href="/blog/">All posts →</a></p>
</section>

<p class="landing-elsewhere">
  Also here: <a href="/fiction/">Fiction</a> ·
  <a href="/archive.html">Archive</a> ·
  <a href="/about/">About</a>
</p>

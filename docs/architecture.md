# Wonderland Architecture

Wonderland is a mostly-static personal blog built with Astro and Typst.

The project has one intentional runtime feature: comments backed by Cloudflare D1. Everything else should be treated as build-time or static output.

## System shape

- **Astro** orchestrates routing, layouts, content collections, RSS, sitemap, and Cloudflare deployment.
- **Typst** is the authoring and typesetting layer for articles and yearly PDF archives.
- **astro-typst / typst.ts / shiroa** render Typst-authored content into HTML during the build.
- **Cloudflare Workers** serves the site and runs comment-related server code.
- **Cloudflare D1** stores comments only.

## Boundaries

### Static content

These routes should be safe to prerender:

- article pages: `/article/...`
- article index pages: `/article/`, `/article/2/`, ...
- tag pages: `/tag/...`
- archive index: `/archive/`
- RSS and sitemap

### Build-time generation

These capabilities rely on local Node/native tooling and should not become Worker runtime dependencies:

- Typst-to-HTML article rendering
- Typst yearly archive and single-article PDF generation
- mathyml conversion
- shiroa template expansion

Native Typst compiler imports such as `@myriaddreamin/typst-ts-node-compiler` belong on the build side. Do not import them from comment routes or other runtime-only code.

### Runtime features

Runtime code should stay small and explicit:

- comment form submission
- comment list loading
- D1 access through the `DB` binding

If D1 is unavailable locally, article rendering should still be considered healthy; only the comment area should degrade.

## Content model

Articles live under:

```text
content/article/**/*.typ
```

Article metadata is emitted from Typst via `#metadata(...) <frontmatter>` and consumed by Astro content collections.

The intended source-of-truth rule is:

> Article metadata is the canonical source for title, description, date, tags, and collection membership. Tag pages, RSS, article lists, and yearly archives should be derived from article metadata whenever practical.

Yearly archive pages and PDFs now follow the same rule: they are derived from article metadata at build time, not from hand-maintained archive entry lists. Single-article PDFs are also prerendered from the same article sources and metadata, rather than compiled dynamically in the Cloudflare Worker runtime.

Run this after adding or editing articles:

```bash
bun run content:check
```

The checker verifies that article metadata is present and article tags are declared in the tag registry.

Yearly archive pages and PDFs are derived from article metadata during build. There is no hand-maintained `content/archive/YYYY.typ` article list: `/archive/` groups `getCollection("blog")` by year, and `/archive/YYYY.pdf` renders those same derived groups through `templates/archive.typ`.

Single-article PDFs use the same build-time boundary: `/article/<slug>.pdf` is prerendered from `content/article/**/*.typ` through `templates/article-pdf.typ`. The template includes the article's author, source URL, publication dates, tags, and copyright notice on the cover page and page footer.

## Tag model

Tags are intentionally managed from one central source:

```text
templates/enums.typ
```

Articles should reference tags through `blog-tags.<id>` from that file. Astro tag pages parse the same file through `src/utils/tags.ts`, so the Typst authoring layer and Astro UI share the same registry.

Run this after adding, renaming, or removing tags:

```bash
bun run tags:check
```

The checker verifies that tag IDs are valid, labels are unique, article tags reference the central registry, and inline string tags do not bypass `templates/enums.typ`.

This keeps authoring convenient inside `.typ` articles while preserving a single management point for tags. If tag usage grows enough to justify a neutral data file later, it should still remain one canonical registry that generates the Typst enum and TypeScript view, not two independently edited tag lists.

## Content rendering surfaces

Typst-rendered content can appear in multiple surfaces, and those surfaces should not all inherit article-detail behavior.

The rendering stack is intentionally split into layers:

- `ContentSurface.astro` loads a content collection entry and renders it through `astro:content`.
- `RenderedContent.astro` is the low-level body renderer. It accepts a `variant` and feature flags for generated TOC, heading hash links, and footnotes/sidenotes.
- `BlogPost.astro` owns the article-detail shell: title block, date, language/PDF controls, tags, comments, and back-to-top behavior. It uses `RenderedContent variant="article"`, where article affordances are enabled.
- Embedded contexts such as the homepage about card should use `ContentSurface variant="embed"`, where article-only affordances are disabled by default.

Default feature policy:

- `article`: `toc`, `headingLinks`, and `footnotes` are enabled.
- `embed` / `excerpt`: `toc`, `headingLinks`, and `footnotes` are disabled.

This keeps content reusable without copying Typst files or creating separate “preview” sources.

For arbitrary-part reuse, keep the selection responsibility in this same layer rather than scattered across pages. The intended API shape is:

```astro
<ContentSurface entry={post} variant="embed" part="body" />
<ContentSurface entry={post} variant="embed" part={{ section: "intro" }} />
<ContentSurface entry={post} variant="excerpt" features={{ footnotes: false }} />
```

`part="body"` means “the content body without article shell chrome”. Section/block selection should be implemented as an explicit semantic slice API on `ContentSurface`/`RenderedContent` (prefer named Typst/metadata markers or a build-time renderer helper), not by making each consuming page parse generated HTML ad hoc. The current home-page about embed uses this policy: it renders the about page body while disabling article-only features.

## Content listing and translation policy

Locale-specific list pages should show every logical article, not only entries that already have the current locale source file. Use `postsForLocale(posts, locale)` for homepage lists, article indexes, tag pages, RSS, and archive summaries. It selects one entry per `i18nKey`, preferring the requested locale and falling back to the source/available locale if a translation file is still missing.

Missing counterparts are not generated at runtime. Translation is an explicit source-generation stage:

```bash
bun run i18n:generate   # writes missing/stale machine translations
bun run i18n:complete   # generate, then enforce strict i18n completeness
```

The generation script writes committed `.typ` source files with `translationStatus: "machine"` and `translationSourceHash`, and it refuses to overwrite `translationStatus: "reviewed"` files unless forced. Human-authored source files may omit `translationStatus`; Astro content data, the i18n checker, and the translation script default missing status to `source`, so new articles remain translatable even if the field is forgotten. Normal `validate` still allows missing counterparts as warnings so structural work is not blocked by credentials; run `i18n:complete` when preparing a fully bilingual release.

## Typst template model

Typst templates are part of the rendering pipeline, not just article snippets.

Important files:

- `templates/blog.typ` — article entry template
- `templates/shared.typ` — common article metadata and render rules
- `templates/archive.typ` — yearly PDF archive template
- `templates/article-pdf.typ` — single-article PDF export template with source/copyright metadata
- `templates/mod.typ` — custom heading-link helper
- `templates/footnote.typ` — responsive sidenote/footnote renderer
- `templates/code/*` — code block theme integration

Third-party rendering dependencies such as shiroa should be version-aligned across templates. Mixing shiroa versions increases upgrade risk.

## Comments model

Comments are the only intended mutable user-generated data.

Current flow:

```text
CommentEdit.astro -> /api/comments/[...postSlug].ts -> D1 comments table
CommentList.astro <- D1 comments table
```

Migration/reset policy:

- migrations should describe schema changes;
- seeds should contain development sample data;
- destructive resets are local-development operations;
- remote destructive operations should not be exposed as convenient npm scripts.

The current `migrations/0001_init.sql` is still a local reset script because it drops and recreates the comments table. Treat it as local-only until migrations and seeds are split.

## Deployment model

The project currently uses Astro server output with the Cloudflare adapter:

```js
output: "server"
adapter: cloudflare(...)
```

Most pages are still prerendered. The server output exists primarily for comment-related runtime behavior.

Cloudflare adapter configuration and `wrangler.toml` are version-sensitive. In particular, generated Worker entry paths should not be assumed stable across major adapter versions.

## Near-term design cleanup

Priority order:

1. Keep dependencies pinned to the current Astro 5 line until a dedicated upgrade branch exists.
2. Keep D1 destructive reset local-only.
3. Keep shiroa versions aligned across all Typst templates.
4. Rename post-list components by responsibility rather than age, e.g. `PostList`, `PostListByYear`, `PostListItem`.
5. Derive archive pages/PDFs from article metadata rather than maintaining archive entry lists.

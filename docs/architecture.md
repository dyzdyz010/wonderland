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
- Typst yearly archive PDF generation
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

Current caveat: yearly archive Typst files still repeat article `title`, `date`, and `path` manually. This is accepted for now but should eventually be generated or checked by a script.

## Tag model

Tags are currently declared in `templates/enums.typ` as Typst values and parsed by `src/utils/tags.ts` for Astro pages.

This keeps authoring convenient inside `.typ` articles, but it means `templates/enums.typ` is also acting as site configuration. If tag usage grows, prefer moving tags to a neutral data file and generating both the Typst enum and TypeScript registry from that source.

## Typst template model

Typst templates are part of the rendering pipeline, not just article snippets.

Important files:

- `templates/blog.typ` — article entry template
- `templates/shared.typ` — common article metadata and render rules
- `templates/archive.typ` — yearly PDF archive template
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
5. Add content validation before automating archive generation.

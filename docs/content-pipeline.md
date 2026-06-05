# Content Pipeline Notes

This note records the current content-maintenance pipeline and the architectural reasoning behind recent source-of-truth cleanup.

## Current commands

The project currently exposes these content/data maintenance commands:

```bash
bun run tags:check       # validate the central tag registry and article tag usage
bun run content:check    # validate article metadata and declared tags
```

These commands support the source-of-truth rule documented in `docs/architecture.md`:

- article metadata is the canonical source for title/date/tag data;
- yearly archive pages and PDFs are derived from article metadata at build time;
- tags are managed from one central source, `templates/enums.typ`.

## Archive pipeline

Archive article lists are no longer hand-maintained under `content/archive/YYYY.typ`.

Instead:

- `/archive/` groups `getCollection("blog")` by article year;
- `/archive/YYYY.pdf` uses the same grouped article metadata;
- the PDF route writes a temporary Typst source file under `.astro/generated-archives/` during prerender;
- `templates/archive.typ` remains the yearly PDF layout/template, not a source of archive entries.

Archive PDFs use semantic PDF typography roles from `templates/pdf/typography.typ`:

- heading-like material uses `pdf-heading-fonts` (`Noto Sans CJK SC` / `Noto Sans SC` fallbacks);
- body-like article material uses `pdf-body-fonts` (`Noto Serif CJK SC` / `Noto Serif SC` fallbacks);
- small UI/meta text uses the heading/sans role via `pdf-ui-text`.

The PDF routes call `getTypstCompilerOptions()` from `src/utils/typst-fonts.ts`, which asserts that the required Noto CJK SC files exist under `assets/fonts/noto-cjk-sc/` and exposes that vendored directory to Typst. This keeps PDF generation deterministic and prevents builds from silently depending on fonts installed on the user's machine. Additional project-local font directories (`assets/fonts/` and `public/fonts/`) may still be exposed for future fonts, but the Noto PDF fonts are committed with the repository and tracked through Git LFS to keep normal Git history small.

## Single-article PDF pipeline

Each article also gets a prerendered PDF route at `/article/<slug>.pdf`.

The route:

- reads the same `blog` content collection entry as the HTML article page;
- writes a temporary Typst wrapper under `.astro/generated-article-pdfs/` during prerender;
- renders the original article source through `templates/article-pdf.typ`;
- shares the same semantic PDF typography roles as archive PDFs;
- preserves author, source URL, publication dates, tags, and a visible copyright notice in the PDF.

This intentionally stays build-time/static. Cloudflare Workers serve the generated PDF files; they do not compile Typst dynamically at request time.

This removes the need for `archive:check` and `archive:generate`. There is no archive list left to sync: if an article exists in `content/article/**/*.typ` with valid metadata, it participates in the archive and single-article PDF pipelines automatically.

## Why some scripts remain

The remaining check scripts are repo-local maintenance tools, not runtime features. They run in Node during development or CI and do not become Cloudflare Worker code.

They are intentionally separate from Astro rendering because they check project governance rules that are easier to express outside the renderer:

- articles should have required metadata;
- article tags should come from the central registry;
- `templates/enums.typ` should remain the single tag management point.

These checks can later be integrated into a higher-level validation command or into the default build once the project policy is settled.

## Recommended future integration

If the command surface starts to feel too fragmented, add one aggregate command such as:

```json
"validate": "bun run tags:check && bun run content:check"
```

Then CI or a stricter build command can run:

```bash
bun run validate
bun run build
```

A possible stricter package layout is:

```json
"build": "astro build",
"validate": "bun run tags:check && bun run content:check",
"build:strict": "bun run validate && astro build"
```

Alternatively, `build` itself can become:

```json
"build": "bun run validate && astro build"
```

That is more integrated, but it also means every local build and every deployment build pays the validation cost and inherits validation failures. This is a policy choice rather than a requirement.

## Why not an Astro integration/plugin yet

These checks could technically be wrapped inside an Astro integration or Vite plugin. That would make them feel less like external scripts, but it would also couple content-governance logic to the Astro build lifecycle.

For now, plain Node scripts are preferable because they are:

- simple to debug;
- callable independently;
- safe to run in CI without rendering the site;
- explicit about what is governance validation versus page generation.

If the pipeline grows more complex later, the scripts can be refactored into shared library modules and exposed through both CLI commands and an Astro integration. That should come after the invariants stabilize, not before.

## Runtime comments pipeline

Comments are the only mutable runtime content pipeline. They are intentionally separated from article/PDF generation:

```bash
bun run db:migrate         # apply pending D1 migrations locally
bun run db:migrate:remote  # apply pending D1 migrations to production D1
bun run db:reset           # local destructive reset only, no seed
bun run db:reset:seed      # local destructive reset plus seeds/comments.dev.sql
```

Comment migrations are forward-only and do not contain seed data. The reset script always uses `--local`; do not add a convenient remote reset command. Current comments use article `i18nKey` as the shared `thread_key` so `/zh/...` and `/en/...` translations share one discussion thread.

## Current decision

- Keep `templates/enums.typ` as the single tag registry.
- Derive yearly archive pages and PDFs from article metadata during build.
- Keep validation logic in `scripts/` for now.
- Treat check commands as candidates for a future aggregate `validate` command.
- Keep comments as a small Cloudflare-native D1 feature module; add moderation/admin/replies only as explicit future phases.

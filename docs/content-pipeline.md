# Content Pipeline Notes

This note records the current content-maintenance pipeline and the architectural reasoning behind the helper scripts added during the Phase 2 cleanup.

## Current commands

The project currently exposes these content/data maintenance commands:

```bash
bun run tags:check       # validate the central tag registry and article tag usage
bun run content:check    # validate article metadata and archive consistency
bun run archive:check    # verify archive entries can be derived from article metadata
bun run archive:generate # rewrite archive article lists from article metadata
```

These commands support the source-of-truth rule documented in `docs/architecture.md`:

- article metadata is the canonical source for title/date/tag data;
- yearly archive entries are derived from article metadata;
- tags are managed from one central source, `templates/enums.typ`.

## Why these are scripts

The scripts are repo-local maintenance tools, not runtime features. They run in Node during development or CI and do not become Cloudflare Worker code.

They are intentionally separate from Astro rendering because they check or generate project-specific invariants that cut across several layers:

- Typst article metadata;
- yearly archive Typst files;
- the Typst tag registry;
- Astro's TypeScript tag consumer.

Keeping this logic in `scripts/` makes the checks explicit, easy to run, and independent from the Astro page-rendering lifecycle.

## What should and should not be integrated

Checks are safe to integrate into a higher-level validation command or a CI/build preflight:

```bash
bun run tags:check
bun run content:check
bun run archive:check
```

Generation should stay explicit:

```bash
bun run archive:generate
```

Reason: a build should generally be deterministic and should not silently rewrite source files. If archive entries drift, a build or CI check can fail and tell the author to run `archive:generate`, but `astro build` should not mutate `content/archive/*.typ` by surprise.

## Recommended future integration

If the command surface starts to feel too fragmented, add one aggregate command such as:

```json
"validate": "bun run tags:check && bun run content:check && bun run archive:check"
```

Then CI or a stricter build command can run:

```bash
bun run validate
bun run build
```

A possible stricter package layout is:

```json
"build": "astro build",
"validate": "bun run tags:check && bun run content:check && bun run archive:check",
"build:strict": "bun run validate && astro build"
```

Alternatively, `build` itself can become:

```json
"build": "bun run validate && astro build"
```

That is more integrated, but it also means every local build and every deployment build pays the validation cost and inherits validation failures. This is usually acceptable once the checks are stable, but it is a policy choice rather than a requirement.

## Why not an Astro integration/plugin yet

These checks could technically be wrapped inside an Astro integration or Vite plugin. That would make them feel less like external scripts, but it would also couple content-maintenance logic to the Astro build lifecycle.

For now, plain Node scripts are preferable because they are:

- simpler to debug;
- callable independently;
- safe to run in CI without rendering the site;
- explicit about whether they only check or also write files.

If the pipeline grows more complex later, the scripts can be refactored into shared library modules and exposed through both CLI commands and an Astro integration. That should come after the invariants stabilize, not before.

## Current decision

- Keep `templates/enums.typ` as the single tag registry.
- Keep validation/generation logic in `scripts/` for now.
- Treat check commands as candidates for a future aggregate `validate` command.
- Keep source-generating commands explicit and non-automatic.
- Do not proceed to the comments/D1 Phase 3 until requested.

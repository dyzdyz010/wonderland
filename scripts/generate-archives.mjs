#!/usr/bin/env node

import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

const root = process.cwd();
const articleRoot = resolve(root, "content/article");
const archiveRoot = resolve(root, "content/archive");

const args = new Set(process.argv.slice(2));
const mode = args.has("--write") ? "write" : args.has("--check") ? "check" : "dry-run";
const verbose = args.has("--verbose");

const usage = `Usage:
  node scripts/generate-archives.mjs [--dry-run]
  node scripts/generate-archives.mjs --check
  node scripts/generate-archives.mjs --write

Modes:
  default / --dry-run  Print which archive files would change.
  --check             Exit 1 if generated archive content differs.
  --write             Update content/archive/YYYY.typ files.

Options:
  --verbose           Print changed file paths and compact diffs.
`;

if (args.has("--help") || args.has("-h")) {
  console.log(usage.trim());
  process.exit(0);
}

for (const arg of args) {
  if (!["--dry-run", "--check", "--write", "--verbose", "--help", "-h"].includes(arg)) {
    console.error(`Unknown argument: ${arg}\n\n${usage.trim()}`);
    process.exit(1);
  }
}

function walkFiles(dir, suffix) {
  if (!existsSync(dir)) return [];

  const out = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      out.push(...walkFiles(path, suffix));
    } else if (path.endsWith(suffix)) {
      out.push(path);
    }
  }
  return out.sort();
}

function read(path) {
  return readFileSync(path, "utf8");
}

function rel(path) {
  return relative(root, path);
}

function escapeTypstString(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function parseArticle(path) {
  const raw = read(path);
  const title = /title\s*:\s*"((?:\\"|[^"])*)"/.exec(raw)?.[1]?.replace(/\\"/g, '"');
  const date = /date\s*:\s*"(\d{4}-\d{2}-\d{2})"/.exec(raw)?.[1];

  if (!title || !date) {
    throw new Error(`${rel(path)} is missing title/date metadata; run bun run content:check first.`);
  }

  return {
    title,
    date,
    path: `/${rel(path)}`,
    sortKey: `${date}\u0000${rel(path)}`,
  };
}

function groupArticlesByYear(articles) {
  const byYear = new Map();
  for (const article of articles) {
    const year = article.date.slice(0, 4);
    const group = byYear.get(year) ?? [];
    group.push(article);
    byYear.set(year, group);
  }

  for (const group of byYear.values()) {
    group.sort((a, b) => a.sortKey.localeCompare(b.sortKey));
  }

  return byYear;
}

function formatEntries(articles) {
  return articles
    .map(
      (article) =>
        `    (title: "${escapeTypstString(article.title)}", date: "${article.date}", path: "${article.path}"),`,
    )
    .join("\n");
}

function parseArchiveEntryPaths(existing) {
  const paths = [];
  const entryRegex =
    /\(title:\s*"(?:\\"|[^"])*",\s*date:\s*"\d{4}-\d{2}-\d{2}",\s*path:\s*"([^"]+)"\)/g;

  for (const entry of existing.matchAll(entryRegex)) {
    paths.push(entry[1]);
  }

  return paths;
}

function preserveExistingOrder(existing, articles) {
  const byPath = new Map(articles.map((article) => [article.path, article]));
  const ordered = [];
  const seen = new Set();

  for (const path of parseArchiveEntryPaths(existing)) {
    const article = byPath.get(path);
    if (!article || seen.has(path)) continue;

    ordered.push(article);
    seen.add(path);
  }

  const remaining = articles.filter((article) => !seen.has(article.path));
  return [...ordered, ...remaining];
}

function defaultArchive(year, articles) {
  const latestDate = articles.at(-1)?.date ?? `${year}-01-01`;
  return `#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive ${year}",
  desc: [${year} 年博客文章合集],
  date: "${latestDate}",
  tags: ("Archive",),
  articles: (
${formatEntries(articles)}
  ),
)
`;
}

function replaceArticleEntries(existing, archivePath, articles) {
  const orderedArticles = preserveExistingOrder(existing, articles);
  const replacement = `articles: (\n${formatEntries(orderedArticles)}\n  ),`;
  const pattern = /articles:\s*\(\n[^]*?\n\s*\),/m;

  if (!pattern.test(existing)) {
    throw new Error(`${rel(archivePath)} does not contain a recognizable articles: (...) block.`);
  }

  return existing.replace(pattern, replacement);
}

function buildExpectedArchives() {
  const articles = walkFiles(articleRoot, ".typ").map(parseArticle);
  const byYear = groupArticlesByYear(articles);
  const expected = [];

  for (const [year, yearArticles] of [...byYear.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    const archivePath = resolve(archiveRoot, `${year}.typ`);
    const content = existsSync(archivePath)
      ? replaceArticleEntries(read(archivePath), archivePath, yearArticles)
      : defaultArchive(year, yearArticles);

    expected.push({ year, path: archivePath, content, articleCount: yearArticles.length });
  }

  return expected;
}

function compactDiff(oldText, newText) {
  const oldLines = oldText.split("\n");
  const newLines = newText.split("\n");
  const out = [];
  const max = Math.max(oldLines.length, newLines.length);

  for (let index = 0; index < max; index += 1) {
    if (oldLines[index] === newLines[index]) continue;
    const start = Math.max(0, index - 2);
    const end = Math.min(max, index + 6);
    out.push(`@@ lines ${start + 1}-${end} @@`);
    for (let i = start; i < end; i += 1) {
      if (oldLines[i] === newLines[i]) {
        out.push(` ${oldLines[i] ?? ""}`);
      } else {
        if (oldLines[i] !== undefined) out.push(`-${oldLines[i]}`);
        if (newLines[i] !== undefined) out.push(`+${newLines[i]}`);
      }
    }
    if (end < max) out.push("...");
    break;
  }

  return out.join("\n");
}

const expectedArchives = buildExpectedArchives();
const changed = [];

for (const archive of expectedArchives) {
  const oldContent = existsSync(archive.path) ? read(archive.path) : "";
  if (oldContent !== archive.content) {
    changed.push({ ...archive, oldContent });
  }
}

console.log(
  [
    "Archive generation summary:",
    `- Mode: ${mode}`,
    `- Archive files: ${expectedArchives.length}`,
    `- Changed files: ${changed.length}`,
  ].join("\n"),
);

if (changed.length > 0) {
  console.log("\nChanged archive files:");
  for (const archive of changed) {
    console.log(`- ${rel(archive.path)} (${archive.articleCount} articles)`);
    if (verbose) {
      console.log(compactDiff(archive.oldContent, archive.content));
    }
  }
}

if (mode === "write") {
  mkdirSync(archiveRoot, { recursive: true });
  for (const archive of changed) {
    mkdirSync(dirname(archive.path), { recursive: true });
    writeFileSync(archive.path, archive.content);
  }
  console.log(`\nWrote ${changed.length} archive file(s).`);
} else if (mode === "check" && changed.length > 0) {
  console.error("\nArchive files are out of date. Run `bun run archive:generate` to update them.");
  process.exit(1);
} else if (mode === "dry-run") {
  console.log(
    changed.length === 0
      ? "\nArchive files are already up to date."
      : "\nDry run only. Run `bun run archive:generate` to update these files.",
  );
}

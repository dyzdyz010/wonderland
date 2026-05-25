#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { createHash } from "node:crypto";

const root = process.cwd();
const articleRoot = resolve(root, "content/article");
const pageRoot = resolve(root, "content/page");
const locales = ["zh", "en"];
const defaultTranslationStatus = "source";
const args = new Set(process.argv.slice(2));
const allowMissing = args.has("--allow-missing") && !args.has("--strict");
const errors = [];
const warnings = [];

function walkFiles(dir, suffix) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) out.push(...walkFiles(path, suffix));
    else if (path.endsWith(suffix)) out.push(path);
  }
  return out.sort();
}

function rel(path) {
  return relative(root, path);
}

function sha256(text) {
  return `sha256:${createHash("sha256").update(text).digest("hex")}`;
}

function metadataBlock(raw) {
  const lines = raw.split(/\r?\n/);
  let inShow = false;
  const out = [];
  for (const line of lines) {
    if (line.includes("#show:") && line.includes("main.with")) inShow = true;
    if (inShow) out.push(line);
    if (inShow && line.trim() === ")") break;
  }
  return out.join("\n");
}

function parseStringField(raw, name) {
  return new RegExp(`${name}\\s*:\\s*"([^"]+)"`).exec(raw)?.[1];
}

function parseBooleanField(raw, name) {
  const value = new RegExp(`${name}\\s*:\\s*(true|false)`).exec(raw)?.[1];
  return value === undefined ? undefined : value === "true";
}

function parseTags(raw) {
  const tagBlock = /tags\s*:\s*\(([^]*?)\),/m.exec(raw)?.[1] ?? "";
  return [...tagBlock.matchAll(/blog-tags\.([A-Za-z0-9-]+)/g)].map((match) => match[1]).sort();
}

function parseContentFile(path, rootDir, kind) {
  const raw = readFileSync(path, "utf8");
  const metadata = metadataBlock(raw);
  const relativeToKind = relative(rootDir, path).replaceAll("\\\\", "/");
  const [pathLocale, ...rest] = relativeToKind.split("/");
  const pathKey = rest.join("/").replace(/\.typ$/, "");
  return {
    kind,
    path,
    rel: rel(path),
    raw,
    hash: sha256(raw),
    pathLocale,
    pathKey,
    title: parseStringField(metadata, "title"),
    lang: parseStringField(metadata, "lang"),
    i18nKey: parseStringField(metadata, "i18nKey"),
    sourceLang: parseStringField(metadata, "sourceLang"),
    aiAuthored: parseBooleanField(metadata, "aiAuthored") ?? false,
    translationStatus: parseStringField(metadata, "translationStatus") ?? defaultTranslationStatus,
    translationSourceHash: parseStringField(metadata, "translationSourceHash"),
    date: parseStringField(metadata, "date"),
    tags: parseTags(metadata),
  };
}

function addChecks(items) {
  const byKindAndKey = new Map();
  const sources = new Map();

  for (const item of items) {
    if (!locales.includes(item.pathLocale)) {
      errors.push(`${item.rel}: first path segment must be zh or en`);
    }
    if (item.lang !== item.pathLocale) {
      errors.push(`${item.rel}: lang metadata (${item.lang ?? "missing"}) must match path locale (${item.pathLocale})`);
    }
    if (!item.i18nKey) {
      errors.push(`${item.rel}: missing i18nKey metadata`);
    } else if (item.i18nKey !== item.pathKey) {
      errors.push(`${item.rel}: i18nKey (${item.i18nKey}) must match path key (${item.pathKey})`);
    }
    if (item.translationStatus === "source") {
      sources.set(`${item.kind}:${item.i18nKey}`, item);
    }

    const groupKey = `${item.kind}:${item.i18nKey}`;
    const group = byKindAndKey.get(groupKey) ?? [];
    group.push(item);
    byKindAndKey.set(groupKey, group);
  }

  for (const [groupKey, group] of byKindAndKey.entries()) {
    const seen = new Map();
    for (const item of group) {
      if (seen.has(item.lang)) {
        errors.push(`${item.rel}: duplicate locale ${item.lang} for ${groupKey}; first seen at ${seen.get(item.lang).rel}`);
      }
      seen.set(item.lang, item);
    }
    for (const locale of locales) {
      if (!seen.has(locale)) {
        const message = `${groupKey}: missing ${locale} version`;
        if (allowMissing) warnings.push(message);
        else errors.push(message);
      }
    }

    const [first, ...rest] = group;
    for (const item of rest) {
      if (item.date !== first.date) {
        errors.push(`${item.rel}: date (${item.date}) differs from ${first.rel} (${first.date})`);
      }
      if (item.tags.join(",") !== first.tags.join(",")) {
        errors.push(`${item.rel}: tags differ from ${first.rel}`);
      }
      if (item.aiAuthored !== first.aiAuthored) {
        errors.push(`${item.rel}: aiAuthored (${item.aiAuthored}) differs from ${first.rel} (${first.aiAuthored})`);
      }
    }
  }

  for (const item of items) {
    if (item.translationStatus !== "machine") continue;
    const source = sources.get(`${item.kind}:${item.i18nKey}`);
    if (!source) {
      warnings.push(`${item.rel}: machine translation has no source file`);
      continue;
    }
    if (item.translationSourceHash !== source.hash) {
      errors.push(`${item.rel}: stale machine translation; expected source hash ${source.hash}, got ${item.translationSourceHash ?? "missing"}`);
    }
  }
}

const items = [
  ...walkFiles(articleRoot, ".typ").map((path) => parseContentFile(path, articleRoot, "article")),
  ...walkFiles(pageRoot, ".typ").map((path) => parseContentFile(path, pageRoot, "page")),
];

addChecks(items);

const logicalItems = new Set(items.map((item) => `${item.kind}:${item.i18nKey}`));
console.log([
  "i18n check summary:",
  `- Files: ${items.length}`,
  `- Logical items: ${logicalItems.size}`,
  `- Warnings: ${warnings.length}`,
  `- Errors: ${errors.length}`,
].join("\n"));

if (warnings.length) {
  console.warn("\nWarnings:");
  for (const warning of warnings) console.warn(`- ${warning}`);
}

if (errors.length) {
  console.error("\nErrors:");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(allowMissing
  ? "\ni18n check passed with missing counterparts reported as warnings. Run `bun run i18n:check:strict` after generating all translations."
  : "\ni18n check passed. Every logical content item has zh and en versions.");

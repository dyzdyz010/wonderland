#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const root = process.cwd();
const articleRoot = resolve(root, "content/article");
const tagsFile = resolve(root, "templates/enums.typ");

const errors = [];
const warnings = [];

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

function parseTagRegistry() {
  const raw = read(tagsFile);
  const match = /#let\s+blog-tags\s*=\s*\(([^]*?)\)/m.exec(raw);
  if (!match) {
    errors.push(`Unable to locate blog-tags registry in ${rel(tagsFile)}`);
    return new Map();
  }

  const registry = new Map();
  const entryRegex = /([A-Za-z0-9-]+)\s*:\s*"([^"]+)"/g;
  for (const entry of match[1].matchAll(entryRegex)) {
    const [, id, label] = entry;
    registry.set(id, label);
  }

  if (registry.size === 0) {
    errors.push(`No tags found in ${rel(tagsFile)}`);
  }

  return registry;
}

function parseArticle(path) {
  const raw = read(path);
  const title = /title\s*:\s*"([^"]+)"/.exec(raw)?.[1];
  const date = /date\s*:\s*"(\d{4}-\d{2}-\d{2})"/.exec(raw)?.[1];
  const desc = /desc\s*:\s*\[([^]*?)\]/m.exec(raw)?.[1];
  const tagBlock = /tags\s*:\s*\(([^]*?)\),/m.exec(raw)?.[1] ?? "";
  const tags = [...tagBlock.matchAll(/blog-tags\.([A-Za-z0-9-]+)/g)].map(
    (match) => match[1],
  );

  return {
    path,
    rel: rel(path),
    title,
    date,
    desc,
    tags,
  };
}

function addArticleChecks(articles, tagRegistry) {
  for (const article of articles) {
    if (!article.title) {
      errors.push(`${article.rel}: missing title metadata`);
    }
    if (!article.date) {
      errors.push(`${article.rel}: missing date metadata`);
    }
    if (!article.desc) {
      warnings.push(`${article.rel}: missing desc metadata`);
    }
    if (article.tags.length === 0) {
      warnings.push(`${article.rel}: has no tags`);
    }

    for (const tag of article.tags) {
      if (!tagRegistry.has(tag)) {
        errors.push(`${article.rel}: unknown tag blog-tags.${tag}`);
      }
    }
  }
}

const tagRegistry = parseTagRegistry();
const articles = walkFiles(articleRoot, ".typ").map(parseArticle);

addArticleChecks(articles, tagRegistry);

const years = new Set(
  articles.filter((article) => article.date).map((article) => article.date.slice(0, 4)),
);

console.log(
  [
    "Content check summary:",
    `- Articles: ${articles.length}`,
    `- Article years: ${years.size}`,
    `- Tags in registry: ${tagRegistry.size}`,
    `- Warnings: ${warnings.length}`,
    `- Errors: ${errors.length}`,
  ].join("\n"),
);

if (warnings.length) {
  console.warn("\nWarnings:");
  for (const warning of warnings) console.warn(`- ${warning}`);
}

if (errors.length) {
  console.error("\nErrors:");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("\nContent check passed. Archive and article PDFs are derived from article metadata at build time.");

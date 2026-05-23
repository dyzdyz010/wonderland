#!/usr/bin/env node

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const root = process.cwd();
const articleRoot = resolve(root, "content/article");
const tagsFile = resolve(root, "templates/enums.typ");
const tagUtilsFile = resolve(root, "src/utils/tags.ts");

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
    errors.push(`Unable to locate central blog-tags registry in ${rel(tagsFile)}`);
    return [];
  }

  const entries = [];
  const entryRegex = /^\s*([A-Za-z0-9-]+)\s*:\s*"([^"]+)"\s*,?\s*$/gm;
  for (const entry of match[1].matchAll(entryRegex)) {
    const [, id, label] = entry;
    entries.push({ id, label });
  }

  if (entries.length === 0) {
    errors.push(`No tags found in central registry ${rel(tagsFile)}`);
  }

  return entries;
}

function parseArticleTags(path) {
  const raw = read(path);
  const tagBlock = /tags\s*:\s*\(([^]*?)\),/m.exec(raw)?.[1] ?? "";
  const registryRefs = [...tagBlock.matchAll(/blog-tags\.([A-Za-z0-9-]+)/g)].map(
    (match) => match[1],
  );
  const inlineStringTags = [...tagBlock.matchAll(/"([^"]+)"/g)].map((match) => match[1]);

  return {
    path,
    rel: rel(path),
    registryRefs,
    inlineStringTags,
  };
}

function addRegistryChecks(entries) {
  const ids = new Map();
  const labels = new Map();

  for (const entry of entries) {
    if (!/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/.test(entry.id)) {
      errors.push(
        `${rel(tagsFile)}: tag id "${entry.id}" should use lowercase kebab-case, e.g. dev-ops`,
      );
    }
    if (!entry.label.trim()) {
      errors.push(`${rel(tagsFile)}: tag ${entry.id} has an empty label`);
    }

    if (ids.has(entry.id)) {
      errors.push(`${rel(tagsFile)}: duplicate tag id "${entry.id}"`);
    }
    ids.set(entry.id, entry);

    const existingLabel = labels.get(entry.label);
    if (existingLabel) {
      errors.push(
        `${rel(tagsFile)}: duplicate tag label "${entry.label}" used by ${existingLabel.id} and ${entry.id}`,
      );
    }
    labels.set(entry.label, entry);
  }
}

function addArticleUsageChecks(articleTags, registryById) {
  const usageCounts = new Map([...registryById.keys()].map((id) => [id, 0]));

  for (const article of articleTags) {
    if (article.inlineStringTags.length > 0) {
      errors.push(
        `${article.rel}: inline string tag(s) ${article.inlineStringTags
          .map((tag) => `"${tag}"`)
          .join(", ")} bypass the central registry; use blog-tags.<id> from ${rel(tagsFile)}`,
      );
    }

    if (article.registryRefs.length === 0) {
      warnings.push(`${article.rel}: no blog-tags.<id> references found`);
    }

    const seenInArticle = new Set();
    for (const tagId of article.registryRefs) {
      if (!registryById.has(tagId)) {
        errors.push(`${article.rel}: unknown tag blog-tags.${tagId}; add it to ${rel(tagsFile)} first`);
        continue;
      }

      if (seenInArticle.has(tagId)) {
        warnings.push(`${article.rel}: duplicate tag blog-tags.${tagId}`);
      }
      seenInArticle.add(tagId);
      usageCounts.set(tagId, (usageCounts.get(tagId) ?? 0) + 1);
    }
  }

  for (const [tagId, count] of usageCounts.entries()) {
    if (count === 0) {
      warnings.push(`${rel(tagsFile)}: tag blog-tags.${tagId} is defined but unused`);
    }
  }

  return usageCounts;
}

function addConsumerChecks() {
  if (!existsSync(tagUtilsFile)) {
    warnings.push(`${rel(tagUtilsFile)} not found; Astro tag pages may not be reading the central registry`);
    return;
  }

  const raw = read(tagUtilsFile);
  if (!raw.includes("templates/enums.typ")) {
    errors.push(
      `${rel(tagUtilsFile)} should read tag definitions from the central registry ${rel(tagsFile)}`,
    );
  }
  if (!raw.includes("blog-tags")) {
    warnings.push(`${rel(tagUtilsFile)} does not mention blog-tags; verify tag parsing still uses the central registry`);
  }
}

const registryEntries = parseTagRegistry();
addRegistryChecks(registryEntries);

const registryById = new Map(registryEntries.map((entry) => [entry.id, entry]));
const articleTags = walkFiles(articleRoot, ".typ").map(parseArticleTags);
const usageCounts = addArticleUsageChecks(articleTags, registryById);
addConsumerChecks();

const usedTagCount = [...usageCounts.values()].filter((count) => count > 0).length;

console.log(
  [
    "Tag check summary:",
    `- Central source: ${rel(tagsFile)}`,
    `- Registry tags: ${registryEntries.length}`,
    `- Articles scanned: ${articleTags.length}`,
    `- Used tags: ${usedTagCount}`,
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

console.log("\nTag check passed. Manage tags in templates/enums.typ.");

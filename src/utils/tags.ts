import type { CollectionEntry } from "astro:content";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

export interface TagDefinition {
  id: string;
  label: string;
}

export interface TagWithCount extends TagDefinition {
  count?: number;
}

export interface TagSummary extends TagWithCount {
  count: number;
}

export type TagInput = TagWithCount | string;

const enumsFilePath = resolve(process.cwd(), "templates/enums.typ");

const tagDefinitionsById = parseTagDefinitions(
  readFileSync(enumsFilePath, "utf-8"),
);
const tagIdByLabel = new Map<string, string>();

for (const [id, label] of tagDefinitionsById.entries()) {
  tagIdByLabel.set(label, id);
}

const cachedDefinitions = [...tagDefinitionsById.entries()].map(
  ([id, label]) => ({ id, label }),
);

function parseTagDefinitions(rawFile: string): Map<string, string> {
  const map = new Map<string, string>();
  const match = /#let\s+blog-tags\s*=\s*\(([^]*?)\)/m.exec(rawFile);

  if (!match) {
    console.warn("Unable to locate blog-tags definitions in enums.typ");
    return map;
  }

  const block = match[1];
  const entryRegex = /([A-Za-z0-9-]+)\s*:\s*"([^"]+)"/g;

  for (const entry of block.matchAll(entryRegex)) {
    const [, id, label] = entry;
    map.set(id, label);
  }

  return map;
}

function slugify(label: string): string {
  return label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export function getTagDefinitionById(id: string): TagDefinition | undefined {
  const label = tagDefinitionsById.get(id);
  if (!label) return undefined;
  return { id, label };
}

export function getAllDefinedTags(): TagDefinition[] {
  return cachedDefinitions;
}

export function normalizeTag(tag: TagInput): TagWithCount {
  if (typeof tag !== "string") {
    return tag;
  }

  const existingId = tagIdByLabel.get(tag);
  if (existingId) {
    return {
      id: existingId,
      label: tagDefinitionsById.get(existingId) ?? tag,
    };
  }

  const fallbackId = tagDefinitionsById.has(tag) ? tag : slugify(tag);
  return {
    id: fallbackId,
    label: tagDefinitionsById.get(fallbackId) ?? tag,
  };
}

export function normalizeTags(
  tags: TagInput[] | undefined | null,
): TagWithCount[] {
  if (!tags) return [];
  return tags.map((tag) => normalizeTag(tag));
}

export function buildTagSummaries(
  posts: CollectionEntry<"blog">[],
): TagSummary[] {
  const counts = new Map<string, TagSummary>();

  for (const post of posts) {
    const tags = normalizeTags(post.data.tags ?? []);
    for (const tag of tags) {
      const current = counts.get(tag.id);
      if (current) {
        current.count += 1;
      } else {
        counts.set(tag.id, { ...tag, count: 1 });
      }
    }
  }

  return [...counts.values()].sort((a, b) =>
    a.label.localeCompare(b.label, undefined, { sensitivity: "base" }),
  );
}

export function postHasTag(
  post: CollectionEntry<"blog">,
  tagId: string,
): boolean {
  return normalizeTags(post.data.tags ?? []).some((tag) => tag.id === tagId);
}

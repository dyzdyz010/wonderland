import type { CollectionEntry } from "astro:content";
import { assertLocale, type Locale, normalizeSlug } from "./config";

export type BlogEntry = CollectionEntry<"blog">;
export type PageEntry = CollectionEntry<"page">;

export function localeFromEntry(entry: BlogEntry | PageEntry): Locale {
  return assertLocale(entry.data.lang);
}

export function localizedEntrySlug(entry: BlogEntry | PageEntry): string {
  return normalizeSlug(entry.data.i18nKey);
}

export function localizedPosts(posts: BlogEntry[], locale: Locale): BlogEntry[] {
  return posts.filter((post) => post.data.lang === locale);
}

export function postsForLocale(posts: BlogEntry[], locale: Locale): BlogEntry[] {
  const byKey = new Map<string, BlogEntry[]>();

  for (const post of posts) {
    const key = localizedEntrySlug(post);
    const group = byKey.get(key) ?? [];
    group.push(post);
    byKey.set(key, group);
  }

  return Array.from(byKey.values()).map((group) => {
    return (
      group.find((post) => post.data.lang === locale) ??
      group.find((post) => post.data.translationStatus === "source") ??
      group[0]
    );
  });
}

export function localizedPages(pages: PageEntry[], locale: Locale): PageEntry[] {
  return pages.filter((page) => page.data.lang === locale);
}

export function sortPostsNewestFirst(posts: BlogEntry[]): BlogEntry[] {
  return [...posts].sort((a, b) => {
    const dateCompare = b.data.date.valueOf() - a.data.date.valueOf();
    if (dateCompare !== 0) return dateCompare;
    return localizedEntrySlug(a).localeCompare(localizedEntrySlug(b), undefined, { sensitivity: "base" });
  });
}

export function sortPostsOldestFirst(posts: BlogEntry[]): BlogEntry[] {
  return [...posts].sort((a, b) => {
    const dateCompare = a.data.date.valueOf() - b.data.date.valueOf();
    if (dateCompare !== 0) return dateCompare;
    return localizedEntrySlug(a).localeCompare(localizedEntrySlug(b), undefined, { sensitivity: "base" });
  });
}

export function findLocalizedPost(posts: BlogEntry[], locale: Locale, i18nKey: string): BlogEntry | undefined {
  return posts.find((post) => post.data.lang === locale && post.data.i18nKey === i18nKey);
}

export function findLocalizedPage(pages: PageEntry[], locale: Locale, i18nKey: string): PageEntry | undefined {
  return pages.find((page) => page.data.lang === locale && page.data.i18nKey === i18nKey);
}

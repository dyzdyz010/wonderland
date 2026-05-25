import type { CollectionEntry } from "astro:content";
import { t } from "../i18n/messages";
import type { Locale } from "../i18n/config";
import { localizedEntrySlug, postsForLocale, sortPostsOldestFirst } from "../i18n/content";

export type BlogEntry = CollectionEntry<"blog">;

export interface ArchiveArticle {
  title: string;
  date: string;
  path: string;
}

export interface ArchiveSummary {
  locale: Locale;
  year: string;
  title: string;
  description: string;
  date: Date;
  dateString: string;
  count: number;
  articles: ArchiveArticle[];
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function getArticleTypstPath(post: BlogEntry): string {
  return `/${post.filePath ?? `content/article/${post.id}.typ`}`;
}

export function buildArchiveSummaries(posts: BlogEntry[], locale: Locale): ArchiveSummary[] {
  const messages = t(locale);
  const postsByYear = new Map<string, BlogEntry[]>();

  for (const post of postsForLocale(posts, locale)) {
    const year = String(post.data.date.getFullYear());
    const group = postsByYear.get(year) ?? [];
    group.push(post);
    postsByYear.set(year, group);
  }

  return [...postsByYear.entries()]
    .sort(([a], [b]) => b.localeCompare(a))
    .map(([year, yearPosts]) => {
      const sortedPosts = sortPostsOldestFirst(yearPosts);
      const latestDate = sortedPosts.at(-1)?.data.date ?? new Date(`${year}-01-01T00:00:00.000Z`);
      const latestDateString = formatDate(latestDate);

      return {
        locale,
        year,
        title: locale === "zh" ? `${year} 博客归档` : `Blog Archive ${year}`,
        description: locale === "zh" ? `${year} 年博客文章合集` : `${year} blog article collection`,
        date: latestDate,
        dateString: latestDateString,
        count: sortedPosts.length,
        articles: sortedPosts.map((post) => ({
          title: post.data.title,
          date: formatDate(post.data.date),
          path: getArticleTypstPath(post),
        })),
      } satisfies ArchiveSummary;
    });
}

export function getArchiveByYear(posts: BlogEntry[], locale: Locale, year: string): ArchiveSummary | undefined {
  return buildArchiveSummaries(posts, locale).find((archive) => archive.year === year);
}

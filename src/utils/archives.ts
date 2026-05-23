import type { CollectionEntry } from "astro:content";

export type BlogEntry = CollectionEntry<"blog">;

export interface ArchiveArticle {
  title: string;
  date: string;
  path: string;
}

export interface ArchiveSummary {
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

function compareArticles(a: BlogEntry, b: BlogEntry): number {
  const dateCompare = a.data.date.valueOf() - b.data.date.valueOf();
  if (dateCompare !== 0) return dateCompare;

  return a.id.localeCompare(b.id, undefined, { sensitivity: "base" });
}

export function buildArchiveSummaries(posts: BlogEntry[]): ArchiveSummary[] {
  const postsByYear = new Map<string, BlogEntry[]>();

  for (const post of posts) {
    const year = String(post.data.date.getFullYear());
    const group = postsByYear.get(year) ?? [];
    group.push(post);
    postsByYear.set(year, group);
  }

  return [...postsByYear.entries()]
    .sort(([a], [b]) => b.localeCompare(a))
    .map(([year, yearPosts]) => {
      const sortedPosts = [...yearPosts].sort(compareArticles);
      const latestDate = sortedPosts.at(-1)?.data.date ?? new Date(`${year}-01-01T00:00:00.000Z`);
      const latestDateString = formatDate(latestDate);

      return {
        year,
        title: `Blog Archive ${year}`,
        description: `${year} 年博客文章合集`,
        date: latestDate,
        dateString: latestDateString,
        count: sortedPosts.length,
        articles: sortedPosts.map((post) => ({
          title: post.data.title,
          date: formatDate(post.data.date),
          path: getArticleTypstPath(post),
        })),
      };
    });
}

export function getArchiveByYear(posts: BlogEntry[], year: string): ArchiveSummary | undefined {
  return buildArchiveSummaries(posts).find((archive) => archive.year === year);
}

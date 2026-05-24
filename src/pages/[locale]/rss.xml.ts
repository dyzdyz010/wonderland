import rss, { type RSSFeedItem } from "@astrojs/rss";
import { getCollection } from "astro:content";
import type { CollectionEntry } from "astro:content";
import type { APIContext } from "astro";
import { SITE_AUTHOR, SITE_TITLE } from "../../consts";
import { assertLocale, withLocale } from "../../i18n/config";
import { localizedEntrySlug, localizedPosts, sortPostsNewestFirst } from "../../i18n/content";
import { t } from "../../i18n/messages";

type Kind = "blog";
type Item = CollectionEntry<Kind>;

export const prerender = true;

export function getStaticPaths() {
  return [{ params: { locale: "zh" } }, { params: { locale: "en" } }];
}

export async function GET(context: APIContext) {
  if (!context.site) {
    throw new Error("No site URL found");
  }

  const locale = assertLocale(context.params.locale);
  const m = t(locale);
  const posts = sortPostsNewestFirst(localizedPosts(await getCollection("blog"), locale));

  const items = posts.map(
    (item: Item): RSSFeedItem => ({
      title: item.data.title,
      description: item.data.description,
      pubDate: item.data.date,
      categories: item.data.tags,
      link: withLocale(locale, `/article/${localizedEntrySlug(item)}/`),
    }),
  );

  return rss({
    title: `${SITE_TITLE} (${m.rss.titleSuffix})`,
    description: m.rss.description,
    customData: `<author>${SITE_AUTHOR}</author><language>${locale}</language>`,
    site: context.site,
    items,
  });
}

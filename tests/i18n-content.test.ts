import { describe, expect, test } from "bun:test";
import { postsForLocale } from "../src/i18n/content";

function post(i18nKey: string, lang: "zh" | "en", title: string, date = "2025-01-01") {
  return {
    id: `${lang}/${i18nKey}`,
    data: {
      i18nKey,
      lang,
      title,
      date: new Date(date),
      tags: [],
    },
  } as any;
}

describe("postsForLocale", () => {
  test("returns one post per logical article and prefers the requested locale", () => {
    const posts = [
      post("study/a", "zh", "中文 A"),
      post("study/a", "en", "English A"),
      post("study/b", "zh", "中文 B"),
      post("study/c", "en", "English C"),
    ];

    const zh = postsForLocale(posts, "zh");
    const en = postsForLocale(posts, "en");

    expect(zh.map((entry) => [entry.data.i18nKey, entry.data.lang, entry.data.title])).toEqual([
      ["study/a", "zh", "中文 A"],
      ["study/b", "zh", "中文 B"],
      ["study/c", "en", "English C"],
    ]);
    expect(en.map((entry) => [entry.data.i18nKey, entry.data.lang, entry.data.title])).toEqual([
      ["study/a", "en", "English A"],
      ["study/b", "zh", "中文 B"],
      ["study/c", "en", "English C"],
    ]);
  });
});

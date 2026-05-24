import type { Locale } from "./config";

export const messages = {
  zh: {
    siteDescription: "dyzdyz010 的个人博客。",
    nav: { home: "首页", posts: "文章", archive: "归档", tags: "标签", about: "关于" },
    pages: {
      postsTitle: "文章",
      postsDescription: "所有博客文章。",
      archiveTitle: "归档",
      archiveDescription: "文章归档 — 按年度整理的 PDF 合集",
      archiveIntro: "每年文章汇总，可下载为 PDF 离线阅读。",
      archiveCount: (count: number) => `${count} 篇`,
      tagsTitle: "标签",
      tagsDescription: "浏览所有标签以及每个标签下的文章。",
      tagAll: "全部",
      tagPick: "选择一个标签查看匹配文章。",
      tagCount: (count: number, label: string) => `${count} 篇文章带有 #${label} 标签。`,
      tagEmpty: "这个标签下还没有文章。",
    },
    article: { downloadPdf: "下载 PDF", lastUpdated: "最后更新于", switchLanguage: "阅读 English 版" },
    rss: { titleSuffix: "中文", description: "Wonderland 中文文章。" },
  },
  en: {
    siteDescription: "Personal blog of dyzdyz010.",
    nav: { home: "Home", posts: "Posts", archive: "Archive", tags: "Tags", about: "About" },
    pages: {
      postsTitle: "Posts",
      postsDescription: "All blog posts.",
      archiveTitle: "Archive",
      archiveDescription: "Blog archives — yearly PDF collections",
      archiveIntro: "Yearly article collections are available as PDFs for offline reading.",
      archiveCount: (count: number) => `${count} article${count === 1 ? "" : "s"}`,
      tagsTitle: "Tags",
      tagsDescription: "Browse all tags and the latest posts for each tag.",
      tagAll: "All",
      tagPick: "Pick a tag to see every article that matches.",
      tagCount: (count: number, label: string) => `${count} article${count === 1 ? "" : "s"} tagged with #${label}.`,
      tagEmpty: "No articles have been published with this tag yet.",
    },
    article: { downloadPdf: "Download PDF", lastUpdated: "Last updated on", switchLanguage: "Read 中文 version" },
    rss: { titleSuffix: "English", description: "Wonderland English articles." },
  },
} as const;

export type Messages = (typeof messages)[Locale];

export function t(locale: Locale): Messages {
  return messages[locale];
}

#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2025",
  desc: [2025 年博客文章合集],
  date: "2025-09-15",
  tags: ("Archive",),
  articles: (
    (title: "Typst Syntax", date: "2025-05-27", path: "/content/article/meta/2025/syntaxes.typ"),
    (title: "New Blog Debut", date: "2025-08-23", path: "/content/article/meta/2025/debut.typ"),
    (title: "Hello", date: "2025-08-24", path: "/content/article/meta/2025/hello-world.typ"),
    (title: "使用Cloudflare D1与Astro为博客添加评论功能", date: "2025-08-30", path: "/content/article/tutorials/2025/cloudflare-d1-comments.typ"),
    (title: "在编译NBIS时强制使用小端序", date: "2025-09-14", path: "/content/article/tutorials/2025/nbis-little-endian.typ"),
    (title: "Make NBIS's wsq_decode_mem Thread Safe", date: "2025-09-15", path: "/content/article/tutorials/2025/make-nbis-thread-safe.typ"),
  ),
)

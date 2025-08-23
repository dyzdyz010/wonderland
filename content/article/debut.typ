#import "../../templates/blog.typ": *
#import "../../templates/enums.typ": *

#show: main.with(
  title: "New Blog Debut",
  desc: [My new blog debut, with a new theme and a new look.],
  date: "2025-08-23",
  tags: (
    blog-tags.life,
    blog-tags.typst,
  ),
)

使用新的技术栈创建了新的博客网站。

技术栈：

- Astro
- Typst
- Tailwind CSS
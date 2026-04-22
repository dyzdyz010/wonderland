#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2020",
  desc: [2020 年博客文章合集],
  date: "2020-03-14",
  tags: ("Archive",),
  articles: (
    (title: "2019年总结", date: "2020-01-03", path: "/content/article/life/2019/2019-year-review.typ"),
    (title: "Wonderland - Blog Theme, Redesigned", date: "2020-01-09", path: "/content/article/meta/2020/new-theme-wonderland.typ"),
    (title: "解决在 Windows WSL 中使用 Elixir 的 Observer 时遇到的乱码问题", date: "2020-03-14", path: "/content/article/tutorials/2020/wsl-elixir-observer.typ"),
  ),
)

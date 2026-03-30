#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2017",
  desc: [2017 年博客文章合集],
  date: "2017-12-31",
  tags: ("Archive",),
  articles: (
    (title: "Shadowsocks Module for Surge", date: "2017-04-23", path: "/content/article/life/2017/ss-module-for-surge.typ"),
    (title: "冒个泡证明自己还活着", date: "2017-10-27", path: "/content/article/life/2017/check-in-20171027.typ"),
    (title: "2017年总结", date: "2017-12-31", path: "/content/article/life/2017/2017-year-review.typ"),
  ),
)

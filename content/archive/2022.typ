#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2022",
  desc: [2022 年博客文章合集],
  date: "2022-10-21",
  tags: ("Archive",),
  articles: (
    (title: "2021年总结", date: "2022-01-11", path: "/content/article/life/2021/2021-year-review.typ"),
    (title: "Oblivion - A Vitepress Theme", date: "2022-05-18", path: "/content/article/meta/2022/vitepress-theme-oblivion.typ"),
    (title: "MMO Server From Scratch(0) - Introduction", date: "2022-06-08", path: "/content/article/mmo-server-from-scratch/2022/20220608-mmo-server-from-scratch(0)-introduction.typ"),
    (title: "MMO Server From Scratch(1) - Beacon Server", date: "2022-06-10", path: "/content/article/mmo-server-from-scratch/2022/20220610-mmo-server-from-scratch(1)-beacon-server.typ"),
    (title: "向UE5项目中集成Protobuf", date: "2022-10-12", path: "/content/article/tutorials/2022/ue5-protobuf.typ"),
    (title: "MMO Server From Scratch(2) - Gate Server", date: "2022-10-16", path: "/content/article/mmo-server-from-scratch/2022/20221016-mmo-server-from-scratch(2)-gate-server.typ"),
    (title: "MMO Server From Scratch(3) - Scene Server(0) - 概要", date: "2022-10-19", path: "/content/article/mmo-server-from-scratch/2022/20221016-mmo-server-from-scratch(3)-scene-server-intro.typ"),
    (title: "MMO Server From Scratch(4) - Scene Server(1) - AOI", date: "2022-10-21", path: "/content/article/mmo-server-from-scratch/2022/20221021-mmo-server-from-scratch(4)-scene-server-aoi-algorithm.typ"),
  ),
)

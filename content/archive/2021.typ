#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2021",
  desc: [2021 年博客文章合集],
  date: "2021-08-02",
  tags: ("Archive",),
  articles: (
    (title: "Install RHEL 8 With SAS 2008 Raid Controllers", date: "2021-01-03", path: "/content/article/tutorials/2021/rhel-8-with-sas2008-raid-controllers.typ"),
    (title: "博客换新颜", date: "2021-05-07", path: "/content/article/meta/2021/20210507-blog-new-style.typ"),
    (title: "20210520", date: "2021-05-20", path: "/content/article/life/2021/20210520.typ"),
    (title: "让Windows的Git使用代理", date: "2021-08-02", path: "/content/article/tutorials/2021/windows-git-proxy.typ"),
    (title: "WSL2被防火墙阻挡无法连接网络", date: "2021-08-02", path: "/content/article/tutorials/2021/wsl2-firewall-fix.typ"),
  ),
)

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "博客更新",
  desc: [博客样式更新],
  date: "2026-01-08",
  tags: (
    blog-tags.programming,
    blog-tags.software,
    blog-tags.blog,
  ),
)

= 样式更新

受#link("https://www.yysuni.com/")[YYsuni博客]的启发，我决定更新（抄袭）一下博客样式。把原本的黑红色调改为了现在的毛玻璃彩色背景风格，以红色为主色调，清新亮丽。

= 排版更新

受#link("https://github.com/Yousa-Mirage/Tufted-Blog-Template")[Tufted-Blog-Template]的启发，我为博客增加了Tufed风格的旁注和脚注，可以响应式动态变化，当屏幕较宽时展示旁注，当屏幕较窄时展示脚注#footnote[这是脚注，宽屏显示在内容旁边，窄屏显示在底部。]。

*折腾永无止境。*
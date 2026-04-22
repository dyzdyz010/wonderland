#import "/templates/archive.typ": *

#show: main.with(
  title: "Blog Archive 2023",
  desc: [2023 年博客文章合集],
  date: "2023-10-24",
  tags: ("Archive",),
  articles: (
    (title: "Mac下luatex找不到系统字体解决", date: "2023-03-17", path: "/content/article/tutorials/2023/mac-luatex-system-font-fix.typ"),
    (title: "使用FFmpeg合并视频及字幕", date: "2023-10-24", path: "/content/article/tutorials/2023/ffmpeg-merge-video-and-subtitles.typ"),
  ),
)

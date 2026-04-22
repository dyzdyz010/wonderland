#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "使用FFmpeg合并视频及字幕",
  desc: [有的播放器无法识别外置字幕或者内置轨道，需要将字幕内容“烧录”到视频上。 命令： 内置字幕 外置字幕],
  date: "2023-10-24",
  tags: (
    blog-tags.ffmpeg,
    blog-tags.tooling,
  ),
)

有的播放器无法识别外置字幕或者内置轨道，需要将字幕内容“烧录”到视频上。

命令：

= 内置字幕

```bash
ffmpeg -i input.mp4 -vf "subtitles=input.mp4" output.mp4
```

= 外置字幕

```bash
ffmpeg -i input.mp4 -vf "subtitles=input.srt" output.mp4
```

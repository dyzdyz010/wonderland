#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "国内Origin下载加速",
  desc: [国内Origin下载加速],
  date: "2018-11-18",
  tags: (
    blog-tags.game,
    blog-tags.tooling,
  ),
)

打开 Origin 安装目录下（默认`C:\Program Files(x86)\Origin`）的 `EACore.ini` 文件，复制粘贴如下内容：

```ini
[connection]
EnvironmentName=production

[Feature]
CdnOverride=akamai
```

保存并关闭，重启Origin，本人测试下载可以达到满速。

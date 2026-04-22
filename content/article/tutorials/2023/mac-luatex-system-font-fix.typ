#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Mac下luatex找不到系统字体解决",
  desc: [参考链接：https://zhuanlan.zhihu.com/p/42434849 执行以下命令： 其中，Assets 和 com\_apple\_MobileAsset\_Font4 随系统版本变化。比],
  date: "2023-03-17",
  tags: (
    blog-tags.tooling,
  ),
)

参考链接：#link("https://zhuanlan.zhihu.com/p/42434849")[zhuanlan.zhihu.com/p/42434849]

执行以下命令：

```bash
sudo tlmgr conf texmf OSFONTDIR /System/Library/Assets/com_apple_MobileAsset_Font4/
```

其中，`Assets` 和 `com_apple_MobileAsset_Font4` 随系统版本变化。比如当前 `Ventura` 版本的相应文件夹是 `AssetsV2` 和 `com_apple_MobileAsset_Font7`。

执行上面的命令后，luatex就可以识别系统字体了。如果要取消的话，执行下面命令：

```bash
sudo tlmgr conf texmf --delete OSFONTDIR
```

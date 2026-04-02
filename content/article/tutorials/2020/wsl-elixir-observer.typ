#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "解决在 Windows WSL 中使用 Elixir 的 Observer 时遇到的乱码问题",
  desc: [解决在 Windows WSL 中使用 Elixir 的 Observer 时遇到的乱码问题],
  date: "2020-03-14",
  tags: (
    blog-tags.wsl,
    blog-tags.elixir,
    blog-tags.linux,
  ),
)

- OS: Windows 10
- WSL: Ubuntu 18.04 LTS
- X Server: VcXSrv

在 WSL 下运行 Elixir 的 Observer 时遇到了文字全部变成方框的问题。经查询#link("https://www.cnblogs.com/freestylesoccor/articles/9630758.html")[资料]，证实是中文字体的问题，最终的解决方案如下：

在系统中安装以下三个字体包：

```bash
$ sudo apt install ttf-wqy-microhei
$ sudo apt install fonts-wqy-microhei
$ sudo apt install ttf-wqy-zenhei
```

安装之后再次运行 Observer，文字可以正常显示。

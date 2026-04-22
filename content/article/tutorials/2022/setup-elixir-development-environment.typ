#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "搭建Elixir开发环境",
  desc: [本文对 Linux、WSL、macOS 基本通用。 1. 安装 Elixir 由于 Elixir 是存在],
  date: "2022-12-27",
  tags: (
    blog-tags.elixir,
    blog-tags.tooling,
  ),
)

*本文对 Linux、WSL、macOS 基本通用。*

= 1. 安装 Elixir

由于 Elixir 是存在于 Erlang 运行环境之上的，因此安装 Elixir 也需要安装 Erlang。

在这里我们可以选择用什么包管理器来安装。一般来说 `Homebrew` 就可以了，它可以在安装 Elixir 的时候自动安装它的依赖项，包括Erlang：

```bash
brew install elixir
```

这样会安装 Elixir 的最新版本。

还有一种方法是通过 #link("https://asdf-vm.com/")[Home | asdf (asdf-vm.com)]。`asdf` 是一个环境版本控制器，可以安装指定版本的软件以获得固定的开发环境，不像 `Homebrew`，只要一更新就会连带软件版本自动更新，有可能会破坏开发环境。

通过 `asdf` 的话，首先要添加对应的软件库，先添加 `Erlang`：

```bash
asdf plugin add erlang
```

然后再安装一个指定的版本：

```bash
asdf install erlang 25.1.1
```

这样 `asdf` 会拉取指定的版本进行编译和安装。

`Erlang` 安装完成后继续安装 `Elixir`：

```bash
asdf plugin add elixir
asdf install elixir 1.14.1
```

这样 `Elixir` 就安装好了。我们可以用 `iex` 命令来检测安装是否正常。

= 2. 配置代码编辑器

编辑器我喜欢用 VSCode，因为它拥有非常丰富的各类插件，可以把编辑器打造得又好看又好用。

在 VSCode 里，我们只需要一个插件：`ElixirLS`，这是一个 `Elisir` LSP(Language Server Protocol) 的实现。

ElixirLS 提供了诸如语法高亮、代码提示、自动完成、代码导航等功能。这些功能可以帮助我们更快地编写代码，避免出错。

此外，ElixirLS 还提供了代码检查功能，可以帮助我们发现代码中的错误和潜在问题。它会在编辑器中显示错误信息，并提供修复建议。

ElixirLS 还支持 Elixir 中的部分进行运行、调试、测试等操作。例如，我们可以使用 ElixirLS 运行 Elixir 脚本，或者使用它调试 Elixir 应用程序。

编辑器的配置就算完成了。写一个 Hello world 吧。进入 `iex` 交互环境：

```bash
iex> IO.puts "Hello, World!" 
Hello, World! 
:ok
```

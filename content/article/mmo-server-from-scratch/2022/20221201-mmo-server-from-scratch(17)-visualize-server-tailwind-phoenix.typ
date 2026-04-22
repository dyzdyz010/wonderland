#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(17) - Visualize Server(0) - Tailwind 与 Phoenix 集成",
  desc: [上节说了我想要能够让服务端的玩家移动数据变得直观，那么 Web 就是我第一个想到的方式。所以从本节开始我],
  date: "2022-12-01",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.tooling,
    blog-tags.software,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

#link("/article/mmo-server-from-scratch/2022/20221130-mmo-server-from-scratch(16)-scene-server-movement-error-notes")[上节]说了我想要能够让服务端的玩家移动数据变得直观，那么 `Web` 就是我第一个想到的方式。所以从本节开始我将建立一个以 `Phoenix` 框架为基础的 `Web` 服务器，将数据通过图形的方式展示在网页上。

建立项目很简单：

```bash
mix phx.new visualize_server --no-ecto
```

这个服务器不需要数据库连接，所以给了参数 `--no-ecto`。接下来着重讲如何将 `CSS` 框架 `Tailwind` 整合进项目里。

#line(length: 100%)

#link("https://tailwindcss.com/")[Tailwind CSS] 是一个非常好用的 `CSS` 框架，使用 `class` 组合的方式实现各种样式，非常方便和灵活。在这个对场景进行可视化的项目里，我将使用它作为整个项目的 `CSS` 框架。

= 1. 清理旧样式

为了防止不同 `CSS` 内容间的相互污染，最好在加入新样式之前把旧的先去掉。`Phoenix` 框架使用 `ESBuild` 作为 `JS` 打包工具，它的默认样式 `app.css` 被引入到了 `app.js` 中：

```js
// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import "../css/app.css"
```

而我们因为要用 `Tailwind` 对 `CSS` 进行单独打包，因此我们需要把这行注释掉。

接下来我们看一下 `app.css` 的内容：

```css
/* This file is for your main application CSS */
@import "./phoenix.css";

/* Alerts and form errors used by phx.new */
.alert {
  padding: 15px;
  margin-bottom: 20px;
  border: 1px solid transparent;
  border-radius: 4px;
}
.alert-info {
  color: #31708f;
  background-color: #d9edf7;
  border-color: #bce8f1;
}
.alert-warning {
  color: #8a6d3b;
  background-color: #fcf8e3;
  border-color: #faebcc;
}
...
```

这里引用了一个 `phoenix.css` 的文件，里面是一些项目自带的初始化样式。我们要从头开始，因此可以把它删掉。后面的 `.alert` 之类的样式是框架自带的消息提示机制的样式，比如对数据的增删改查时，页面会有一个 `banner` 用来显示操作结果。我们既然要干干净净的开始，那就干脆什么都不留，把 `app.css` 变成空文件。

= 2. 添加依赖

把 `Tailwind` 库添加到项目里有两种方式：

1. 通过 `NPM` 直接在 `JS`中添加
2. 通过 `Elixir` 依赖包添加

用 *1* 的方式的话，后续的监视、打包等功能还需要自己操心，对我这种菜鸡不友好。

而用 *2* 的方式的话，由于 `Tailwind` 的 `Hex包` 除了引入库文件还能引入一些命令，比如构建控制、开发环境下监视文件变化等，这无疑会更方便一点，所以我选择方法 *2*。

在项目的 `mix.exs` 文件中添加依赖：

```elixir
defp deps do
    [
      ...,
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
    ]

  end
```

除此之外，我们还需要在最终打包时，把我们写好的 `CSS` 文件通过 `Tailwind` 一并打包进去，因此在 `aliases` 函数中增加如下内容：

```elixir
defp aliases do
  [
    setup: ["deps.get"],
    "assets.deploy": [
      # 增加这行
      "tailwind default --minify",
      "esbuild default --minify", 
      "phx.digest"
    ]
  ]
end
```

执行以下命令刷新依赖包：

```bash
mix deps.get
```

= 3. 添加配置

在 `config/config.exs` 中对 `Tailwind` 进行配置：

```elixir
# Tailwind config
config :tailwind, version: "3.1.6", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
  cd: Path.expand("../assets", __DIR__)
]
```

在这里，我们制定了 `Tailwind` 的版本，制定了配置文件、输入文件、以及输出文件的路径。`3.1.6` 可以换成最新的 `Tailwind` 版本。

这里指定了配置文件 `tailwind.config.js`，那就让我们创建它：

```javascript
// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

module.exports = {
  mode: 'jit',
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
```

这里我们指定了可能会用到 `Tailwind class` 名称的地方，即 `JS` 文件、部分 `Elixir` 文件和 `.*ex` 模板文件。如果你有其他地方会用到 `Tailwind`，那就把它的路径也加进来。

我们还想让 `Tailwind` 能够监视我们对文件的变化，从而对改动的部分重新编译，以便实时看到效果。在 `config/dev.exs` 配置文件中加入以下内容：

```elixir
config :visualize_server, VisualizeServerWeb.Endpoint,
  ...,
  watchers: [
    # 加入下面这行
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]},
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]
```

到这里我们就全部配置完成了。可以随便在模板中加个 `class` 然后运行起来看下网页，可以看到是没什么效果的。那是因为我们还没有在 `CSS` 文件中引入 `Tailwind`。

= 4. 在 CSS 中引入 Tailwind

在 `app.css` 中加入以下内容：

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

这时再去看网页，可以看到之前加的 `class` 样式已经能够生效了：

#figure(image("/public/assets/img/2022/20221201-mmo-server-from-scratch(17)-visualize-server-tailwind-phoenix-1.png"), caption: "Pasted image 20221201165547.png")

到这里 `Tailwind` 的配置工作就全部完成了，后续的使用大家就可以自由发挥了 :-P

= 下一步

下一步我们将选择一个趁手的前端 `2D` 渲染库，并探讨数据的获取和推送方式。


#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(12) - Scene Server(10) - 角色进程重整(1)",
  desc: [本节主要讲一下如何重新规整角色相关功能。 角色属性 我们的角色具备多种属性，这些属性需要在服务器中被实时调],
  date: "2022-11-26",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.rust,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

本节主要讲一下如何重新规整角色相关功能。

= 角色属性

我们的角色具备多种属性，这些属性需要在服务器中被实时调用，如位置、攻击力防御力等。这些属性的数学计算需要尽可能效率高，因此我打算把他们置于 `Rust NIF` 内，以获得 `Rust` 的计算性能，相比较而言 `Elixir` 对此类计算的效率相对较低。

在#link("/article/mmo-server-from-scratch/2022/20221016-mmo-server-from-scratch(5)-scene-server-aoi-supervision-tree#heading-0")[从零开始的MMORPG游戏服务器(4) - Scene Server(2) - AOI - 监督树 - 掘金 (juejin.cn)]中我们提到过，`NIF` 中的数据可以在 `Elixir` 中以引用的形式存在，因此在 `Elixir` 代码中，我们只需要让玩家角色进程保存一个各类状态数据的引用即可，反正几乎所有的计算都存在于 `NIF` 空间，`Elixir` 中就算不持有真正的数据也没有什么问题。

= 定时任务

除了保存数据，玩家角色进程还需要定时更新自身的一些数据，如在匀速直线运动中更新自己的位置、buff结算等等。这类任务我也想把它放到 `NIF` 中以提高计算速度。

由于 `NIF` 中无法很好地进行并发编程，因此 *定时* 的这个任务依然需要交给 `Elixir` 代码。`Elixir` 允许间隔一定时间向进程发送消息，从而实现定时任务。基本的调用流程如下：

```mermaid
sequenceDiagram

participant P as PlayerCharacter
participant N as NIF Space

P ->> P: Process.send_after(self, 100ms, tick_function)

rect rgb(200, 150, 255)
note right of P: Tick function
P ->> P: tick_function()
activate P
P ->> N: TickFunction in NIF
activate N
N -->> P: Reply
deactivate N
deactivate P
end
```

从 `NIF` 的定时函数返回数据是必要的，例如在位置更新中，`Elixir` 代码需要拿到更新后的位置进行 `AOI` 广播。

= 下一步

下一步将具体说明 `NIF` 中的代码结构，以及如何改造已经写好的移动同步代码逻辑。

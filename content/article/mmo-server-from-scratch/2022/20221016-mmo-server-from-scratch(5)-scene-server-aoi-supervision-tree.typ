#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "MMO Server From Scratch(5) - Scene Server(2) - AOI - 监督树",
  desc: [今天来确定 NIF 的 Elixir 接口部分以及相应监督树的结构。],
  date: "2022-10-22",
  tags: (
    blog-tags.game,
    blog-tags.mmo,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.programming,
  ),
)

今天来确定 `NIF` 的 `Elixir` 接口部分以及相应监督树的结构。

= NIF - Elixir 部分

在上一篇文章中我简要实现了坐标管理系统 `coordinate_system` 的 `Rust` 部分，除此之外还需要它的另一半，`Elixir` 接口。

这个过程十分简单。`mix rustler.new` 命令生成 `Rust` 代码时，会在 `README.md` 文件中写好模板：

```elixir
defmodule SceneServer.Native.SortedSet do
  use Rustler, otp_app: :scene_server, crate: "coordinate_system"

  # When your NIF is loaded, it will override this function.
  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)
end
```

可以看到，我只需要新建一个 `.ex` 文件，并将与 `Rust` 中对应的模块名及函数原型写好即可。此处有两个地方需要与 `Rust` 代码对应：

+ `crate:` 参数，需要与 `Cargo.toml` 文件中的 `package name` 一致
+ `defmodule 模块名`，需要与 `lib.rs` 中 `rustler::init!` 函数调用中的参数一致

创建好之后，需要逐个添加 `Rust` 代码中的接口，例：

```elixir
@spec new_system(integer(), integer()) :: {atom(), Types.coordinate_system()}
def new_system(_set_capacity, _bucket_capacity), do: error()

@spec add_item_to_system(Types.coordinate_system(), integer(), {number(), number(), number()}) :: {:ok, Types.item()} | {:err, atom()}
def add_item_to_system(_system, _cid, _coord), do: error()

@spec remove_item_from_system(Types.coordinate_system(), Types.item()) :: {:ok, {integer(), integer(), integer()}} | {:err, atom()}
def remove_item_from_system(_system, _item), do: error()

@spec update_item_from_system(Types.coordinate_system(), Types.item(), tuple()) :: {{integer(), integer(), integer()}, atom()}
def update_item_from_system(_system, _item, _new_position), do: error()

defp error, do: :erlang.nif_error(:nif_not_loaded)
```

可以看到，有的接口我写的类型规格 `@spec` 的返回值不太合理，但是目前问题不大。

有眼尖的小伙伴可能还注意到了 `Types.item()` 和 `Types.Coordinate_system()` 这两种类型，这些都是自定义类型：

```elixir
defmodule SceneServer.Native.CoordinateSystem.Types do
  @type item :: reference()
  @type coordinate_system :: reference()
end
```

可以看到这里使用了 `reference()` 类型，这个就很有意思了。参考上一篇文章中提到的 #link("https://github.com/discord/sorted_set_nif")[Discord 代码]，我的做法照搬了这份代码，原因是 `Elixir` 侧希望只保有相应资源的 *引用*，而不是内容本身，使得内容只存在于 `NIF` 空间内，避免内容来回复制传递造成的资源浪费和效率降低。

到这里，坐标系统的 `NIF` 部分已经基本完成，可以作为一个完整模块被其他模块调用了。

= AOI 进程结构设计

刚开始的想法时，`AOI` 作为一个单一进程存在，接受所有 `PlayerCharacter` 进程的请求，并返回相关数据。但是这样一来，`PlayerCharacter` 进程数量众多，全部向一个单一进程发送消息，势必会造成 *消息拥堵*，导致有的玩家需要等待好久才能获取返回数据，极大影响玩家游戏体验。

因此我又想出了另一种方法，每一个玩家对应创建一个 `AoiItem` 进程，只保有与当前玩家有关的 `AOI` 信息，同时 `Aoi` 模块维护一个 `用户ID` 到 `AOI进程ID` 的映射，便于向其他玩家发送 `AOI` 消息。

这样一来，用户的逻辑与 `AOI` 相关逻辑就在一定程度上解耦了，`AoiItem` 只专注于更新自己的 `感兴趣列表` 和 `收发广播消息`，玩家进程只需要通知自己的 `AoiItem` 进程进行各种操作，发送一条消息的事，完全不影响自己进程中的逻辑被 `AOI` 相关操作阻塞。

如此一来，整个 `scene_server` 的监督树目前变成了这样：

```
SceneServer
├── InterfaceSup
│   └── Interface
├── PlayerSup
│   ├── PlayerManager
│   └── PlayerCharacterSup
│       └── PlayerCharacter (1:N)
└── AoiSup
    ├── AoiManager
    └── AoiItemSup
        └── AoiItem (1:N)

PlayerCharacter -.-> AoiItem
```

其中：

+ AoiManager - 负责维护 `用户ID` 到 `AOI进程ID` 映射的模块
+ AoiItem - 与 `PlayerCharacter` 对应的单个玩家 `AOI` 进程，被 `PlayerCharacter` 所持有。

== 目前考虑到的问题

`AoiItem` 进程所应该具备的属性，除了 `用户ID` 和 `玩家进程ID`，是否需要同时持有 `网关连接进程ID`，如果 `AoiItem` 需要向客户端发送周围玩家更新信息的时候，是经过 `玩家进程`，还是直接发往 `网关连接进程`？这里我还没有想清楚，如果直接发往网关的话，持有 `网关连接进程ID` 是否会造成数据一致性问题？目前不得而知。

= 接下来的工作

下一步对 `AOI` 进程树的初始化流程进行分析和实现，同时准备加入客户端及 `Proto` 协议对其进行测试。

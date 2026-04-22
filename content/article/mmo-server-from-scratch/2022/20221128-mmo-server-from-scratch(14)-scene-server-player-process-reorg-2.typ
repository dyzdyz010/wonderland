#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(14) - Scene Server(11) - 角色进程重整(2)",
  desc: [上节我说明了自己选择Rustler作为架构一部分的原因，本节详细介绍如何将角色的移动计算搬到 Rust N],
  date: "2022-11-28",
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

上节我说明了自己选择Rustler作为架构一部分的原因，本节详细介绍如何将角色的移动计算搬到 `Rust NIF` 中。

在#link("/article/mmo-server-from-scratch/2022/20221126-mmo-server-from-scratch(12)-scene-server-player-process-reorg-1")[从零开始的MMORPG游戏服务器(12) - Scene Server(10) - 角色进程重整(1) - 掘金 (juejin.cn)]中我已经向大家展示了定时任务的执行方式，而移动计算恰恰就是一种需要定时执行的任务。

= 执行流程

1. `PlayerCharacter` 进程创建时同时也创建定时任务 `movement_tick` 、 `NIF` 空间的自身数据
2. `movement_tick` 触发执行，将自身数据引用传入 `NIF` 函数进行运动计算
3. `NIF` 函数将数据引用解包，进行运动参数更新，并返回新的位置
4. `PlayerCharacter` 收到返回的新位置，并通知 `AoiItem` 进程对新位置进行记录和广播
5. `AoiItem` 收到消息，首先将新位置更新到 `CoordinateSystem` 中，然后向当前 `AOI` 范围内其他玩家进行广播

= 数据结构

玩家角色数据在 `Rust` 中以结构体的形式存在：

```rust
pub struct CharacterData {
    pub cid: u64,
    pub nickname: String,
    pub movement: Movement,
    pub dev_attrs: DevAttrs,
}
```

- cid - 玩家角色ID
- nickname - 昵称，目前没用
- movement - 移动组件，包含内容见下
- dev\_attrs - 成长属性，目前没用

移动组件同样为一个结构体，包含位置、速度、加速度等属性，用于计算玩家角色在某时刻下的位置以及状态：

```rust
pub struct Movement {
    pub location: Vector,
    pub velocity: Vector,
    pub acceleration: Vector,
    pub timestamp: u64,
    pub is_in_air: bool,
}
```

- location - 位置
- velocity - 速度
- acceleration - 加速度，目前还没有用到，不确定未来要不要用
- timestamp - 运动参数生效时的时间，一般在运动状态发生变化时更新
- is\_in\_air - 用于判断玩家角色是不是在空中，用于判断是否要施加重力影响。目前没用

当 `PlayerCharacter` 执行 `movement_tick` 时，其实就是在更新 `movement` 组件的值。

`PlayerCharacter` 传入 `NIF` 函数的数据引用是一个 `ResourceArc` 类型的对象：

```rust
pub struct CharacterDataResource(Mutex<CharacterData>);
pub type CharacterDataArc = ResourceArc<CharacterDataResource>;
```

`ResourceArc` 能够将一个资源包装成引用形式，这样可以使其能够在 `Elixir` 和 `Rust` 之间传递同一份持续存在的数据，使得 `Elixir` 进程保存 `NIF` 空间数据成为可能。

同时我们可以看到我们传递的资源类型不是直接的 `CharacterData`，而是在其上加了锁（Mutex），一方面是因为 `ResourceArc` 类型所引用的资源默认是 *不可变（Immutable）* 的，想要使其可变要求资源类型必须被 `Mutex` 包裹；另一方面也是出于跨线程读写安全的考虑。目前玩家角色数据涉及到的逻辑比较少可能看不出来，但是后期 *线程安全* 有可能会成为一个不得不考虑的问题。

= AoiItem 执行逻辑

在之前，`AoiItem` 进程既负责移动计算，又负责 `AOI` 相关，现在经过改造之后，移动计算的相关逻辑移到了 `PlayerCharacter` 进程内，`AoiItem` 进程只需要负责 `AOI` 相关逻辑即可。我们只需要给 `AoiItem` 增加一个接口供 `PlayerCharacter` 执行完移动计算逻辑后调用即可：

```elixir
@impl true
def handle_cast({:self_move, location}, %{cid: cid, subscribees: subscribees} = state) do
  broadcast_action_player_move(cid, location, subscribees)

  {:noreply, %{state | location: location}}
end
```

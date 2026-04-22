#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(28) - Scene Server(17) - 更新相关NIF接口",
  desc: [上节我们将物理系统创建完成，本节就开始利用物理系统对移动相关的 NIF 函数进行修改。 基本思路就是在涉],
  date: "2022-12-20",
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

上节我们将物理系统创建完成，本节就开始利用物理系统对移动相关的 `NIF` 函数进行修改。

基本思路就是在涉及到物理操作的函数上增加 `PhySys` 对象引用，以获取全局唯一对象。除此之外，还有个地方值得着重说一下。

= 获取调试数据

之前没有引入物理引擎的时候，角色数据结构体内的所有字段均为简单类型，因此可以直接使用 `Rustler` 提供的传递类型，使得 `Rust` 类型的数据能够传递到 `Elixir` 代码中，反之亦然。*但是* 引入物理引擎相关类型后，那些物理相关的字段无法被 `Rustler` 传递，阻碍了我们对 `NIF` 代码进行调试。因此，我的方法是再创建一个孪生的结构体，去掉物理相关字段，全部使用简单字段。以移动组件 `Movement` 为例：

```rust
pub struct Movement {
    physics_component: PhysicsComp,
    // pub location: Vector,
    pub velocity: Vector,
    pub acceleration: Vector,
    pub timestamp: u64,
    pub is_in_air: bool,
}
```

可以看到，我们把 `location` 字段替换为了 `physics_component`，因为位置由它决定。这个结构体无法被传递到 `Elixir` 代码中，所以我们就创建另一个结构体：

```rust
pub struct MovementDebug {
    pub location: Vector,
    pub velocity: Vector,
    pub acceleration: Vector,
    pub timestamp: u64,
    pub is_in_air: bool,
}
```

其他的地方都一样，只不过又将 `physics_component` 替换回了 `location`。这个结构体用上面的原本数据进行初始化：

```rust
pub fn new(movement: &Movement, physys: &PhySys) -> MovementDebug {
    MovementDebug {
        location: movement.get_location(&physys),
        velocity: movement.velocity,
        acceleration: movement.acceleration,
        timestamp: movement.timestamp,
        is_in_air: movement.is_in_air,
    }
}
```

`location` 的获取也很简单，从原本数据的 `get_location` 方法获取即可，只需要传递一个 `PhySys` 对象。

这样一来，当需要查看调试数据时，只要返回 `MovementDebug` 类型的对象即可。角色数据类型 `CharacterData` 同理。

= 下一步

物理引擎的替换目前就暂时告一段落，下一阶段我要重新思考一下移动同步的客户端执行过程。目前依靠 `NavMesh` 的方法在跨越地形时是有问题的，我需要找一个其他的办法，同时把跳跃动作也进行同步。

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(27) - Scene Server(16) - 创建物理系统及其管理器",
  desc: [上节提到了物理系统对象 PhySys ，这节我们来实现 PhySys 以及 Elixir 端的管理进程。],
  date: "2022-12-19",
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

上节提到了物理系统对象 `PhySys` ，这节我们来实现 `PhySys` 以及 `Elixir` 端的管理进程。

= PhySys

这是一个自定义结构体，用来存放物理引擎的全局信息，比如刚体/碰撞体集合、管线、碰撞阶段（Broad Phase, Narrow Phase）等。

选择要存储的东西并不难，只要看管线执行步进方法时需要哪些参数即可。对于我们的项目来说，目前只考虑使用 `碰撞管线 Collision Pipeline` ，所以就看它需要哪些参数：

```rust
/// Executes one step of the collision detection.
pub fn step(
    &mut self,
    prediction_distance: Real,
    broad_phase: &mut BroadPhase,
    narrow_phase: &mut NarrowPhase,
    bodies: &mut RigidBodySet,
    colliders: &mut ColliderSet,
    hooks: &dyn PhysicsHooks,
    events: &dyn EventHandler,
)
```

这参数中的东西，除了最后的两个事件处理函数，其他的都是需要存储的全局信息。其中 `prediction_distance` 在一个叫做 `IntegrationParameters` 的 `Rapier` 结构中提供。

除此之外我们还需要做场景查询，以进行射线测试等操作。

因此，我们的 `PhySys` 结构如下：

```rust
pub struct PhySys {
    pub integration_params: IntegrationParameters,
    pub pipeline: CollisionPipeline,
    pub queries: QueryPipeline,
    pub rigid_body_set: RigidBodySet,
    pub collider_set: ColliderSet,
    pub broad_phase: BroadPhase,
    pub narrow_phase: NarrowPhase,
}
```

接下来，我们需要提供 `NIF` 函数接口用来创建该结构。结构分为两部分：`Rust` 部分以及 `Elixir` 部分。代码略，按照 `Rustler` 要求编写即可。

= PhysicsManager

我们需要在 `Elixir` 的监督树中创建一个进程，用于在服务器程序的生命周期内持有一个 `PhySys` 全局对象供各个实体调用。这个进程目前只需要两个功能：

1. 持有 `PhySys` 对象引用
2. 提供获取 `PhySys` 对象接口

我们把这个进程叫做 `PhysicsManager` ，为其创建一个单独的监督者。监督者代码略， `PhysicsManager` 关键代码如下：

```elixir
@impl true
def handle_continue(
      :load,
      state
    ) do
  # 从 NIF 函数获取 PhySys 对象的引用
  {:ok, physys_ref} = SceneServer.Native.SceneOps.new_physics_system()
  
  {:noreply, %{state | physys_ref: physys_ref}}

end

@impl true
def handle_call(:get_physics_system_ref, _from, %{physys_ref: physys_ref} = state) do
  # 获取 PhySys 对象引用
  {:reply, {:ok, physys_ref}, state}
end
```

= PlayerCharacter

为了使用方便，目前暂且规定让每个玩家角色进程均持有一个 `PhySys` 对象引用，在自身初始化时获取并存入进程状态：

```elixir
{:ok, physys_ref} = SceneServer.PhysicsManager.get_physics_system_ref()

{:noreply,
  %{
    state
    | physys_ref: physys_ref,
      aoi_ref: aoi_ref,
      character_data_ref: cd_ref,
      movement_timer: movement_timer
  }}
```

这样一来，物理引擎的准备工作就完成了。

= 下一步

将角色移动的逻辑迁移到物理引擎上来。

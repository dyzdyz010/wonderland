#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(25) - Scene Server(14) - Rapier角色控制器",
  desc: [本节我将简单介绍我们要用到的主要工具：Character Controller Character Co],
  date: "2022-12-17",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.rust,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

本节我将简单介绍我们要用到的主要工具：`Character Controller`

`Character Controller` 是一种让实体进行非物理移动的工具。它不受力的影响，而是按照给定的位移来移动，这正好是我们的玩家角色移动所需要的。

玩家角色的移动是由用户输入触发，而不是在力的驱使下，因此用 `Character Controller` 来移动玩家角色最好不过。

`Character Controller` 在 `Rapier 3D` 中叫做 *Kinematic Character Controller* ，它能够自动计算射线检测或者形状检测，以探测前方多远的地方存在障碍物，从而调整移动的目的地。

虽然这东西叫做 `Character Controller`，但是它不止可以用作角色移动，其他进行不受力的影响而移动的物体也可以使用，比如一个移动平台。

`Character Controller` 的主要功能有以下几点：

1. 在障碍物前停止
2. 走上不是很陡的斜坡
3. 自动爬台阶
4. 越过较小的障碍
5. 与移动平台交互

`Rapier 3D` 的 `Character Controller` 只暴露了两个接口：

- `move_shape`: 根据设定参数和前方障碍计算可能的位移
- `solve_character_collision_impulses`: 对碰撞进行定制化处理。这个接口是以回调形式提供的，可以在上一个接口中直接处理

下面给一个使用的例子：

```rust
// The translation we would like to apply if there were no obstacles.
let desired_translation = vector![1.0, -2.0, 3.0];

// Create the character controller, here with the default configuration.
let character_controller = KinematicCharacterController::default();

// Calculate the possible movement.
let corrected_movement = character_controller.move_shape(
dt, // The timestep length (can be set to SimulationSettings::dt).
&bodies, // The RigidBodySet.
&colliders, // The ColliderSet.
&queries, // The QueryPipeline.
character_shape, // The character’s shape.
character_pos, // The character’s initial position.
desired_translation,
QueryFilter::default()
// Make sure the the character we are trying to move isn’t considered an obstacle.
.exclude_rigid_body(character_handle),
|_| {} // We don’t care about events in this example.
);

// TODO: 利用 `corrected_movement` 来更新角色刚体或碰撞体的位置
```

有了修正后的位移之后，我们可以根据代表对象的不同来设置正确的位移：

- 一个没有和任何刚体绑定的碰撞体，直接在它当前的位置上加上修正位移
- 一个基于速度的刚体，将速度设置为修正后位移除以步进时间长度
- 一个基于位置的刚体，和上面的碰撞体类似

这样一来，我们的移动策略就可以变一变了：

以碰撞体的位置为准，利用 `Character Controller` 对其进行更新，并发送给各客户端，而不再单独存储位置变量了。

= 下一步

改造移动同步功能，使用上面提到的 `Character Controller` 以及涉及到的物理引擎相关组件。

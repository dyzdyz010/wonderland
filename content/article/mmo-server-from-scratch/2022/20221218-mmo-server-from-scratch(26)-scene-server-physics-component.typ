#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(26) - Scene Server(15) - 创建角色物理组件",
  desc: [本节开始我们来对之前已有的移动组件进行改造。 当前的移动组件，位置是直接存储为结构体内一个字段的： 但是],
  date: "2022-12-18",
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

本节开始我们来对之前已有的移动组件进行改造。

当前的移动组件，位置是直接存储为结构体内一个字段的：

```rust
pub struct Movement {
    pub location: Vector,
    pub velocity: Vector,
    pub acceleration: Vector,
    pub timestamp: u64,
    pub is_in_air: bool,
}
```

但是下一步既然要用物理组件的位置表示玩家角色的位置，那么这个 `location` 字段就需要被替换。替换成什么呢？

= 物理移动组件 PhysicsComp

我们新建一个结构体，作为 `Movement` 组件的一个字段存在。这个结构体内存放着 `Rapier 3D` 物理引擎相关的类对象，比如 `Character Controller`：

```rust
pub struct PhysicsComp {
    character_controller: KinematicCharacterController,
    collider_handle: ColliderHandle,
}
```

这里我们只存储两件东西：

- `character_controller` - 角色控制器，负责移动
- `collider_handle` - 一个碰撞体的句柄，用于操纵角色碰撞体的碰撞事件、位置等

之后我们来编写一个初始化函数：

```rust
pub fn new(location: Vector, physys: &mut PhySys) -> PhysicsComp {
    let collider = ColliderBuilder::capsule_z(0.3, 0.15)
        .translation(Vector3::new(location.x, location.y, location.z))
        .build();
    let collider_handle = physys.collider_set.insert(collider);
    let character_controller = KinematicCharacterController::default();

    PhysicsComp {
        character_controller,
        collider_handle
    }
}
```

这里，我们创建了一个 `z` 方向的胶囊形状碰撞体，赋予位置，并把它加入到碰撞体集合中，将返回的一个 `handle` 存储到结构体中方便下次使用。

我们还需要一个位置更新函数，用来更新碰撞体的位置：

```rust
pub fn controller_move(&mut self, translation: Vector, physys: &mut PhySys) -> Vector {
    let collider = &physys.collider_set[self.collider_handle];
    let desired_translation = Vector3::new(translation.x, translation.y, translation.z);

    let corrected_movement = self.character_controller.move_shape(
        physys.integration_params.dt,
        &physys.rigid_body_set,
        &physys.collider_set,
        &physys.queries,
        physys.collider_set[self.collider_handle].shape(),
        collider.position(),
        desired_translation,
		QueryFilter::default().exclude_collider(self.collider_handle),
        |_| {},
    );

    let collider = &mut physys.collider_set[self.collider_handle];
    collider.set_translation(collider.translation() + corrected_movement.translation);

    return self.get_location(&physys);
}
```

这里，我们利用 `Character Controller` 的 `move_shape` 对角色的碰撞体向目标坐标移动进行判定，看途中有没有什么障碍物阻挡移动。如果没有，那么就可以顺利地移动到目标位置；如果被阻挡了，那么这个函数就会返回在阻挡物前面可以到达的位置，即停到障碍物边上。获取到新的目标位置后我们对碰撞体的位置进行更新即可。

注意参数 `translation`，这是一个平移参数，也就是移动的距离，而不是目标位置的坐标，因为 `move_shape` 函数需要的参数是移动距离向量。

这个函数中我们使用了一个 `PhySys` 类型的参数，这个参数是整个物理系统的指针，我们对物理实体所做的所有操作都需要在这个系统内的数据上进行。

除此之外，因为在上述函数中我们所用的坐标计算是矩阵形式的，是物理引擎类型，对 `Rustler` 与 `Elixir` 之间传递数据不友好，因此我们需要把它转换成有好的数据类型，也就是我们自己定义的类型 `Vector`。编写一个函数实现此功能：

```rust
pub fn get_location(&self, physys: &PhySys) -> Vector {
    let collider = &physys.collider_set[self.collider_handle];

    return Vector{x: collider.position().translation.x, y: collider.position().translation.y, z: collider.position().translation.z};

}
```

= 下一步

创建上面提到的 `PhySys` 类型，并向 `Elixir` 代码中加入保持相关数据的进程和监督者，同时把本节的物理组件整合到已有的 `Movement` 组件中。

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *
#import "/templates/mod.typ": code-image
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#show: main.with(
  title: "MMO Server From Scratch(4) - Scene Server(1) - AOI - 算法与数据结构",
  desc: [本节着重讨论场景服务器的 AOI 模块中的 NIF 部分，确定接口、算法和数据结构。],
  date: "2022-10-21",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.server,
    blog-tags.game,
    blog-tags.elixir,
  ),
)

本节着重讨论场景服务器的 `AOI` 模块中的 `NIF` 部分，确定接口、算法和数据结构。

= 功能解析

`AOI(Area Of Interest)` 是用来管理大世界上各种实体之间位置关系的模块，可以接受某个实体的 *查询身边其他实体* 的请求，同时负责维护各实体位置关系的数据结构。当实体在大世界上发生移动时，`AOI` 模块需要更新实体在数据结构中的位置，以便业务进程在请求身边实体列表时返回更新后的结果。

从描述上就可以看出，这个模块需要频繁进行列表的查询、插入、删除操作，计算量不算小，因此如果把这部分功能拿给 `Elixir` 实现的话恐怕会力不从心，运算速度不足导致客户端之间的同步操作延迟过大，影响游戏体验。因此我们选择使用更快速的办法实现这个模块——`NIF(Native Implemented Functions)`，使用执行效率更高的语言实现计算量最大的部分，同时在 `Elixir` 中提供调用接口，这样将两种语言的代码联系起来，各取所长。

经过一段时间的网上搜索，最终选定了 #link("https://github.com/rusterlium/rustler", "Rustler") 库，该库使用 `Rust` 作为 `NIF` 函数编写语言，同时提供了运行时安全保障，使得 `NIF` 函数中的错误不会Down掉整个 `BEAM` 虚拟机，而这个问题是 `NIF` 的一个重要缺陷，而 `Rustler` 解决了这个问题；同时 `Rust` 也提供了安全的内存管理特性，使得我可以不必像在 `C++` 中那样时刻关注内存分配和销毁的情况。

= 算法和数据结构分析

我们需要的操作基本分为三种：*查找*、*插入*、*删除*。可以选择的数据结构基本为两种：`数组` 和 `链表`。下面分别讨论两种结构的特点。

== 数组

数组是一块连续的内存空间，使用索引下标访问元素。

对于 *查找* 来说，不同情况下的时间复杂度见表：

#figure(caption: "数组查找时间复杂度")[
  #table(
    columns: (1fr, 1fr, 1fr),
    inset: 4pt,
    align: (center, center, center),

    table.header("是否拥有索引", "是否有序", "时间复杂度"),
    [是], [-], [O(1)],
    [否], [否], [线性查找 O(n)],
    [否], [是], [二分查找 O(lg(n))],
  )]

对于 `插入` 和 `删除` 来说，假设已经确定元素索引，其复杂度均为 `O(n)`，因为插入和删除某个元素时，其后的元素均需要整体移动。

可以看出，`数组` 结构对于 `查找` 来说效率较高，但 `插入/删除` 元素则效率较低。

== 链表

链表是通过元素内指针指向其他元素形成的链式结构。

对于链表来说，由于 `查找` 只能对结构进行遍历，因此其时间复杂度为 `O(n)`。但是如果查询方持有元素且链表有序的话则可以相对降低，但在最坏情况下依然为 `O(n)`。

对于 `插入` 和 `删除` 来说，如果不考虑查找过程，链表只需要修改元素本身及前后元素的指针即可，因此其时间复杂度为 `O(1)`。

== 总结

对于 `AOI` 中的场景，一般是 *玩家移动 -> `AOI` 更新元素位置 -> 玩家获取元素周围一定半径内其他元素* 。当 `AOI` 更新元素位置时，意味着元素顺序会频繁变化，这样对于数组来说就失去了其最大优势—— *索引*。如果采用数组结构，那么对元素所作的所有操作都将有一个前置操作—— *二分查找*。这样的话与 `链表` 相比，效率上应该略逊一筹。

`数组` 和 `链表` 都可以通过建立 *层* 机制进行优化，使得花费时间进一步减少。至于优化后的结构孰优孰劣，待我有时间全部实现后再做对比。

至于本系列，由于本人对链表很久不用了不甚熟悉，而且在类似问题上找到了 #link("https://discord.com/blog/using-rust-to-scale-elixir-for-11-million-concurrent-users", "Discord 的一篇文章")，该文章使用了类似 `跳跃表` 的机制，将数组变成了两层，提高了对其进行操作的速度。为了方便起见，在目前本人暂时先选择 `数据` 的形式，在 `Discord` 代码的基础上进行改造。

= 简要实现

首先为我们的 `scene_server` 添加依赖，将依赖项添加到 `mix.exx` 文件的 `deps` 函数中：

```elixir
{:rustler, "~> 0.26.0"}
```

然后使用命令创建 `NIF` 模块：

```bash
mix rustler.new
```

根据提示输入 `Elixir` 和 `Rust` 中的模块名称。本人使用的是 `SceneServer.Native.CoordinateSystem` 和 `coordinate_system`。

该命令会在 `scene_server` 项目文件夹下生成 `native` 文件夹，并将 `NIF` 模块文件放在其下：

#figure(caption: "Rustler 结构")[
  #image("/public/assets/img/2022/20221021_rustler_structure.png")
]

== SortedSet分析

上面 `Discord` 的文章中实现了一个名为 `SortedSet` 的数组结构，其包含一个元素为 `Bucket` 的数组，而 `Bucket` 则包含一个元素为 `Item` 的数组，如此将一个数组定义为两层。本节中我也将沿用这些名称，对代码进行改造。

== Item

`Item` 即是最基本的元素结构体，其包含 `实体ID` 、 `坐标` 、 `所在轴向` 三个属性：

```rust
// 轴向枚举类型
#[derive(NifUnitEnum, Clone, Debug, Copy)]
pub enum OrderAxis {
    X,
    Y,
    Z,
}

// 坐标结构体类型
#[derive(NifTuple, Clone, Debug, Copy)]
pub struct CoordTuple {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

// Item结构体类型
#[derive(NifStruct, Clone, Debug, Copy)]
#[module = "Item"]
pub struct Item {
    pub cid: i64,
    pub coord: CoordTuple,
    pub order_type: OrderAxis,
}
```

其中的 `NifUnitEnum`、`NifTuple`、`NifStruct` 是为了将 `Rust` 内的类型转化为 `Elixir` 类型，从而使得其可以被传递。

为了能让 `Item` 之间能够被比较和排序，我们需要实现几个 `Trait` ：

1. PartialEq
2. PartialOrd
3. Eq
4. Ord

实现细节此处就不再展示了，各位看官有兴趣自行实现即可。此处之讨论一下 `Item` 之间该如何比较。

如果是 `排序` 的话，我们需要一个可以被排大小的值，在这里就是坐标值 `coord` 了，但是三个方向的顺序怎么确定呢？这是 `order_type` 就派上用场了，`order_type` 是哪个轴，那我们就把坐标里哪个轴上的数值拿来比较。

如果是 `查找` 的话，有了上面的比较大小还不够，别忘了我们的 `cid` 属性。坐标值相等并不意味着两个 `Item` 元素就是相等的。想想我们什么时候需要查找元素？只有唯一的一个场景，那就是找到对应玩家/实体的 `Item`，而实体之间的区分使用 `cid`，因此在相等条件中我们还需要加入 `cid` 相等的逻辑。

除此之外我们还需要一个 `distance(距离)` 方法，用来计算两个 `Item` 之间的距离，使用简单的勾股定理即可。

之后可以写几个单元测试用例，试一试 `Item` 的功能正不正常。

== Bucket

`Bucket` 是一个包含 `Item` 数组的结构体：

```rust
#[derive(NifStruct, Clone, Debug)]
#[module = "Bucket"]
pub struct Bucket {
    pub data: Vec<Item>,
}
```

作为包含元素列表的类型，`Bucket` 需要实现查找、插入、删除元素的方法。但是，贴心的 `Rust` 已经为我们实现了 *二分查找*；删除方法同样 `Rust` 内置类型 `Vec` 已经实现；对于插入，我们需要自行实现，对 `Vec` 的插入方法进行上层包装。这是因为我们想要让 `Bucket` 的长度固定，从 #link("https://doc.rust-lang.org/std/vec/struct.Vec.html#guarantees", "Rust官方文档")得知，`Vec` 有一个 `capacity(容量)` 属性，代表 `Vec` 预分配内存的大小，如果 `Vec` 长度超过了 `capacity`，那么 `Rust` 将需要为其额外分配内存，造成不必要的计算消耗；而且当我们需要 `插入/删除` 元素时，我们希望数组的长度越短越好。因此综合上面的因素，我们需要 `Bucket` 为固定长度。

这样一来，在插入元素的方法中，我们需要对列表长度进行判断，如果长度超过了设定的长度，则需要对列表进行 `分裂`，将一个 `Vec` 一分为二，成为两个对半分的 `Vec`。

`Bucket` 作为 `SortedSet` 的元素，同样需要具备比较的能力。但是比较特殊的是，`Bucket` 的比较对象是 `Item`，这是因为我们一般查找的对象都是 `Item`，在 `SortedSet` 进行查找时，需要确定给定 `Item` 在哪个 `Bucket` 内部。

最后，`Bucket` 还需要一个功能，那就是返回给定 `Item` 一定范围内其他 `Item` 列表的方法。实现很简单，使用 `filter` 方法对列表内元素进行遍历即可，该过程可以借助 `Rayon` 库进行并行优化。

== SortedSet

`SortedSet` 是最外层真正的元素数组。其为一个包含 `Bucket` 数组的结构体，其同时还包含容量、元素数量等属性：

```rust
#[derive(Debug, NifStruct, Clone, Copy)]
#[module = "Configuration"]
pub struct Configuration {
    // Bucket最大容量
    pub bucket_capacity: usize,

    // SortedSet最大容量
    pub set_capacity: usize,
}

#[derive(Debug, NifStruct, Clone)]
#[module = "SortedSet"]
pub struct SortedSet {
    configuration: Configuration,
    buckets: Vec<Bucket>,
    size: usize,
}
```

与 `Bucket` 类似，我们也希望 `SortedSet` 有一个最大长度避免额外的内存分配开销，但是不需要分裂，只要最大容量即可。

方法实现与 `Bucket` 类似，需要 `新建列表`、`查找元素`、`插入元素`、`删除元素`、`查找一定范围内Item列表` 等方法。对于 `SortedSet` 来说，对元素的所有操作都需要先找到 `Bucket` 然后在对应 `Bucket` 中操作 `Item`。

== CoordinateSystem

最后是我们的顶层结构体 `CoordinateSystem`，包含 X、Y、Z 三个轴向的三个 `SortedSet` 成员：

```rust
#[derive(Debug, NifStruct, Clone)]
#[module = "CoordinateSystem"]
pub struct CoordinateSystem {
    configuration: Configuration,
    axes: Vec<SortedSet>,
}
```

此处 `SortedSet` 以列表形式存储，是为了后期对其进行并行优化。例如 `插入元素` 方法：

```rust
pub fn add(&mut self, item: &Item) -> AddResult {
    let mut jobs: Vec<SetAddResult> = Vec::with_capacity(3);

    self.axes
        .par_iter_mut()
        .enumerate()
        .map(|(idx, ss)| {
            return ss.add(Item {
                cid: item.cid,
                coord: item.coord.clone(),
                order_type: OrderAxis::axis_by_index(idx),
            });
        })
        .collect_into_vec(&mut jobs);

    let result = match (jobs[0], jobs[1], jobs[2]) {
        (SetAddResult::Added(ix), SetAddResult::Added(iy), SetAddResult::Added(iz)) => {
            AddResult::Added(ix, iy, iz)
        }
        (rx, ry, rz) => AddResult::Error((rx, ry, rz)),
    };

    result
}
```

其中的 `par_iter_mut()` 方法将一个 `Vec` 中的元素转化为并行迭代器，使得 `map` 方法可以在每个元素上并行运行。

`CoordinateSystem` 要实现的方法就是接口所需的所有方法，目前实现的有：

1. 建立结构
2. 插入元素
3. 删除元素
4. 更新元素位置
5. 查找一定范围内`Item`列表

= 接下来的工作

`Nif` 部分到这里基本完成，我们拥有了一个简陋但相对完整的 `AOI NIF` 库，下一步我们将继续将其接入到 `Elixir` 程序里，使其可以被玩家进程调用。

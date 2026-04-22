#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(24) - Scene Server(13) - 物理引擎Rapier简介",
  desc: [让我们继续回到场景服务器 scene\_server 的编写上来。之前提到过，我打算向服务器增加物理引擎用],
  date: "2022-12-16",
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

让我们继续回到场景服务器 `scene_server` 的编写上来。之前提到过，我打算向服务器增加物理引擎用于客户端数据验证，今天我们就来看看物理引擎的选型。

= 选型

最先了解到的是大名鼎鼎的 `PhysX`，`UE` 内置的也是这个，足见他的能力是多么强大。然而，对于我们的代码来说，计算密集型的任务是用 `Rust` 语言来完成的，实在是没有必要再引入一套 `C++` 代码来增加项目的复杂度了。因此，问题转化为，在 `Rust` 语言编写的物理引擎中哪一个更好一点？

有一个小网站：#link("https://arewegameyet.rs/ecosystem/physics/")[Physics | Are we game yet?]，可以看到目前在物理引擎领域 `Rust` 已经有了哪些成果：

#figure(image("/public/assets/img/2022/20221216-mmo-server-from-scratch(24)-scene-server-rapier-introduction-1.png"), caption: "Pasted image 20221216203224.png")

可以看到，已有的物理引擎库还是很多的。但是哪个更靠谱一点呢？

有意思的是，`PhysX` 也有 `Rust port` 存在。可惜的是这个项目目前还不是完全体，还在施工当中。我还是希望能选择一个目前已经比较完备的库来用。

从下载量、版本等参数来看，`rapier3d` 无疑胜出，下载量比第二名高出一倍，可见使用的人还是非常多的，质量有一定保障。

= Rapier 3d

== 性能

让我们来深入了解一下 `Rapier 3d`。它的官网上有 `Benchmark` 的链接#link("https://rapier.rs/benchmarks/")[Rapier physics engine | Rapier]，进去以后可以看到几个物理引擎之间的性能对比：

#figure(image("/public/assets/img/2022/20221216-mmo-server-from-scratch(24)-scene-server-rapier-introduction-2.png"), caption: "Pasted image 20221216204719.png")

从图中关于胶囊体的性能对比可以看出，`rapier3d` 的性能与 `PhysX` 相差无几，在实体数量较少的时候，`rapier3d` 的性能甚至略微超过 `PhysX`；在实体数量增加之后，`rapier3d` 也只比 `PhysX` 慢 3 毫秒左右。

== 功能

`Rapier 3D` 提供了常用的各种功能，比如物理模拟、碰撞检测、场景查询等。同时也支持 `CCD(Continuous collision detection)`，可以帮助检测高速物体，避免 *隧穿效应* 的发生。

= 结论

所以综上，`Rapier 3D` 是一个不错的选择。对于我们的项目来说，我打算只用它来检测已有的数据，因此物理模拟是不必要的，我们只需要进行碰撞检测和场景查询就可以，`Rapier 3D` 还提供了 `SIMD` 优化以及并行优化版本，能够使得其运行更加高效。

= 下一步

接下来我会逐渐想办法将 `Rapier 3D` 融入到我们的场景服务器中，为角色的移动功能服务。


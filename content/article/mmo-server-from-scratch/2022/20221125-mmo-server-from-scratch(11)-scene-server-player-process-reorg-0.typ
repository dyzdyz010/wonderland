#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(11) - Scene Server(9) - 角色进程重整(0)",
  desc: [本篇主要探讨一下 PlayerCharacter 相关进程的数据存储和逻辑结构调整。在上一篇 \[\[📄从零开],
  date: "2022-11-25",
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

本篇主要探讨一下 `PlayerCharacter` 相关进程的数据存储和逻辑结构调整。在前面 #link("/article/mmo-server-from-scratch/2022/20221123-mmo-server-from-scratch(9)-scene-server-movement-sync-3-player-movement-server")[从零开始的MMORPG游戏服务器(9) - Scene Server(7) - 移动同步(3) - 玩家移动 - 服务器部分 - 掘金 (juejin.cn)] 中我提到过，到目前为止的 `PlayerCharacter` 和 `AoiItem` 的代码结构不是很清晰，分工不明确，不利于后续开发。因此，我又重新思考了进程的职责定位，以及数据的存储位置，包括一些逻辑应该由哪个进程来执行等问题。

= 进程职责分配

在设计之初，我本来的想法是，充分利用 `Elixir` 多线程的优势，将一个玩家角色的不同功能分配给不同的进程完成，比如 `移动` 负责移动、`战斗` 负责战斗相关逻辑等等。但是到后来在写代码的过程中慢慢感觉到，这种方式对计算资源是一种浪费：*首先*，玩家角色的不同类的属性之间是有联动的，比如玩家释放一个位移技能会导致玩家的运动状态发生变化，这样会导致不同进程之间的固有消息发送与接收流量变大；*其次*，进程间通信是有成本的，延迟、CPU时间等都是成本，不符合游戏服务器的设计基本要求，过多的进程会造成进程间通信导致的资源浪费；*第三*，引入多进程的初衷是能够让不同功能的逻辑能够并行运行提高效率，但是在这里的情况下，大多数逻辑都是 _串行_ 的，采用多线程有种得不偿失的感觉。当然也有少部分逻辑是可以并行的，但是可以通过定时任务的方式使其交替运行互不干扰，但是可以节省跨进程通信的成本，目前我感觉是值得的。

经过上面的思考之后，我决定分配玩家角色相关进程的角色如下：

1. `PlayerCharacter` 负责自己的全部数据存储（包括属性、移动、状态、战斗相关等），并利用 `定时任务` 和 `Rust NIF` 进行运动、战斗等运算，对自身属性进行更新；
2. `AoiItem` 进程只负责定时获取周围玩家，以及向周围玩家广播消息。广播消息主要由 `PlayerCharacter` 进程触发，其他少数情况如频道聊天等也可触发。

= PlayerCharacter 进程布局设计

按照目前设想，`PlayerCharacter` 需要存储以下信息：

1. Movement - 移动相关数据，如位置、速度、朝向等
2. Attrs - 属性，包含成长属性和面板属性
3. Equipments - 装备列表
4. BattleOps - 战斗相关数据，如可用技能列表、当前状态、目标等
5. Bag - 背包数据

需要定时计算的逻辑主要有以下两种：

1. 移动，需要频繁计算玩家坐标
2. 战斗，需要实时结算各类伤害和效果

如下图：

#figure(image("/public/assets/img/2022/20221125-mmo-server-from-scratch(11)-scene-server-player-process-reorg-0-1.png"), caption: "Drawing 2022-11-12 21.59.01.excalidraw.png")

以上所有数据和逻辑全部放在 `NIF` 中，使用 `Rust` 实现，提高运行效率。

= 下一步

下一篇我将逐步实现上述内容，同时不影响已经实现的移动同步效果。


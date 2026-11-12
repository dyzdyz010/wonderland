#import "/templates/blog.typ": *
#import "/templates/enums.typ": *
#import "@preview/pintorita:0.1.4"
#import "/templates/mod.typ": typ_frame

#show raw.where(lang: "pintora"): it => pintorita.render(it.text)

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(29) - 四年后：服务端权威体素、QUIC 与跨 Scene 移交",
  desc: [四年后回头看这个系列：当年那些猜想后来哪些被推翻，服务端权威体素、QUIC 和跨 Scene 移交现在是怎么分工的。],
  date: "2026-11-11",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.rust,
  ),
  lang: "zh",
  i18nKey: "mmo-server-from-scratch/2026/20261111-mmo-server-from-scratch(29)-authoritative-voxel-quic-scene-handoff",
  sourceLang: "zh",
  translationStatus: "source",
  aiAuthored: true,
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[https://github.com/dyzdyz010/ex\_mmo\_cluster]
]

#let series-link(path, title) = link("/zh/article/mmo-server-from-scratch/2022/" + path, title)

#let arch-fig(caption, body) = figure(caption: caption, kind: image)[
  #typ_frame("pintora-diagram flex justify-center")[
    #show raw.where(lang: "pintora"): it => pintorita.render(it.text, style: "dark")
    #body
  ]
]

= 从 (28) 说起

#series-link("20221220-mmo-server-from-scratch(28)-scene-server-update-nif-interfaces", "从零开始的MMORPG游戏服务器(28)") 写完的时候，物理引擎这一轮替换告一段落，下一步是重新思考移动同步的客户端执行过程。那时靠 `NavMesh` 跨越地形已经显出问题，跳跃也还等着同步。那是 2022 年 12 月 20 日，之后这个系列停了很久。

这一篇回头看整条路。仓库还是那个 `ex_mmo_cluster`，里面跑着的主线已经和 #series-link("20220608-mmo-server-from-scratch(0)-introduction", "(0) 引言") 那张架构图很不一样。我想讲清楚三件事：当年建立了什么，哪些猜想后来被换掉，以及现在为什么以体素世界为唯一真值、用 QUIC 做传输，并把当年推迟的跨 Scene 移交做了出来。文章聚焦服务端架构，客户端部分只谈概念。

#figure(
  image("/public/assets/img/2026/qinglan-entering-world.png"),
  caption: [青岚，进入世界时的加载画面。],
)

= 当年那张图里有什么

#series-link("20220608-mmo-server-from-scratch(0)-introduction", "(0)") 开头那几句话，现在回头看依然成立：当时能搜到的资料要么对架构泛泛而谈，要么对着某个算法纸上谈兵。我是纯粹的业外人士，抽象的东西很难指导动手，于是决定自己把服务器做一遍。选 `Elixir`，是因为它天然支持高并发，监督树和尽早崩溃的思路也打动了我。

那张整图大致是：`auth_server` 负责登录，`gate_server` 接客户端的 TCP 连接，`agent_server` 执行非场景逻辑（当时标了待定），`scene_server` 跑场景，`world_server` 统筹场景分配，数据层打算用 `Mnesia`，`beacon_server` 当集群的固定汇合点。客户端连接按 `one process per client` 来。我当时就写明，其中不少是猜想，实际性能要做出来才知道。

之后差不多半年，系列就沿着这张图往下砌。

#series-link("20220610-mmo-server-from-scratch(1)-beacon-server", "(1)") 先做灯塔。组成 Elixir 集群需要一个启动时就能连上的固定节点，默认全连接，所有节点两两相连。节点向灯塔登记自己的「资源」和「需求」，灯塔再按需求把已注册的节点介绍出去。

#series-link("20221016-mmo-server-from-scratch(2)-gate-server", "(2)") 做网关。客户端用 TCP Socket 连上 `gate_server`，消息用 Protobuf，一个连接一个 `TcpConnection` 进程，经灯塔注册后把流量转到业务服务器。监督树是 `Interface`、`TcpAcceptor` 和一组 `TcpConnection`。

#series-link("20221016-mmo-server-from-scratch(3)-scene-server-intro", "(3)") 请出场景服务器，第一阶段只做两件事：移动同步，以及玩家进入或离开游戏。AOI 选了十字链表。玩家跨场景服务器移动、因副本或传送进出大世界，我当时放到了「等后期代码完善之后再实现」。也是在这一篇，我定下了分工：重度计算交给 Rust NIF，并发消息和广播留给 Elixir。

接下来 #series-link("20221021-mmo-server-from-scratch(4)-scene-server-aoi-algorithm", "(4)") 和 AOI 监督树那篇，把十字链表做进 Rust 数据结构，再接到 Elixir 监督树上。然后是对时，再从 #series-link("20221026-mmo-server-from-scratch(6)-scene-server-movement-sync-0", "(6)") 到 #series-link("20221124-mmo-server-from-scratch(10)-scene-server-movement-sync-4-player-movement-client", "(10)") 做第一轮移动同步：指令队列、服务器坐标计算、进入场景，再做玩家移动的服务端和客户端。客户端在那些文章里是订阅者，由服务器把周围的人送过来。

所以 2022 年那一套就已经是服务器计算坐标：(6) 里有指令队列和服务器侧的坐标计算，(3) 里重计算走 NIF。后来变化的是四件事：合同收得更紧，传输换了，世界真值换了归属，跨 Scene 终于提上日程。

#series-link("20221125-mmo-server-from-scratch(11)-scene-server-player-process-reorg-0", "(11)") 到 (14) 是角色进程重整，中间专门写了 #series-link("20221127-mmo-server-from-scratch(13)-rustler-introduction", "Rustler")。(15) 和 (16) 思考物理引擎——移动校验、命中判定——以及移动误差，并需要一种可视化手段。于是 (17) 到 (23) 用 Phoenix 和 PIXI 做了 Visualize Server，用来查看角色列表、坐标和朝向，是一个调试和观察工具。

最后 #series-link("20221216-mmo-server-from-scratch(24)-scene-server-rapier-introduction", "(24)") 到 (28) 选定 Rapier 3D，用 Kinematic Character Controller 驱动角色移动，位置由碰撞体表示，Elixir 侧用 `PhysicsManager` 持有一份 `PhySys`。系列停在这里，复杂地形上的行走和跳跃同步留给了下一阶段。

= 哪些猜想后来被换掉了

四年后再打开这个仓库，变化最大的是当年图上的几块底座。下面这张表把旧文里的设想和公开仓库里的现状对照起来。

#figure(caption: "旧系列里的设想与现状")[
  #set text(size: 0.92em)
  #table(
    columns: (1.15fr, 1.45fr, 1.2fr),
    inset: 6pt,
    align: left,
    table.header([旧设想], [现在], [变化]),
    [客户端以 TCP 连上门，消息用 Protobuf。出处：(0)(2)。],
    [正式入口是 QUIC，可靠流和 DATAGRAM 分开走，旧的 TCP / WS 传输和 codec 已删除。出处：公开仓当前运行时说明，以及提交 `af180c98`。],
    [换传输的理由见下文。],
    [用 `beacon_server` 做集群固定汇合点，默认全连接。出处：(0)(1)。],
    [灯塔和各 app 的 `Interface` 模块已删除。拓扑改成配置的 JSON，由 `WorldServer.Topology` 在本机或对等节点上启动 Scene。出处：`af180c98` 与现行 README。],
    [只剩一个客户端以后，服务端收成单一发布，旧链路一并拆掉。],
    [数据层打算用 Mnesia，动态横向扩展。出处：(0)。],
    [持久化是 PostgreSQL 和 Ecto，修改日志和页表都在这里。出处：现行 README。],
    [回到主流数据库，理由见下文。],
    [玩家跨 Scene、副本和传送留到后期。出处：(3)。],
    [两 Scene 节点之间的受控移交已验收。出处：公开仓现行说明，以及提交 `981f27fe`。],
    [世界按 Scene 分区，玩家越界就要换写者，同一时刻只有一个写者，所以移交必须做。],
    [世界真值看起来是 Scene 里的角色和物理对象。出处：(15)–(28)。],
    [真值归 `VoxelRegion.World`：生成或烘焙的基底，加上已提交的修改日志。Scene 拿只读碰撞派生物，旧的 Scene 内 chunk / field 链路已删除。出处：公开仓现行说明，以及提交 `af180c98`。],
    [世界模型的一次转向，单独成一个话题。],
    [Visualize Server 作为观察前端。出处：(17)–(23)。],
    [`visualize_server` 随旧链路一起删除。出处：`af180c98`。],
    [它和旧传输、旧移动模块在同一次拆除里离开了现行组合。],
  )
]

TCP 换成 QUIC，是因为 TCP 有队头阻塞，延迟也高。游戏里的消息按时效有不同的优先级，移动同步就是最典型的一类，这类消息 TCP 处理不好。QUIC 把可靠的控制流和讲究时效的数据报分开：按 RFC 9000，流内有序，流与流之间没有全局到达顺序，DATAGRAM 在应用层整条收发。后面讲移交时还会用到「两条流各走各的」这一点。

数据库从 Mnesia 回到 PostgreSQL，理由很朴素：Mnesia 功能太弱，代码难写，相关的库也不活跃、用的人少。我选择回到大众路线，用大家都在用的 PostgreSQL，现在的持久化就是 PostgreSQL 加 Ecto。

NavMesh 和体素真值是两个独立的话题。(28) 里的 `NavMesh` 属于移动执行：角色怎么在地形上走、怎么跳。体素真值回答的是世界状态放在哪里：体素世界是唯一真值，碰撞读取权威占用，客户端看到的世界都来自它。

现行的空间合同是 Y 轴向上、以米为单位。

= 现在谁拥有什么

把现在的职责画成一张图，可以看到四条边界：谁管连接，谁管这个人的运动，谁有资格改世界，谁负责把人从一块权威域交到另一块。

#arch-fig("现行职责：连接、玩家进程、唯一可写的世界")[
```pintora
sequenceDiagram
  autonumber
  participant C as 客户端
  participant G as Gate
  participant S as Session
  participant P as Player
  participant Sc as Scene
  participant W as World
  C->>G: QUIC 流与 DATAGRAM
  G->>S: 入场登记与身份
  G->>P: 输入直达该玩家
  P->>Sc: 不可变的运动结果
  Sc->>W: 只读碰撞 / 世界意图
  W-->>Sc: Replica 与权威增量
```
]

连接这一侧由 Gate、鉴权和 `WorldServer.Session` 组成。客户端经 QUIC 进来，Gate 负责鉴权、解码和按通道路由。`WorldServer.Session` 是角色会话的唯一登记处，管理身份和 session 代际，处理重复登录，并在移交时提交切换。

场景这一侧，Scene 拥有公共时间、成员关系和碰撞版本的发布。每个已鉴权的身份有一个 `Player` 进程，独占输入槽、运动状态、模拟进度和确认前缀。入场绑定之后，Gate 把输入直接交给这个 owner。复制层消费 Player 产出的不可变结果，再分发给观察者。AOI 现在用带滞回的格网算法。

世界这一侧，只有 `VoxelRegion.World` 能写。真值是生成或烘焙出来的基底，加上之后每一笔已提交的修改。Scene 节点上的 `Replica` 是只读的区域视图，碰撞派生物从权威世界或本地只读副本重建。权威节点启动时先烘好基底，再启动 World；基底齐备，应用才完成启动，依赖它的 Gate 才开始监听。

编排归 `WorldServer`：路由、受控移交，以及一份显式的 JSON 拓扑。服务端在 Linux 上构建和运行，运行时是 Elixir 和 OTP，原生计算走 Rustler，字节合同集中在纯库 `mmo_contracts` 里，按 Session、Movement、Voxel 划分。

服务端权威依然是全局铁律，覆盖面比 2022 年更广：移动、AOI、体素、对象状态都以服务端为准，客户端负责预览、呈现和发送意图。体素的确认态只来自权威结果；来源不完整时显式拒绝，保证客户端的世界始终和权威一致。

= 移动同步：更严的合同，新的传输

(6) 到 (10) 的服务器计算和周围人广播，(24) 到 (28) 接进 NIF 的 Rapier，在今天的仓库里都延续了下来：共享的 Rapier 运动内核还在，服务端依旧推进运动。变化在它周围的合同上。

碰撞读取权威体素占用，能不能走由服务端的世界决定。协议从当年散落在网关里的 Protobuf 消息，收拢到纯库 `mmo_contracts`，旧的移动协议随之退场。时间线是固定步长和公开的 tick，我很喜欢这样一句话：物理时间从来不是靠数包数造出来的。

传输换成了 QUIC，理由上一节已经说过。服务端权威的移动闭环已经验收，覆盖引导、Ready、移动，以及真实双客户端联调。

客户端这一侧，我只讲概念。它是服务端权威的状态同步，加上本人的预测和校正。逻辑上的校正与 Mesh、相机的平滑分层处理；远端玩家用带时间戳的快照做插值；网络统计由回调产出不可变快照，游戏线程只负责消费。服务端「输入进权威、确认再回来」的合同，在客户端就对应预测、校正和呈现这三层。

为了并发，Scene 把玩家拆开推进：每个玩家一个 `Player` 进程，复制再分到多个观察者 worker 上。

= 跨 Scene 移交：当年推迟的那件事

(3) 里推迟的跨场景移动，现在成了必需。世界被切成多块 Scene 权威域，分区是配置好的静态范围；玩家越出本 Scene 的权威盒，就要换写者。同一角色在同一时刻只有一个写者，每条输入只执行一次，新代际的状态只接受新代际的输入和快照。

这一轮受控移交在同一台主机的两个独立 BEAM 虚拟机上完成验收，两边使用显式对齐的公共 tick 零点。提交 `981f27fe` 把本地 Replica 和受控移交做进了公开仓库。

流程大致如下。

#arch-fig("受控移交时序（概念示意）")[
```pintora
sequenceDiagram
  autonumber
  participant P as 源 Player
  participant G as Gate
  participant S as Session
  participant D as 目标 Scene
  P->>G: 越出本区权威范围
  G->>P: 与先前输入同发送者 seal
  G->>S: 预留新的会话代际
  S->>G: 准备完成
  G->>P: 通知切换
  @note over P,D: 目标 Ready 之后才积分
  P->>G: Ready
  G->>S: 提交移交
  S->>D: 源先放下，目标再激活
```
]

两个节点各自运行 Scene 和一份本地只读 Replica，权威世界只有一处写入。邻区之间交换只读的复制帧，让边界两侧的人互相看得见；这些记录只用于观察，碰撞裁决仍由本地 Player 完成。

玩家越界后先停步。正在转发输入的那个 Gate 发起 seal，借助 OTP「同一发送者的消息有序」的语义，保证封口排在先前所有输入之后。`WorldServer.Session` 预留新的 session 代际，连接通知客户端切换，等匹配新身份和切点的 Ready 到达后才提交。源先放下写者，目标再激活。原生物理句柄留在各自节点，目标侧自己重建。

目标侧用本地已有的共同基线，加上源带来的碰撞检查点重建历史，再导入输入槽；Ready 之后才开始积分。输入序号和 tick 在移交前后保持连续。

在客户端看来，切换前后是同一个角色、同一条输入序号、同一份预测历史，人带着已经走到的状态越过边界。

体素编辑由连接上懒启动的一个串行 worker 执行，Gate 会话继续处理输入和 Ready。控制走一条可靠流，编辑走另一条，两条流之间没有全局到达顺序，所以移交过程要能容纳迟到的编辑。现在的范围是共用同一份世界的两个 Scene。之后仓库里又补了测试，验证需要跨过切点的效果回执在真实的 scene handoff 之后依然能收到。

= 保留了什么，换掉了什么，接下来做什么

保留下来的：Elixir 和 OTP 的进程与监督边界；(3) 定下的分工，重度计算放进 Rust NIF；Rapier 作为角色运动内核，并进了两端共享的内核；每个玩家一个进程，现在由它独占输入、状态和确认前缀；从 (6) 开始的服务端计算移动，合同更严了；AOI 还在，换成了格网算法；仓库还是同一个公开仓库。

换掉的：正式入口从 TCP 加 Protobuf 换成 QUIC；集群从灯塔加全连接换成显式 JSON 拓扑；数据层从 Mnesia 换成 PostgreSQL；体素真值从 Scene 内的 chunk 进程收归 `VoxelRegion.World`；Visualize Server 和旧 Interface 模块随旧链路退场；跨 Scene 移交从「后期再说」变成了已验收的能力。

已经完成的是服务端权威的移动闭环，以及同一台主机上两个 Scene 之间的受控移交（本地 Replica）。接下来要做的是完整的容量验收、跨机部署与时钟，以及故障接管和动态分区。

(0) 结尾我写过：因为找不到同好，只有我一个人孤军奋战，不知能坚持多久。四年过去，仓库还在，主线还在往前走，当年那张图里的好几块底座被我亲手换掉了。猜想本来就是拿来验证的，下一篇接着往前写。

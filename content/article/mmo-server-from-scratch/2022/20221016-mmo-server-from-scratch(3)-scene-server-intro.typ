#import "/templates/blog.typ": *
#import "/templates/enums.typ": *
#import "/templates/mod.typ": code-image
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node

#show: main.with(
  title: "MMO Server From Scratch(3) - Scene Server(0) - 概要",
  desc: [MMO Server From Scratch(3) - Scene Server(0) - 概要],
  date: "2022-10-19",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.server,
    blog-tags.game,
    blog-tags.elixir,
  ),
)

今天开始实现服务器的第三个部件 - *scene_server*，即场景服务器。本节只关注接下来一段时间将要简单实现的内容，而不是一个完整的场景服务器。场景服务器包含的内容极多，我们将一步一步将其实现。

= 功能解析

场景服务器 `scene_server` 用于为玩家提供场景服务，即玩家在进入地图之后的一切与场景相关的内容均由场景服务器提供，如移动同步、周围玩家状态更新、战斗结算、玩家行为验证等。

`scene_server` 的消息可以来自其他不同服务器，如网关服务器 `gate_server`、世界服务器 `world_server`、用户代理服务器 `agent_server`等。但是如果把全部的功能点一次性全部纳入考虑的话我怕会顾不过来，所以目前让我们把注意力集中在场景服务器最基本的职能上：*移动同步*。

当然我们不能丢到最基础的功能：`玩家进入/离开场景`

== 移动同步

什么是移动同步？简单地说，在多人游戏里，你需要看到你身边的其他玩家，队友也好、敌人也好，你希望能够看到身边其他玩家的各种操作，角色的位置和移动也是各种操作中的一种。为了实现这种效果，当你的角色在移动时，你需要将自己移动的信息发送给身边所有玩家，以便他们在自己的客户端上更新你的角色表现，使得他们看到的和你看到的内容是 *一致* 的。

这里涉及两个条件：

1. 将自己的信息发送给其他多个玩家
2. 信息发送的目标是自己周围一定范围内

即：在所有玩家中搜索出自己身边的玩家，并向他们广播自己的移动消息。这个功能有个专有名词，叫做 `AOI(Area Of Interest)`。顾名思义，每个玩家都具有一个自己感兴趣的范围，在这个范围内发生的事情才会告诉客户端，超出这个范围的动静一概不管（当然也没有这么绝对）。

因此为了实现在游戏中能够看到其他玩家的移动，我们需要实现一个 `AOI` 系统。经过一番资料搜索，目前实现 `AOI` 的方式主要有三种：

1. 灯塔
2. 九宫格
3. 十字链表

这三种方式大家可以自行搜索。在这里我选择了 `十字链表` 作为前期粗略实现，也让自己对相关概念进行了解。

== 玩家进入/离开场景

玩家进入或离开场景的情况不止一种，目前我能想到以下几种：

1. 玩家进入/离开游戏
2. 玩家移动过程中去往其他场景服务器
3. 玩家因为某些玩法（如副本、传送等）离开/进入大世界

当前为了方便我们只考虑第一种，其他两种待后期代码完善之后再进行实现

= 简要设计

== 计算量规划

`scene_server` 作为场景管理服务器，集多项职能于一身，且多数职能属于计算密集型。`Elixir` 可能再并发方面比较擅长，但在数学计算方面与 `C/C++` 一系的语言相比就差得多了。但幸运的是，`Elixir` 和 `Erlang` 一样可以允许通过多种方式与外部程序通信：

1. C Node
2. NIF
3. Port Driver
4. Port

每种方法都有不同的特点和适用环境。在这个项目里，我们需要的是巨大的计算量和相对较低的延迟，而在以上四种方法中，`NIF` 的消息传递延迟是最低的，而且有一个非常棒的 `NIF` 库使得 `NIF` 的开发过程更加高效，程序更加健壮—— `Rustler`。该库使用 `Rust` 作为 `NIF` 函数的开发语言，兼具了内存安全和高效，可谓完美之选。

因此，将重度计算的内容扔给 `Rust` 来做，如 `AOI` 数据管理、各种计算验证等；并发消息传递的工作由 `Elixir` 来完成，如玩家之间的交互、消息广播等。

== 初步监督树

为了让前期的代码尽量简化，前期的功能规划目前只包括以下几部分：

1. 玩家进程模块 `PlayerCharacter`，每个玩家为一个进程，玩家交互通过进程间消息传递实现
2. 玩家管理模块 `PlayerManager`，用来管理玩家 `ID` 与进程之间的映射，方便其他进程进行查询从而向目标玩家进程发送消息
3. `AOI` 管理模块 `Aoi`，用来与 `NIF` 通信，操纵 `AOI` 数据结构（十字链表）
4. 集群操作模块 `Interface`，与其他服务器一样

监督树形态大概如下：

#figure(
  code-image.with(class: "center")(theme => [
    #set text(font: "DejaVu Sans Mono", size: 12pt)
    #let nodebox = (position, text, fill) => node(position, text, fill: fill, inset: 8pt)
    #let edge-box(body) = box(fill: rgb("#10aec2"), inset: 4pt, text(white, body))
    // #set page(width: auto, height: auto, margin: 5mm, fill: white)
    #let node-text = text.with(white)
    #let colors = (green.darken(20%), eastern, blue.lighten(20%))
    #let edge = edge.with(stroke: theme.main-color)

    #diagram(
      edge-stroke: 1pt,
      node-corner-radius: 5pt,
      edge-corner-radius: 8pt,
      mark-scale: 100%,

      nodebox((1, 0), node-text[Application], colors.at(0)),

      nodebox((0, 1), node-text[InterfaceSup], colors.at(1)),
      nodebox((1, 1), node-text[PlayerManagerSup], colors.at(1)),
      nodebox((2, 1), node-text[PlayerCharacterSup], colors.at(1)),

      nodebox((0, 2), node-text[Interface], colors.at(2)),
      nodebox((1, 2), node-text[PlayerManager], colors.at(2)),
      nodebox((2, 2), node-text[PlayerCharacter], colors.at(2)),
      // node((2, 0), align(center)[arithmetic & logic \ unit (ALU)], fill: colors.at(1)),
      // node((2, -1), [control unit (CU)], fill: colors.at(1)),
      // node((4, 0), [output], fill: colors.at(2), shape: fletcher.shapes.hexagon),

      edge((1, 0), (0, 1), "-}>"),
      edge((1, 0), (1, 1), "-}>"),
      edge(
        (1, 0),
        (2, 1),
        "-}>",
      ),

      edge((0, 1), (0, 2), "-}>"),
      edge((1, 1), (1, 2), "-}>"),

      edge(
        (2, 1),
        (2, 2),
        "-}>",
        label: edge-box[1:N],
        label-anchor: "center",
        // label-angle: -10deg,
      ),
    )
  ]),
  caption: "Scene Server Supervision Tree",
)

其中：

- application - `scene_server`主程序
- InterfaceSup - `Interface`模块监督者进程
- AoiSup - `AOI`管理模块监督者进程
- PlayerManagerSup - 玩家管理`PlayerManager`模块监督者进程
- PlayerCharacterSup - 玩家进程`PlayerCharacter`模块监督者进程
- Aoi - `AOI`管理模块进程
- PlayerManager - 玩家管理模块进程
- PlayerCharacter - 玩家进程

= 接下来的工作

前期一个极致简单的 `scene_server` 就先规划到这里，未来还会增加其他更多功能。下一篇将着重实现 `Aoi` 的 `NIF` 部分，使用 `Rust` 编写。敬请期待。

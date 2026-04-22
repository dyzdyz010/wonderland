#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(10) - Scene Server(8) - 移动同步(4) - 移动同步 - 玩家移动 - 客户端部分",
  desc: [从本节开始，我决定尽量就不贴代码了，除非我觉得逻辑特别复杂不好解释的地方。因为目前是在想法验证阶段，所以代],
  date: "2022-11-24",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.protobuf,
    blog-tags.ue5,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

从本节开始，我决定尽量就不贴代码了，除非我觉得逻辑特别复杂不好解释的地方。因为目前是在想法验证阶段，所以代码频繁变化，可能现在写好的代码过一段时间就面目全非了，容易给读者造成不必要的麻烦。所以大家专注于实现的思路就好了🤟

今天探讨移动同步实现的 *客户端部分*。

== 功能解析

在客户端上，移动同步的基本流程如下：

1. 检查速度变化，如果发生变化就发送移动事件
2. 移动事件回调函数提取移动数据并将数据发送至服务器，同时将事件存入指令队列，收到服务器确认后将事件移出事件队列
3. 其他客户端的 `TcpConnection` 模块收到服务器发来的角色移动广播消息，将其作为回调参数调用对应模块（`PlayerManager`）进行处理
4. `PlayerManager` 收到移动同步消息，根据 `cid` 检索场景中该角色引用，如果存在则向其发送移动状态更新事件
5. 被移动的角色对象收到事件，将自身移动到目标坐标

== 简要实现

=== 发送自身移动

首先为了能够检测玩家角色移动变化，我在角色蓝图 `ThirdPersonPlayerCharacter` 内新建了一个叫做 `NetEntityActionComponent` （我知道这不是个好名字，后面再改😋） 的组件，这个组件负责将玩家控制角色的运动状态变化存入指令队列并发给 `TcpConnection`。当玩家按下 WSAD 移动角色时，`ThirdPersonPlayerCharacter` 类会检测当前和上一帧速度有没有发生变化，如果发生了变化，那就将当前角色的 `位置` `速度` `加速度` 等信息发给 `NetEntityActionComponent`；

`NetEntityActionComponent` 收到移动消息后，将移动消息发送给 `TcpConnection` 以便进一步将移动信息发送给服务器，同时接收返回值（一个protobuf 的包）并将其存入指令队列；

`TcpConnection` 将移动信息发至服务器。服务器接收到消息后，更新服务器端玩家角色的移动状态，并向客户端返回一个响应消息。`TcpConnection` 接收到响应消息之后，查询已注册的回调列表，将消息发送给回调对象，即 `NetEntityActionComponent`。`NetEntityActionComponent` 收到响应消息后，将对应的移动消息从指令队列中移除，意味移动得到了服务器的确认。这个过程可以是乱序的，如果一个后进入队列的指令被先确认，则默认该指令之前的所有指令全部视为被确认即可。

=== 接收其他玩家角色移动

服务器向客户端发送了其他玩家的移动消息，被 `TcpConnection` 所接收到，同样地查询回调列表，将消息发给回调对象，在这里是 `PlayerManager`。

`PlayerManager` 收到移动消息后，根据消息内的 `cid` 查询自身存储的其他玩家角色字典，如果存在的话将新的目的地坐标发给该角色。角色在收到坐标后，更新自身的目标位置，同时利用 `AIController` 将角色向目标坐标移动。至此，客户端就可以看到其他玩家的移动了。

== 下一步

经过一番思考，我觉得现在的移动同步逻辑的位置不够合理，同时为了给其他逻辑预留空间，打算先重整一下 `PlayerCharacter` 和 `AoiItem` 进程的职责和功能。

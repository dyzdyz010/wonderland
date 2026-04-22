#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(8) - Scene Server(6) - 移动同步(2) - 玩家进入场景 - 客户端部分",
  desc: [今天探讨一下当有玩家进入 AOI 范围时客户端如何处理。在上一节—— 从零开始的MMORPG游戏服务器(6],
  date: "2022-11-22",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.ue5,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

今天探讨一下当有玩家进入 `AOI` 范围时客户端如何处理。在上一节—— #link("/article/mmo-server-from-scratch/2022/20221028-mmo-server-from-scratch(7)-scene-server-movement-sync-1-enter-scene-server#heading-2")[从零开始的MMORPG游戏服务器(6) - Scene Server(4) - 移动同步(1) - 玩家进入场景 - 服务器部分 - 掘金 (juejin.cn)] 中，服务器对于玩家进入范围的响应是即时的，当别的玩家向自己发送进入消息时，自己的进程会立即向服务器返回。后期可能考虑设计定时任务，一次性返回多项数据，一个潜在的优化方向记录一下。

== 功能解析

对于客户端来说是纯粹的订阅者，只需要等待服务器返回数据时进行处理，不需要轮询。

客户端的 `TcpConnection` 模块接收到消息后，需要判断消息的载荷类型，如果是 `玩家进入` 类型的消息，则根据自身存储的 `回调哈希表` 调用正确的回调对象。

回调方法收到消息后，对数据进行解包，得到进入玩家的 `CID` 和 `位置`，然后通知 `GameMode` 在场景中生成角色，并将 `CID` 和角色对象引用存入字典，用于处理其他如 `移动`、`玩家离开` 等消息。

== 简要实现

本节内容较简单，基本流程如下：

```mermaid
sequenceDiagram

participant S as Server
participant T as TcpConnection
participant P as PlayerManager
participant G as GameMode

P ->> T: 绑定回调(自身)
S ->> T: Packet(玩家进入)
T ->> P: 回调
P ->> G: 在场景中生成角色(Cid, Location)
G -->> P: 生成的角色引用

P ->> P: 存入字典(Cid, 角色引用)
```

=== 绑定回调

所谓绑定回调只是通知 `TcpSocketConnection` 模块将消息类型和自身对象引用存入字典：

```cpp
// PlayerManager.cpp

void APlayerManager::BeginPlay()
{
   Super::BeginPlay();

   // 玩家自己进入场景请求相应
   TcpConnection->BindReplyDelegate(reply::Result::kEnterScene, this);
   
   // AOI 广播消息
   TcpConnection->BindMessageDelegate(Packet::kBroadcastAction, this);
}
```

```cpp
// MP5DemoTcpSocketConnection.cpp

void AMP5DemoTcpSocketConnection::BindMessageDelegate(Packet::PayloadCase PC, FMessageDelegateBase* MD)
{
   MessageDelegates.Add(PC, MD);
}
```

=== 处理玩家进入消息

`PlayerManager` 定义了一个 `BlueprintImplementable` 蓝图可实现事件，方便后续逻辑在蓝图中完成：

```cpp
UFUNCTION(BlueprintImplementableEvent)
void OnPlayerEnter(int64 Cid, FVector3f Location);
```

下面是回调函数：

```cpp
void APlayerManager::OnMessageReceived(Packet* P)
{
   switch (P->payload_case())
   {
   case Packet::kResult:
      {
         types::Vector Location1 = P->result().enter_scene().location();
         EnterSceneCallback.Execute(FVector3f(Location1.x(), Location1.y(), Location1.z()));
         break;
      }
   case Packet::kBroadcastAction:
      {
         switch (P->broadcast_action().action_case())
         {
         case broadcast::player::Action::kPlayerEnter:
            {
               // 玩家进入范围
               types::Vector Location2 = P->broadcast_action().player_enter().location();
               int64 Cid = P->broadcast_action().player_enter().cid();
               OnPlayerEnter(Cid, FVector3f(Location2.x(), Location2.y(), Location2.z()));
               break;
            }
         case broadcast::player::Action::kPlayerLeave:
            {
               // 玩家离开范围
               int64 Cid = P->broadcast_action().player_leave().cid();
               OnPlayerLeave(Cid);
               break;
            }
         default:
            break;
         }
      }
   default:
      break;
   }
}
```

蓝图自定义事件实现：

#figure(image("/public/assets/img/2022/20221122-mmo-server-from-scratch(8)-scene-server-movement-sync-2-enter-scene-client-1.png"), caption: "image.png")

== 下一步

接下来将实现重头戏——玩家的移动同步，多人游戏的 `多人` 终于能够初具雏形了。


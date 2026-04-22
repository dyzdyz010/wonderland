#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "UE5 客户端对时实现 & 非玩家角色移动问题解决",
  desc: [对时 联动：从零开始的MMORPG游戏服务器(5) - Scene Server(3) - 对时 -],
  date: "2022-10-25",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.ue5,
  ),
)

== 对时

联动：#link("/article/mmo-server-from-scratch/2022/20221024-mmo-server-from-scratch(5)-scene-server-timesync")[从零开始的MMORPG游戏服务器(5) - Scene Server(3) - 对时 - 掘金 (juejin.cn)]

服务器端的对时逻辑在上面的文章中已经写好，本节说明客户端的实现方式。

客户端与服务器的 `Socket` 通信使用虚幻商城中免费的 `TcpSocketConnection`，通过子类化实现发送自定义 `Proto` 数据的目的。子类化后的类名为 `AMP5DemoTcpSocketConnection`，需要定义函数 `SendTimeSync`，用来向服务器发送 `TimeSync` 数据包。

对于本系列来说，`Proto`协议被定义为顶层全部为 `Packet` 类型的消息，通过 `oneof` 关键字区分载荷内容，`TimeSync` 就是其中一种。目前 `TimeSync` 消息内没有任何内容，以后想到了再完善。

协议包装与发送代码：

```cpp
void AMP5DemoTcpSocketConnection::SendTimeSync(int64 Timestamp)
{
   TimeSync *TS = new TimeSync();
   Packet *P = new Packet();
   P->set_id(GetPacketId());
   P->set_timestamp(Timestamp);
   P->set_allocated_time_sync(TS);
   SendProtoData(P);
}

bool AMP5DemoTcpSocketConnection::SendProtoData(Packet *P)
{
   size_t PacketSize = P->ByteSizeLong();
   TArray<uint8> DataArray1;
   DataArray1.SetNum(PacketSize);
   P->SerializeToArray(DataArray1.GetData(), PacketSize);
   
   // 数据包序列化过程
   std::string str = P->SerializeAsString();
   FString FData(str.c_str());
   TArray<uint8> DataArray;
   DataArray.SetNum(FData.Len());
   memcpy(DataArray.GetData(), TCHAR_TO_ANSI(*FData), FData.Len());
   
   SendData(connectionIdGameServer, DataArray1);
   
   return SendResult;
}
```

其中数据包的序列化过程，从 `C++` 原生类型向 `UE` 类型转化，搜索方法花了不少功夫。

这个类还需要存放一个回调列表，以及一个注册回调函数，区分不同类型的消息收到后应该由谁负责处理：

```cpp
TMap<Packet::PayloadCase, FMessageDelegateBase*> MessageDelegates;

void BindMessageDelegate(Packet::PayloadCase PC, FMessageDelegateBase *MD);
```

此处回调的类型为 `FMessageDelegateBase`，是一个抽象类，所有要处理接收到的信息的类都需要继承这个类实现多态：

```cpp
class MP5DEMO_API FMessageDelegateBase
{
public:
   FMessageDelegateBase();
   virtual ~FMessageDelegateBase() = 0;

   virtual void OnMessageReceived(Packet *P) = 0;
};
```

当 `AMP5DemoTcpSocketConnection` 类收到消息后，会根据回调列表中对应消息类型的对象，调用 `OnMessageReceived` 方法。

之后再创建一个 `Actor` 的子类 `ANetDelayManagerActor`，目前暂时用来专门与服务器对时。

实现一个 `UFUNCTION` 方法用来给蓝图类调用，并实现上面 `FMessageDelegateBase` 类的 `OnMessageReceived` 方法：

```cpp
UFUNCTION(BlueprintCallable)
void StartTimeSync(FTimeSyncCompleteCallback Callback);
```

```cpp
void ANetDelayManagerActor::StartTimeSync(FTimeSyncCompleteCallback Callback)
{
   this->TimeSyncCompleteCallback = Callback;
   OldTimestamp = TcpConnection->GetTimestamp();
   this->TcpConnection->SendTimeSync(OldTimestamp);
}

void ANetDelayManagerActor::OnMessageReceived(Packet* P)
{
   const int64 NewTimestamp = TcpConnection->GetTimestamp();

   const int32 TempDelay = (NewTimestamp - OldTimestamp) / 2;

   if (Delay != 0)
   {
      Delay = (TempDelay + Delay) / 2;
   }
   else
   {
      Delay = TempDelay;
   }

   UE_LOG(LogTemp, Warning, TEXT("New delay: %dms"), Delay);
   TcpConnection->SendTimeSync(TcpConnection->GetTimestamp());
}
```

代码实现的部分基本完成，下面在引擎里测试一下：

#figure(image("/public/assets/img/2022/20221025-ue5-timesync-and-npc-movement-fix-1.png"), caption: "微信截图_20221025194819.png")

== 非玩家角色移动问题

多人测试的时候需要另一个不被 `PlayerController` 控制的角色，但是我使用 `AIController` 的 `AIMoveto` 方法让这个角色向玩家控制角色移动，但是怎么也不动。一开始我以为 `AIController` 的生效是需要有什么手动设置或者初始化才会生效。但是经过一番查找资料后，发现如果一个 `Character` 不是玩家控制，那么它就默认被 `AIController` 控制，但是要想让其正常工作还需要一个东西—— `NavMesh`，地图中必须有这个东西角色才能在 `AIController` 的控制下移动。于是我在场景中添加了一个 `NavMeshBoundVolumn`，这个Volumn会在范围内把场景中可以站立移动的地方标出来，就像这样：

#figure(image("/public/assets/img/2022/20221025-ue5-timesync-and-npc-movement-fix-2.png"), caption: "image.png")

加入这个之后，非玩家控制的角色就能动起来了。


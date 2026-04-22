#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(6) - Scene Server(4) - 移动同步(0)",
  desc: [本节开始研究客户端与服务端角色移动同步问题。 功能解析 多人游戏之所以是多人游戏，就是因为每个玩家的动],
  date: "2022-10-26",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.rust,
  ),
)

本节开始研究客户端与服务端角色移动同步问题。

== 功能解析

多人游戏之所以是多人游戏，就是因为每个玩家的动作都可以被别的玩家看到，营造出一种大家在同一个世界的氛围。其中玩家移动的同步是最基础最重要的，它代表了玩家之间的远近关系，同时也划定了玩家影响世界的范围。

前期查阅了各种资料，没有找到能说很清楚的实现方式，全都是理论性的，本人水平有限无法落地。但是前几天看到了 #link("https://juejin.cn/post/7041560950897377293")[2 天做了个多人实时对战，200ms 延迟竟然也能丝滑流畅？ - 掘金 (juejin.cn)] 这篇文章，文章里详细说明了在位置同步中可能会出现的问题，比如本端和其他玩家端的移动卡顿不流畅；同时针对这些问题提出了一个我觉得不错的解决方案，那就是 `指令队列`。

=== 指令队列

文中提到了一个和解公式：

*预测状态 = 权威状态 + 预测输入*

其中 `权威状态` 可以认为就是服务器的状态，因为在多人游戏中服务器的数据才是权威的。 `预测状态` 是客户端表现的状态，因为客户端的状态送往服务器并得到确认需要时间，因此客户端为了让玩家角色不卡顿，先行表现，而不是等待服务器回应后再进行下一个动作，这样会极大影响玩家体验。 `预测输入` 即是客户端角色移动的状态变化。

可以看出，客户端只需不断将移动状态变化的事件存入一个队列结构，并在前端进行即时表现，收到服务器对某次状态变化进行确认后即将该事件从队列删除。整体上相当于一个 `生产者——消费者` 结构。

#figure(image("/public/assets/img/2022/20221026-mmo-server-from-scratch(6)-scene-server-movement-sync-0-1.png"))

正常情况下这个方法可以保证玩家本端显示的效果非常平滑。但是当延迟较高的时候，这个指令队列有可能被其他玩家对当前玩家的一些动作所打断，比如战斗中的定身，这是就出现了本端预测与服务器权威状态的冲突。这时为了保证本端与服务器的权威数据一致，只能抛弃队列中的预测状态变化事件，结果就是玩家被拉回之前与服务器状态一致的位置。虽然这样看起来体验不是很好，但是这也正是延迟的代价。

=== 服务器坐标计算

为了减少网络传输量，我计划目前只发送移动状态发生变化的事件，而不是固定时间间隔直接发送位移。比如加速度变化和速度变化。我打算在服务器实现变加速运动，但是目前为了简化就只考虑匀速运动。

当玩家运动状态变化时，就会发送数据包给服务器，服务器的 `AOI` 模块接受运动状态数据并存储，并且拥有一个定时任务，用来定时更新服务器上玩家角色的位置数据。

计算原理是与单个玩家关联的 `AoiItem` 进程在存储运动状态数据的同时，也会存储客户端和服务器的时间戳，目前客户端时间戳没有使用，打算在未来用于验证。当定时任务触发时，就可以根据现在和之前存储的服务器时间戳得到一个时间段，有了时间和速度，就可以计算出当前时刻玩家角色的坐标。计算完成后再将当前时间戳覆盖到存储的时间戳上，预备下一次定时触发。

== 简要实现

=== 客户端移动提交&指令队列

客户端定义一个新的 *Component*，实现一个用于发送移动状态的方法，以及一个队列结构：

```arduino
UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )
class MP5DEMO_API UNetEntityActionActorComponent : public UActorComponent, public FMessageDelegateBase
{
   GENERATED_BODY()

public:    
   // Sets default values for this component's properties
   UNetEntityActionActorComponent();

   // 角色移动组件引用
   UPROPERTY(EditAnywhere, BlueprintReadWrite)
   UCharacterMovementComponent *MoveComp;

   // TCP 消息模块引用
   UPROPERTY(EditAnywhere, BlueprintReadWrite)
   AMP5DemoTcpSocketConnection *TcpConnection;

   // 发送移动消息
   UFUNCTION(BlueprintCallable)
   void SendMovement(FVector3f Location, FVector3f Velocity, FVector3f Acceleration);

   // 获取指令队列长度
   UFUNCTION(BlueprintCallable)
   int32 MoveQueueLength();

   // 服务器返回响应处理回调
   virtual void OnMessageReceived(Packet *P) override;

protected:
   // Called when the game starts
   virtual void BeginPlay() override;

   // 指令队列以及手动计数
   TQueue<Packet*> MovementQueue;
   int32 QueueCounter = 0;

public:    
   // Called every frame
   virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
};
```

可以看到，这个类同时还继承了 `FMessageDelegateBase` 类，用于向 `AMP5DemoTcpSocketConnection` 注册消息处理函数。下面的指令队列使用了利用额外变量进行技术的方法，因为 UE 的 FIFO 结构 `TQueue` 内部实现是链表，没有提供默认的长度方法，因此我就用了一个 `int` 变量，当添加元素时就为其 +1，当删除元素时就为其 -1，从而实现手动的长度记录。

指令队列内存放的元素类型为 `Proto` 类型，方便在回调时获取消息响应 ID，以及如果预测冲突的话恢复之前的运动状态。

=== 服务器移动计算

服务器端为了实现高效计算，数学运算的部分同样放到了 `NIF` 里，目前与 `coordinate_system` 放在一起。代码：

```rust
pub fn calculate_coordinate(
    old_timestamp: i64,
    new_timestamp: i64,
    location: Vector,
    velocity: Vector,
) -> Vector {
    let mut result: Vector = location.clone();

    if velocity == (Vector{x: 0.0, y: 0.0, z: 0.0}) {
        result = location;
    } else {
        // 获取时间段并换算单位为秒
        let time = (new_timestamp - old_timestamp) as f64 / 1000.0;
        result.x = location.x + velocity.x * time;
        result.y = location.y + velocity.y * time;
        result.z = location.z + velocity.z * time;
    }

    return result;
}
```

在 `AoiItem` 进程内创建定时任务，按固定时间间隔进行计算：

```elixir
# 创建定时器
defp make_coord_timer() do
  Process.send_after(self(), :update_coord_tick, @coord_tick_interval)
end

# 定时任务消息处理
@impl true
def handle_info(
      :update_coord_tick,
      %{system_ref: system, item_ref: item, movement: movement} = state
    ) do

  # 获取新位置
  new_location = if movement.velocity != {0.0, 0.0, 0.0} do
    new_location = CoordinateSystem.calculate_coordinate(movement.server_timestamp, :os.system_time(:millisecond), movement.location, movement.velocity)
    CoordinateSystem.update_item_from_system(system, item, new_location)
    new_location
  else
    movement.location
  end

  # 更新新位置至状态
  {:noreply, %{state | coord_timer: make_coord_timer(), movement: %{movement | location: new_location}}}
end
```

== 下一步

下一步将聚焦于客户端在场景中生成其他玩家，向多人联机再迈出一步。

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(7) - Scene Server(5) - 移动同步(1) - 玩家进入场景 - 服务器部分",
  desc: [移动同步需要同步的东西很多，今天先研究玩家进入场景的时候如何同步给其他的玩家。 功能解析 当一个玩家进],
  date: "2022-10-28",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

移动同步需要同步的东西很多，今天先研究玩家进入场景的时候如何同步给其他的玩家。

== 功能解析

当一个玩家进入场景的时候，需要被周围的玩家看到，同时当前玩家也需要看到周围的玩家。这就需要每个玩家发送和接收 `玩家进入` 的消息，带上玩家的 `ID` 和 `位置`。

除了发送接收消息之外，还需要决定何时发送和接收这些消息。开始的时候我的想法是，在用户发送 `EnterScene` 消息给服务器的时候，服务器立刻就对周围玩家进行一次检索，之后将玩家列表随 `应答` 返回客户端。但是后来又仔细想了想，这样做极大拖慢了玩家的 `PlayerCharacter` 进程和对应 `AoiItem` 进程的初始化过程，可能会造成预期之外的后果导致初始化失败；况且玩家刚进入场景的时候稍微晚一点看见周围的人并没有什么大不了，对游戏体验影响极小。

随后我又想出了另一种办法，每个进程只 *主动* 向其他玩家进程发消息和 *被动* 从其他玩家进程收消息，避免主动从其他玩家进程拉去信息，由于并发数众多且均通过收发消息通信，拉取信息可能会导致自身和对面都发了消息等待回应的局面，从而造成死锁。

上篇文章 #link("/article/mmo-server-from-scratch/2022/20221026-mmo-server-from-scratch(6)-scene-server-movement-sync-0")[从零开始的MMORPG游戏服务器(6) - Scene Server(4) - 移动同步(0) - 掘金 (juejin.cn)] 中我提到，`aoi_item` 进程中设计了一个定时任务，用于定期根据自身坐标向 `coordinate_system` 模块查询周围一定半径内其他玩家的集合。我发现可以在这个过程上做文章。我可以借助进程存储的周围玩家列表，在定时任务出发的时候获取了新的玩家列表之后，将其与旧的列表做差，可以得到两个列表：`进入场景` 列表和 `离开场景` 列表。当前默认所有人的 `AOI` 范围都是一致的话，有了这两个列表就可以知道自己在其他玩家那里的状态，因为当自己能看到另一个人时，另一个人也能看到自己。通过这种方式可以将 `收集其他玩家信息` 转变为 `向其他玩家发送自身信息`。

所以，当一个新玩家进入地图的时候，只需要通知服务器创建相关的进程即可，广播状态的任务就交给定时任务，如果时间间隔设置得比较小的话，对客户端的体验影响几乎可以忽略不计。

== 简要实现

=== SceneServer.AoiItem

之前有提到过，我当时还不太确定让 `aoi_item` 进程持有网关进程的 `PID` 是不是一个好主意，但是现在为了方便，我选择了存储：

```elixir
# aoi_item.ex

# 进程状态初始化
@impl true
def init({cid, client_timestamp, location, connection_pid, player_pid, system}) do
  {:ok,
    %{
      cid: cid,
      player_pid: player_pid,
      connection_pid: connection_pid,
      system_ref: system,
      item_ref: nil,
      movement: %{
        client_timestamp: client_timestamp,
        server_timestamp: :os.system_time(:millisecond),
        location: location,
        velocity: {0.0, 0.0, 0.0},
        acceleration: {0.0, 0.0, 0.0}
      },
      subscribees: [],
      interest_radius: 500,
      aoi_timer: nil,
      coord_timer: nil
    }, {:continue, {:load, location}}}
end
```

其中，`subscribees` 代表被订阅者，即玩家身边其他玩家的列表；`connection_pid` 即是玩家网关进程 `ID`。

定时任务我采用了 `Process.send_after/3` 来创建定时器。在定时任务中，我需要获取身边玩家列表以及它与就列表的变化：

```elixir
# 定时任务
@impl true
def handle_info(
      :get_aoi_tick,
      %{
        cid: cid,
        movement: %{location: location},
        system_ref: system,
        item_ref: item,
        subscribees: subscribees
      } = state
    ) do
  aoi_pids = refresh_aoi_players(system, item, cid, location, subscribees)

  {:noreply, %{state | aoi_timer: make_aoi_timer(), subscribees: aoi_pids}}
  # {:noreply, state}
end

@spec refresh_aoi_players(
        CoordinateSystem.Types.coordinate_system(),
        CoordinateSystem.Types.item(),
        integer(),
        vector(),
        [pid()]
      ) :: no_return()
defp refresh_aoi_players(system, item, cid, location, subscribees) do
  # 获取身边半径10000范围内的玩家PID列表
  aoi_pids = get_aoi_players(system, item, 10000.0)
  leave_pids = subscribees -- aoi_pids
  enter_pids = aoi_pids -- subscribees

  # 广播状态变化
  broadcast_action_player_leave(cid, leave_pids)
  broadcast_action_player_enter(cid, location, enter_pids)

  aoi_pids
end
```

广播方法由于后期玩家人数多起来后，需要广播的目标数也会上升，因此为了让广播消息能够并行地向所有人送出，目前为了方便采用了以下方法（以玩家进入场景为例），后期可能改用 `Poolboy`：

```elixir
# 广播函数
@spec broadcast_action_player_enter(integer(), vector(), [pid()]) :: any()
defp broadcast_action_player_enter(cid, location, pids) do
  pids
  |> Enum.map(&Task.async(fn -> GenServer.cast(&1, {:player_enter, cid, location}) end))
  |> Enum.map(&Task.await(&1))
end

# 对应接收函数
@impl true
def handle_cast({:player_enter, cid, location}, %{connection_pid: connection_pid} = state) do
  # 向网关进程发送消息
  GenServer.cast(connection_pid, {:player_enter, cid, location})

  {:noreply, state}
end
```

=== GateServer.TcpConnection

网关进程在收到玩家进程消息后，需要将消息进行包装发给客户端。废话不多说，上代码：

```elixir
# 网关进程接收玩家进程消息
@impl true
def handle_cast({:player_enter, cid, location}, state) do
  GateServer.Message.send_player_enter(cid, location, self())

  {:noreply, state}
end

# 发送玩家进入消息至客户端
@spec send_player_enter(integer(), SceneServer.Aoi.AoiItem.vector(), pid()) :: no_return()
def send_player_enter(cid, {x, y, z} = _location, connection) do
  action = %Broadcast.Player.Action{action: {:player_enter, %Broadcast.Player.PlayerEnter{cid: cid, location: %Types.Vector{x: x, y: y, z: z}}}}
  payload = {:broadcast_action, action}

  GenServer.cast(connection, {:send_data, payload})
end
```

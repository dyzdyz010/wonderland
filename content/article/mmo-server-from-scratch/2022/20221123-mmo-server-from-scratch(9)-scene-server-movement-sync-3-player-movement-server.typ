#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(9) - Scene Server(7) - 移动同步(3) - 玩家移动 - 服务器部分",
  desc: [今天实现重头戏——移动同步。当玩家发生位移时，需要通知服务器，服务器存储了所有客户端的移动状态。服务器定时],
  date: "2022-11-23",
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

今天实现重头戏——*移动同步*。当玩家发生位移时，需要通知服务器，服务器存储了所有客户端的移动状态。服务器定时讲玩家的位置变化同步给 `AOI` 范围内的其他玩家。

== 功能解析

玩家移动情况上传服务器后的基本流程如下：

1. 网关收到 `movement` 消息，将其分发至对应的 `PlayerCharacter`；
2. `PlayerCharacter` 进程收到消息后，立刻通知对应的 `AoiItem` 进程更新移动参数并返回，包括 `位置`、`速度`等参数；
3. `AoiItem` 进程收到消息后，更新自身存储的移动信息；
4. `AoiItem`  的 `坐标更新` 定时任务根据当前存储的移动信息计算玩家角色新的坐标并存入 `进程状态` 和 `AOI` 坐标系统数据结构，并将更新后的坐标信息广播给其他玩家；
5. 网关进程收到 `PlayerCharacter` 进程返回值后将其发回客户端。

```mermaid
sequenceDiagram

participant C as Client
participant G as GateServer
participant P as PlayerCharacter
participant A as AoiItem

C ->> G: Movement消息
activate G
G ->> P: 传输运动信息
activate P
P ->> A: 更新运动信息
P -->> G: 返回更新结果
deactivate P
G ->> C: Movement消息回复
deactivate G

A ->> A: Movement Tick
```

可以看到，运动状态的上报和服务器计算是解耦的，两者的数据更新互不影响。这样可以使移动数据的计算量相对能少一点，避免运动状态密集改变时大量消耗服务器资源。

同时，网关服务器接收 `Movement` 消息和发送回复消息对于客户端来说是异步的，即客户端发送后无需等待服务器响应，能够为客户端稍微节省资源。

== 简要实现

=== GateServer.Message

该模块负责消息的分发和处理。当收到客户端的 `Movement` 消息是，是该模块负责将消息转发给 `SceneServer.PlayerCharacter` 进程并根据返回值向客户端发送响应消息。

```elixir
def dispatch(

      %Packet{

        id: id,

        timestamp: timestamp,

        payload: {:entity_action, %Entity.EntityAction{action: {:movement, movement}}}

      },

      %{scene_ref: spid} = state,

      connection

    ) do

  # 拆解消息包结构
  %Types.Movement{
    location: %Types.Vector{x: lx, y: ly, z: lz},
    velocity: %Types.Vector{x: vx, y: vy, z: vz},
    acceleration: %Types.Vector{x: ax, y: ay, z: az}
  } = movement

  # 把消息内容发给 SceneServer.PlayerCharacter
  {:ok, _} =
    GenServer.call(spid, {:movement, timestamp, {lx, ly, lz}, {vx, vy, vz}, {ax, ay, az}})

  # 包装响应消息
  payload = {:result, %Reply.Result{packet_id: id, status_code: :ok, payload: nil}}

  # 向客户端发送响应消息
  GenServer.cast(connection, {:send_data, payload})

  {:ok, state}

end
```

=== SceneServer.PlayerCharacter

在目前，`PlayerCharacter` 进程扮演的角色只是将消息转发给 `AoiItem` 进程进行处理，除此之外没有其他逻辑。这个情况在之后将会有大变化。

```elixir
@impl true
def handle_call(
      {:movement, client_timestamp, location, velocity, acceleration},
      _from,
      %{aoi_ref: aoi} = state
    ) do
  GenServer.cast(aoi, {:movement, client_timestamp, location, velocity, acceleration})
  
  {:reply, {:ok, ""}, state}
end
```

=== SceneServer.AoiItem

该进程目前是处理移动逻辑的主要进程，当然还包括 `AOI` 的管理和广播职能。正如前面所说，这部分的处理逻辑将在不远的将来发生变化，目前权当测试功能。

首先是接收 `Movement` 消息函数：

```elixir
@impl true
def handle_cast(
      {:movement, timestamp, location, velocity, acceleration},
      state
    ) do
  new_state = update_movement(timestamp, location, velocity, acceleration, state)

  {:noreply, new_state}

end

@spec update_movement(integer(), vector(), vector(), vector(), map()) :: map()
defp update_movement(
        timestamp,
        location,
        velocity,
        acceleration,
        %{system_ref: system, item_ref: item} = state
      ) do
  # 更新坐标管理系统中玩家的位置
  {:ok, _} = CoordinateSystem.update_item_from_system(system, item, location)

  # 返回更新的移动信息供进程状态保存
  %{
    state
    | movement: %{
        client_timestamp: timestamp,
        server_timestamp: :os.system_time(:millisecond),
        location: location,
        velocity: velocity,
        acceleration: acceleration
      }

  }

end
```

然后是位置更新定时任务：

```elixir
@impl true
def handle_info(
      :update_coord_tick,
      %{cid: cid, system_ref: system, item_ref: item, movement: movement, subscribees: subscribees} =
        state
    ) do
  # 计算玩家角色新坐标
  new_location =
    update_location(
      system,
      item,
      movement.server_timestamp,
      movement.location,
      movement.velocity
    )

  # 如果位置发生变化则进行广播
  if new_location != movement.location and subscribees != [] do
    broadcast_action_player_move(cid, new_location, subscribees)
  end

  {:noreply,
    %{state | coord_timer: make_coord_timer(), movement: %{movement | location: new_location, server_timestamp: :os.system_time(:millisecond)}}}

end
```

该定时任务会根据当前存储的运动信息计算新的坐标，并对周围玩家进行广播。

之后是获取周围玩家的定时任务：

```elixir
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

  # 获取周围玩家AoiItem进程pid
  aoi_pids = refresh_aoi_players(system, item, cid, location, subscribees)

  {:noreply, %{state | aoi_timer: make_aoi_timer(), subscribees: aoi_pids}}
end
```

广播函数：

```elixir
@spec broadcast_action_player_move(integer(), vector(), [pid()]) :: any()
defp broadcast_action_player_move(cid, location, pids) do
  pids
  |> Enum.map(&Task.async(fn -> GenServer.cast(&1, {:player_move, cid, location}) end))
  |> Enum.map(&Task.await(&1))
end
```

接收广播消息函数：

```elixir
@impl true
def handle_cast({:player_move, cid, location}, %{connection_pid: connection_pid} = state) do
  # 发送广播消息至网关服务器
  GenServer.cast(connection_pid, {:player_move, cid, location})
  
  {:noreply, state}
end
```

== 下一步

经过一番思考，我觉得现在的移动同步逻辑的位置不够合理，同时为了给其他逻辑预留空间，打算先重整一下 `PlayerCharacter` 和 `AoiItem` 进程的职责和功能。

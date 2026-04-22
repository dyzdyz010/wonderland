#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(5) - Scene Server(3) - 对时",
  desc: [今天实现了一个简单的功能 —— 对时。 对时 所谓对时，不是让客户端和服务器的时钟完全一致，而是通过二],
  date: "2022-10-24",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
  ),
)

今天实现了一个简单的功能 —— *对时*。

== 对时

所谓对时，不是让客户端和服务器的时钟完全一致，而是通过二来二回计算出客户端与服务器之间的延迟，方便双方对数据进行验证和预测。

服务器与客户端的对时消息发送流程如下：

```mermaid
sequenceDiagram

participant C as Client
participant S as Server
Note over C: client_timestamp1
C ->>+ S: TimeSync()
Note over S: server_timestamp1
S -->> C: TimeSync()
Note over C: client_timestamp2
Note over C: delay = (client_timestamp2 - client_timestamp1) / 2
C ->> S: TimeSync()
Note over S: server_timestamp2
Note over S: delay = (server_timestamp2 - server_timestamp1) / 2
```

1. 客户端发起对时请求，向服务器发送 *客户端第一个* `TimeSync` 包，存储自身当时时间戳
2. 服务器收到 *客户端第一个* `TimeSync` 包，存储自身当时时间戳，并立即向客户端发送 *服务器第一个* `TimeSync` 包
3. 客户端收到 *服务器第一个* `TimeSync` 包，获取自身当前时间戳，根据现在以及刚才的两个时间戳计算出 *网络延迟* 并存储 ，并立即向客户端发送 *客户端第二个* `TimeSync` 包
4. 服务器收到 *客户端第二个* `TimeSync` 包，获取自身当前时间戳，根据现在以及刚才的两个时间戳计算出 *网络延迟* 并存储，对时结束

此过程可以进行多次取平均值以提高准确性。

== 实现逻辑

此功能实现涉及 `gate_server` 以及 `scene_server` 两个服务器，因为需要网络延迟进行补偿的内容一般处于大地图场景内，因此 `对时` 过程目前设计在 `scene_server` 上完成。

服务器端对时的基本流程：

1. `gate_server` 收到数据包进行解析，判断是否为 `TimeSync`包，如果是的话获取 `PlayerCharacter` 进程ID，向其发送 `time_sync` 消息
2. `PlayerCharacter` 进程收到 `time_sync` 消息，获取当前时间戳，判断是否第一次收到 `time_sync` 消息，如果是的话将当前时间戳存入进程状态；如果不是的话取出进程状态中的上一次时间戳，计算网络延迟。根据情况不同向 `gate_server` 返回不同相应
3. `gate_server` 收到相应，根据相应判断是否应该向客户端发送 `TimeSync` 包

== 简要代码

首先是 `gate_server` 的消息解析和向客户端发送数据包部分：

```elixir
def dispatch(
      %Packet{id: id, payload: {:time_sync, _}},
      %{scene_ref: spid} = state,
      connection
    ) do
  {:ok, new_timestamp} = GenServer.call(spid, :time_sync)

  if new_timestamp != :end do
    packet = %Packet{id: id, timestamp: new_timestamp, payload: {:time_sync, %TimeSync{}}}
    GenServer.cast(connection, {:send_data, packet})
  end

  {:ok, state}
end
```

然后是 `scene_server` 中 `PlayerCharacter` 进程的对时逻辑部分：

```elixir
def handle_call(
      :time_sync,
      _from,
      %{old_timestamp: old_timestamp, net_delay: old_delay} = state
    ) do
  new_timestamp = :os.system_time(:millisecond)

  case old_timestamp do
    nil ->
      {true, %{state | old_timestamp: new_timestamp}}
      {:reply, {:ok, new_timestamp}, %{state | old_timestamp: new_timestamp}}

    _ ->
      temp_delay = div(new_timestamp - old_timestamp, 2)
      Logger.debug("CS延迟: #{temp_delay}")

      new_delay =
        if old_delay != 0 do
          div(temp_delay + old_delay, 2)
          # ((new_timestamp - old_timestamp) / 2 + old_delay) / 2
        else
          temp_delay
        end

      {false, %{state | old_timestamp: nil, net_delay: new_delay}}

      {:reply, {:ok, :end}, %{state | old_timestamp: nil, net_delay: new_delay}}
  end
end
```

到这里，游戏的 `对时` 功能就完成了。下一步聚焦于实现客户端显示其他玩家。

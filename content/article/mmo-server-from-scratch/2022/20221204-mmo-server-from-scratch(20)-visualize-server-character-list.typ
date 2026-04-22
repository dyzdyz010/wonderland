#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(20) - Visualize Server(3) - 获取玩家角色列表",
  desc: [本节我将为 SceneServer 建立接口，用来向 VisulizeServer 提供数据。 在 Sc],
  date: "2022-12-04",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

本节我将为 `SceneServer` 建立接口，用来向 `VisulizeServer` 提供数据。

在 `SceneServer` 中，各个玩家角色是以进程的形式存在的，所以没有一个天然的结构统一存放所有的角色数据。我的方案是再创建一个新的进程 `PlayerManager` ，用来存放所有的玩家角色进程，以及它们和各自 `cid` 的对应关系。每当一个角色进入场景的时候，网关服务器向 `PlayerManager` 发请求，由 `PlayerManager` 来创建角色进程，并将其存储到自身的状态里。同样地，当一个玩家断开连接时，角色进程在完全销毁前先通知 `PlayerManager` 把自己从角色进程列表中删除，然后自己再完成销毁。

所以思路就有了。`PlayerManager` 存放着所有玩家角色的索引，我们从这里获取完整列表，然后再分别向各个角色进程获取具体数据就行。我们只需要给 `PlayerManager` 增加一个接口：

```elixir
@impl true
def handle_call(:get_all_players, _from, %{players: players} = state) do
  {:reply, {:ok, players}, state}
end
```

非常简单。让 `VisualizeServer` 调用一下试试看。先运行几个客户端，让服务器能有数据，否则获取的就是空的。之后在我们之前创建的 `:data_update` 消息处理函数中调用接口：

```elixir
result =
      GenServer.call(
        {SceneServer.PlayerManager, :"scene1@127.0.0.1"},
        :get_all_players
      )
Logger.debug("玩家获取结果：#{inspect(result, pretty: true)}")
```

这里 `:"scene1@127.0.0.1"` 是场景服务器 `SceneServer` 的 *节点名称*。按照 `BEAM` 节点集群要求，一个节点要想访问另一个节点，首先得知道 *节点名称*，其次自己节点的 `cookie` 得和要连接的节点一致。

#figure(image("/public/assets/img/2022/20221204-mmo-server-from-scratch(20)-visualize-server-character-list-1.png"), caption: "Pasted image 20221204203535.png")

可以看到已经完美获取了玩家角色列表，结构是一个 `Map`，键为 `cid`，值为对应角色进程 `ID`，即 `pid`。

= 下一步

接下来我们按照已经获取到的进程列表，分别获取具体数据，并将数据打包发给前端用于展示。


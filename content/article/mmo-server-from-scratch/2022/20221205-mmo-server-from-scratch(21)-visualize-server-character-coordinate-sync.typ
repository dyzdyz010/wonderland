#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(21) - Visualize Server(4) - 获取玩家角色坐标并发至前端",
  desc: [上一节我们获取到了玩家角色的 cid 和进程列表，本节我们获取所有的坐标数据并发送给前端。 获取位置 我],
  date: "2022-12-05",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.rust,
    blog-tags.tooling,
    blog-tags.software,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

上一节我们获取到了玩家角色的 `cid` 和进程列表，本节我们获取所有的坐标数据并发送给前端。

= 获取位置

我们有了每个玩家角色进程的 `pid` ，那我们只需要向该进程发送请求获取位置即可。玩家角色进程提供一个接口：

```elixir
@impl true
def handle_call(:get_location, _from, %{character_data_ref: cd_ref} = state) do
  {:ok, location} = SceneServer.Native.SceneOps.get_character_location(cd_ref)

  {:reply, {:ok, location}, state}
end
```

这里获取坐标是从 `NIF` 空间中获取，因为我们在之前的文章里已经把玩家角色的所有数据全部放到了 `Rust` 代码中。

之后我们按顺序请求所有的玩家角色：

```elixir
# 获取玩家角色列表
{:ok, players_map} =
  GenServer.call(
    {SceneServer.PlayerManager, :"scene1@127.0.0.1"},
    :get_all_players
  )

# 获取坐标
characters =
  Enum.map(players_map, fn {cid, pid} ->
    {:ok, {x, y, _z}} = GenServer.call(pid, :get_location)
    %{
      cid: cid,
      location: %{x: x, y: y}
    }
  end)
```

这里的 `location` 本来应该是一个 `Tuple`：`{x, y, z}` 的形式，但是 `Phoenix` 无法将 `Tuple` 类型转换为 `Json` 对象，因此我们需要利用模式匹配将其转换成 `Map`，即 `%{x: x, y: y}`。目前用不到 `z` 坐标，因此先不向前端传递 `z` 的值。

这样一来，我们要传到前端的数据结构就是一个关于 `Map` 的列表：

#figure(image("/public/assets/img/2022/20221205-mmo-server-from-scratch(21)-visualize-server-character-coordinate-sync-1.png"), caption: "Pasted image 20221205213427.png")

之后将其传给前端即可。

= 前端显示

在前端的事件监听函数中，我们将数据取出来就可以准备让其显示在页面中了。

在这之前，我们需要确定一下更新策略。一开始的时候我想的是每刷新一次数据就把之前页面中的精灵清空然后重新创建，但是搜了一下文档好像并不原生支持这种操作，况且这样的话消耗也比较大。于是我又想出了 *第二种策略：* 存一个全局字典，用 `cid` 进行索引，值为场景中的精灵对象，如果不存在就新创建，如果存在就修改其位置。这样一来消耗也比第一种方法低了一些。

```javascript
var players = {}

window.addEventListener(`phx:data`, (e) => {
    const clist = e.detail.characters

    clist.forEach(character => {
        if (players[character.cid] == null) {
            let sprite = PIXI.Sprite.from('/images/arrow_64.png')
            scene.addChild(sprite)
            sprite.position.set(character.location.x, character.location.y)
            sprite.scale.set(0.5)
            players[character.cid] = sprite
        } else {
           players[character.cid].position.set(character.location.x, character.location.y)
        }
    })
})
```

效果：

#figure(image("/public/assets/img/2022/20221205-mmo-server-from-scratch(21)-visualize-server-character-coordinate-sync-2.png"), caption: "Pasted image 20221205213956.png")

可以看到精灵的坐标并不是正确的，这是由于 `PIXI.js` 和 `UE` 的坐标系不一致，以及缩放比例不一致导致的。

= 下一步

下一节将重点解决坐标显示不正确的问题。


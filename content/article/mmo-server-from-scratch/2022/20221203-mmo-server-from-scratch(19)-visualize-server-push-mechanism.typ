#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(19) - Visualize Server(2) - 服务端数据推送机制",
  desc: [本节我们探讨关于数据如何定时从服务端推送到客户端的问题。 对于 Phoenix Liveview 来说，],
  date: "2022-12-03",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.software,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

本节我们探讨关于数据如何定时从服务端推送到客户端的问题。

对于 `Phoenix Liveview` 来说，由于前后端已经被框架机制由 `WebSocket` 连接起来了，所以前后端的来回通信一下就变得非常方便，只要通过 `WebSocket` 来发送接收消息就好，而不需要再通过 `AJAX` 之类的请求来获取信息。

= 服务端

`Phoenix Liveview` 的服务端可以向前端主动发送事件，也就是可以发送自定义数据。

参考链接：#link("https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_event/3")[Phoenix.LiveView — Phoenix LiveView v0.18.3 (hexdocs.pm)]

有个函数叫做 `push_event/3`，可以通过 `socket` 向前端发送一个事件，并与事件关联发送一段 `json` 数据。

既然服务端可以主动向前端推送数据，那我们只需要让服务端定时获取最新数据，再通过 `push_event` 函数将数据推送给前端，由前端解析后展示即可。

我们还需要将这个发送事件的动作变成定时任务，和 `SceneServer` 中的定时任务创建方式完全一致：

```elixir
@impl true
def mount(_params, _session, socket) do
  # 创建定时任务
  if connected?(socket), do: Process.send_after(self(), :data_update, 1000)

  {:ok, assign(socket, :data, [])}
end
```

意即1秒后向自己的进程发送一条 `:data_update` 消息。可以看到我判断了一下 `socket`是否已经连接，原因是 `mount/3` 函数在同一个页面的初始化过程中会#link("https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:mount/3")[调用两次]，我们不希望同时存在两个完全一样的定时任务。

我们的数据处理与发送就在这个 `:data_update` 消息处理函数中进行：

```elixir
@impl true
def handle_info(:data_update, socket) do
  Process.send_after(self(), :data_update, 1000)

  {:noreply, push_event(socket, "data", %{
    characters: [%{
      cid: 1101,
      location: %{x: 5.0, y: 10.0}
    }]
  })}
end
```

这里我就随便发一个样例数据试试看。可以看到，我在处理函数 `handle_info/2` 中又一次调用了定时任务创建函数 `Process.send_after/3`，原因是这个函数创建的定时任务是一次性的，我们要向让他不断执行，那就在每次定时任务出发的时候再创建一个相同的定时任务。

这样一来，服务端就可以定时向前端发送数据了。

= 前端

我们的这套消息传送机制是一个 `发布——订阅` 模式，服务端发布事件，客户端订阅事件，因此我们现在需要在客户端订阅 `data` 事件。

参考链接：#link("https://hexdocs.pm/phoenix_live_view/js-interop.html#event-listeners")[JavaScript interoperability — Phoenix LiveView v0.18.3 (hexdocs.pm)]

我们在前端的 `js` 文件中按照文档中的写法订阅 `data` 事件，这样就可以获取服务端推送过来的数据了：

```javascript
window.addEventListener(`phx:data`, (e) => {
    console.log("自定义事件：", e)
})
```

看下前端的输出：

#figure(image("/public/assets/img/2022/20221203-mmo-server-from-scratch(19)-visualize-server-push-mechanism-1.png"), caption: "Pasted image 20221203215416.png")

可以看到，我们的数据在 `detail` 字段下。

到这里，我们前后端的数据交换流程就打通了🥳

= 下一步

接下来我将为 `SceneServer` 添加接口，用于让 `VisualizeServer` 获取玩家角色移动数据。


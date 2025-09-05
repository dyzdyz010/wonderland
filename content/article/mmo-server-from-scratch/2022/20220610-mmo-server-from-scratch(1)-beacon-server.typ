#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "MMO Server From Scratch(1) - Beacon Server",
  desc: [MMO Server From Scratch(1) - Beacon Server],
  date: "2022-06-10",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.server,
    blog-tags.game,
    blog-tags.elixir,
  ),
)

今天来实现服务器的第一个部件 - *beacon_server*。

= 功能解析

为了建立Elixir集群，需要所有 Beam 节点在启动之时就已经知道一个固定的节点用来连接，之后 Beam 会自动完成节点之间的链接，即默认的`全连接`模式，所有节点两两之间均有连接。关于这一点我还没有深入思考过有没有必要进行调整，之后看情况再说🤪

因此，为了让服务器集群内的所有节点在启动时都能够连接一个固定节点从而组成集群，这个固定节点就是`beacon_server`。

`beacon_server`需要有什么功能呢？在经过一番简单思考后，至少需要具备以下几个功能：

1. 接受其他节点的连接
2. 接受其他节点的注册信息
3. 相应其他节点的需求，返回需求节点的信息

这里有两个重要概念：`资源(Resource)` 和 `需求(Requirement)`。`资源`指某个节点自身的内容类型，也就是在集群中所处的角色，比如网关服务器的资源就是网关(gate_server)；`需求`指某个节点需要的其他节点，比如网关节点需要*网关管理节点(gate_manager)*来注册自己，数据服务节点需要*数据联系节点(data_contact)*来把数据库同步到自身。

当一个节点向`beacon_server`节点注册时，我们希望它能够向`beacon_server`提供自己的节点名称、资源、需求等数据，方便`beacon_server`在收到别的节点注册时，能够把已经注册过的节点当做需求返回给别的节点。

= 数据结构

我用一个 `GenServer` 线程负责上面所说的所有工作，利用线程的 `state` 来保存来往节点信息。当前粗略想了想，姑且定义信息存储格式如下：

```elixir
%{
  nodes: %{
    "node1@host": :online,
    "node2@host": :offline
  },
  requirements: [
    %{
      module: Module.Interface,
      name: [:requirement_name],
      node: :"node@host"
    }
  ],
  resources: [
    %{
      module: Module.Interface,
      name: :resoutce_name,
      node: :"node@host"
    }
  ]
}
```

我用一个字典存储所有信息，分为 `nodes`、`requirements`以及`resources`三部分。

`nodes`存储所有已经连接的节点和他们的状态，`:online`表示在线正常连接，`:offline`表示节点断开连接；

`requirements`存储每个节点注册时提供的需求信息。使用列表存储，列表中每个项代表一个节点。项使用字典，存储模块(module)、名称(name)、节点(node)信息。其中`名称`字段，因为有些节点可能会有不只一个`需求`，因此使用列表存储。`模块`字段是为了留着以备后用，目前没什么用……`节点`字段用于获取的节点使用该字段对目标节点发送消息，必不可少。

`resources`存储每个节点注册时提供的资源信息，字段与`requirements`完全相同，有一个不同的地方是`名称`字段的数据类型不再是列表，而是原子，因为每个节点只可能属于唯一的一种资源，不可能属于两种以上，因此用一个单一的原子就可以代表了。

= 简要实现

== 建立项目

这是第一个实现，在实现之前，我们先建立一个`umbrella`项目，用来存放之后的所有代码：

```bash
mix new cluster --umbrella
```

然后创建本节的`beacon_server`项目：

```bash
cd apps/
mix new beacon_server --sup
```

`--sup`用来生成监督树。

有了项目之后，我们需要建立一个`GenServer`，用来充当其他节点用来通信的接口，我们就把他叫做`Beacon`好了。

== 功能函数

根据前面的设想，我们需要下面这么几个函数：

- register(credentials, state) - 用于把注册来的节点信息记录在 `state` 中，并将新的 `state` 返回。
- get_requirements(node, requirements, resources) - 用于向已注册的节点返回其需求。

下面贴上我粗略实现的代码，当然这不会是最终版本，未来还有优化的空间：

```elixir
@spec register({node(), module(), atom(), [atom()]}, map()) :: {:ok, map()}
defp register(
        {node, module, resource, requirement},
        state = %{nodes: connected_nodes, resources: resources, requirements: requirements}
      ) do
  Logger.debug("Register: #{node} | #{resource} | #{inspect(requirement)}")

  {:ok,
    %{
      state
      | nodes: add_node(node, connected_nodes),
        resources: add_resource(node, module, resource, resources),
        requirements:
          if requirement != [] do
            add_requirement(node, module, requirement, requirements)
          else
            requirements
          end
    }
  }
end

@spec get_requirements(node(), list(map()), list(map())) :: list(map())
defp get_requirements(node, requirements, resources) do
  req = find_requirements(node, requirements)
  offer = find_resources(req, resources)
  offer
end
```

上面代码中用到的其他私有函数我就不贴了，总之就是利用线程 `state` 中的数据返回新的数据。


除了这两个必要的函数，我还想添加两个能够监控节点通断的函数。这两个函数通过 `handle_info` 实现。首先需要在线程初始化的时候开启这项功能：

```elixir
:net_kernel.monitor_nodes(true)
```

之后实现两个 callback：

```elixir
# ========== Node monitoring ==========

@impl true
def handle_info({:nodeup, node}, state) do
  Logger.debug("Node connected: #{node}")

  {:noreply, state}
end

@impl true
def handle_info({:nodedown, node}, state = %{nodes: node_list}) do
  Logger.critical("Node disconnected: #{node}")

  {:noreply, %{state | nodes: %{node_list | node => :offline}}}
end
```

不在 `:nodeup` 回调中将节点状态修改为 `:online` 是因为节点在注册的时候，注册函数已经将节点的状态修改为 `:online` 了。

== 接口函数

有了功能之后，还需要提供对外接口，`GenServer` 已经提供了相关的回调函数供我们实现，在这里我使用 `handle_call/3`，因为注册流程需要是*同步*的，只有注册完成之后对应节点才能开始正常运行。

同样地，对外接口也是两个，分别是 `:register` 和 `:get_requirements`：

```elixir
@impl true
# Register node with resource and requirement.
def handle_call(
      {:register, credentials},
      _from,
      state
    ) do
  Logger.info("New register from #{inspect(credentials, pretty: true)}.")

  {:ok, new_state} = register(credentials, state)

  Logger.info("Register #{inspect(credentials, pretty: true)} complete.", ansi_color: :green)

  {:reply, :ok, new_state}
end

@impl true
# Reply to caller node with specified requirements
def handle_call(
      {:get_requirements, node},
      _from,
      state = %{nodes: _, resources: resources, requirements: requirements}
    ) do
  Logger.debug("Getting requirements for #{inspect(node)}")

  offer = get_requirements(node, requirements, resources)

  {:reply,
    case length(offer) do
      0 -> nil
      _ -> 
        Logger.info("Requirements retrieved: #{inspect(offer, pretty: true)}", ansi_color: :green)
        {:ok, offer}
    end, state}
end
```

至此，`Beacon` 功能模块就基本完整了，最后我们需要把它加入到监督树里使其运行起来。在 `application.ex` 中：

```elixir
def start(_type, _args) do
  children = [
    # Starts a worker by calling: BeaconServer.Worker.start_link(arg)
    {BeaconServer.Beacon, name: BeaconServer.Beacon}
  ]

  # See https://hexdocs.pm/elixir/Supervisor.html
  # for other strategies and supported options
  opts = [strategy: :one_for_one, name: BeaconServer.Supervisor]
  Supervisor.start_link(children, opts)
end
```

像这样把 `Beacon` 模块加入到监督者的子线程列表中，`beacon_server` 暂时就算完成了。

= 效果测试

运行一下试试：

```bash
iex --name beacon1@127.0.0.1 --cookie mmo -S mix
```

为了让其他节点连接，`name` 和 `cookie` 一定好设置好。

我写了点测试代码调用一下试试：

#figure(image("/public/assets/img/2022/20220611_beacon_server_output.png"), caption: "Beacon Server Output")

最后我们看一下 `Beacon` 模块的 `state` 长什么样：

#figure(image("/public/assets/img/2022/20220611_beacon_state.png"), caption: "Beacon State")

就先这样，后面我们会在此基础上继续实现别的服务器。
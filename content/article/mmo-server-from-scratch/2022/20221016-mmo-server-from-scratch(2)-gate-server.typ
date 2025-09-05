#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "MMO Server From Scratch(2) - Gate Server",
  desc: [MMO Server From Scratch(2) - Gate Server],
  date: "2022-10-16",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.server,
    blog-tags.game,
    blog-tags.elixir,
  ),
)

今天实现服务器的第二个部件 - **gate_server**

= 功能解析

根据[开篇架构设想](/posts/mmo-server-from-scratch/2022/20220608-mmo-server-from-scratch(0)-introduction.md)中的想法，`gate_server` 是用来接受用户连接的服务器。客户端通过 **TCP Socket** 的方式连接到 `gate_server` 上来， `gate_server` 负责把客户端发来的消息转发到指定的业务相关服务器上，并将服务器产生的消息发回客户端。

所以，根据上面的描述，`gate_server` 至少需要具备以下功能：

1. 连接`beacon_server`服务器，注册自身并获取自身需要的其他服务器资源
2. 监听TCP端口并接受连接
3. 接受客户端消息并转发至其他服务器
4. 向客户端发送消息

在 `Erlang/Elixir` 中，进程的使用是极其廉价的，这里说的进程不是系统进程，而是 `Beam` 虚拟机进程，属于用户进程。因此我打算为每个客户端传入的 `Socket` 连接分配一个 `GenServer` ，用于消息交换和状态保存。

对于消息协议，我选择了#link("https://github.com/protocolbuffers/protobuf")[Protobuf]，因此 `gate_server` 还需要具备消息的编解码能力。

= 简要实现

== 建立项目

首先建立本节的 `gate_server` 项目：

```bash
cd apps/
mix new gate_server --sup
```

== 模块划分

为了实现以上功能，需要划分几个模块：一个 `Interface` 模块负责集群相关操作，如注册、加入集群、获取其他服务器节点等；一个 `TcpAcceptor` 模块负责监听端口并接受TCP连接；一个 `TcpConnection` 模块负责和客户端进行通信。

按照这个设计，`gate_server`应用的监督树如下：

```text
                            application
                           /     |     \
                          /      |      \
                         /       |       \
           TcpAcceptorSup   InterfaceSup  TcpConnectionSup
                  |              |               |  
                  |              |               |  
                  |              |               |  
              Interface     TcpAcceptor   TcpConnection x N

```

其中：

- application - `gate_server`主程序
- TcpAcceptorSup - `TCP`监听进程监督者进程
- InterfaceSup - `Interface`模块监督者进程
- TcpConnectionSup - `TcpConnection`模块监督者进程
- Interface - 集群接口模块进程
- TcpAcceptor - `Tcp`监听模块进程
- TcpConnection - 用户连接进程

== Interface

关于监督者进程的创建我就不说了，查阅各种文档都可以找到方法。首先来实现一下 `Interface` 的功能。

`Interface`进程的初始化流程：

1. 建立`GenServer`
2. 连接给定的`beacon_server`节点
3. 连接成功后调用`beacon_server`的`register`接口，注册自身
4. 向`beacon_server`请求自身所需的其他节点

受前面实现的 `beacon_server` 限制，这个流程姑且就先这样，后续再继续优化。

我不在 `init` 函数中进行以上动作，而是将逻辑放置到 `timeout` 消息处理中，使得进程尽快完成初始化开始接收消息。代码如下：

```elixir
@impl true
def init(_init_arg) do
    {:ok, %{auth_server: [], server_state: :waiting_requirements}, 0}
end

@impl true
def handle_info(:timeout, state) do
    send(self(), :establish_links)
    {:noreply, state}
end

@impl true
def handle_info(:establish_links, state) do
    Logger.info("===Starting #{Application.get_application(__MODULE__)} node initialization===", ansi_color: :blue)

    join_beacon()
    register_beacon()
    new_state = get_requirements(state)

    Logger.info("===Server initialization complete, server ready===", ansi_color: :blue)
    {:noreply, %{new_state | server_state: :ready}}
end
```

`join_beacon/0`、`register_beacon/0`、`get_requirements/1` 三个函数我就不放了，基本需要的东西就是 `Node.connect/1` 和 `GenServer.call/3`。

运行效果：

#figure(image("/public/assets/img/2022/20221016_interface.png"), caption: "Interface 运行效果")

此时 `beacon_server` 的 `state` 数据：

#figure(image("/public/assets/img/2022/20221016_beacon_state.png"), caption: "beacon_server state 内容")

此时如果在 `iex` 中输入：

```elixir
Node.list
```

可以发现我们的 `gate_server` 已经和 `beacon_server` 建立连接了：

#figure(image("/public/assets/img/2022/20221016_node_list.png"), caption: "beacon_server state 内容")

== TcpAcceptor

`TcpAcceptor` 是用来接收 `TCP` 传入链接的进程，同样是一个 `GenServer`。这个进程的逻辑非常简单，直接看代码：

```elixir
defp listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: true, reuseaddr: true])

    Logger.debug("Accepting connections on port #{port}")
    loop_acceptor(socket)
end

defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
        DynamicSupervisor.start_child(
        GateServer.TcpConnectionSup,
        {GateServer.TcpConnection, client}
        )

    :ok = :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
end
```

`listen/1` 函数用来监听指定的端口，在成功之后开始接受传入 `TCP` 连接；`loop_acceptor/1` 函数用来循环接受 `TCP` 连接，一旦接受一个连接，则为其创建一个 `TcpConnection` 进程，并将该链接的 `socket` 控制权转交给新生成的 `TcpConnection` 进程。在 `Elixir` 中，尾递归可以被优化，不会无限制占用栈空间，因此在函数的最末尾进行递归调用实现循环接受 `TCP` 连接。

== TcpConnection

这是本节最核心的功能模块，负责与客户端的一切通信。

`TcpConnection` 同样是一个 `GenServer`，用于保存一些状态和传输 `TCP` 数据。其初始化函数如下：

```elixir
@impl true
def init(socket) do
    Logger.debug("New client connected.")
    {:ok, %{socket: socket, status: :waiting_auth}}
end
```

可以看到，我们把 `socket` 信息存入了进程的 `state` 中，方便后续调取。此处的 `status` 属性暂且抛开不管，用于后续用户的鉴权，本节不作讨论。

接下来是本进程的核心函数 - `TCP` 消息接收函数：

```elixir
@impl true
def handle_info({:tcp, _socket, data}, %{socket: socket} = state) do
    result = "You've typed: #{data}"
    send_data(senddata, socket)

    {:noreply, state}
end
```

此处为了方便测试，先写一个简单的 **echo** 功能。`GenServer` 还贴心地提供了对 `TCP` 连接状态变化的处理，只需实现以下两个函数：

```elixir
@impl true
def handle_info({:tcp_closed, _conn}, state) do
    Logger.error("Socket #{inspect(state.socket, pretty: true)} closed unexpectly.")
    DynamicSupervisor.terminate_child(GateServer.TcpConnectionSup, self())

    {:stop, :normal, state}
end

@impl true
def handle_info({:tcp_error, _conn, err}, state) do
    Logger.error("Socket #{inspect(state.socket, pretty: true)} error: #{err}")
    DynamicSupervisor.terminate_child(GateServer.TcpConnectionSup, self())

    {:stop, :normal, state}
end
```

这里我们就可以对 `TCP` 的连接建立以及信息收发功能进行测试了。假设我的 `gate_server` 运行在本机 `29000` 端口上，我们运行 `Telnet`：

```powershell
telnet 127.0.0.1 29000
```

即可开始与服务器进行通信。测试结果：

#figure(image("/public/assets/img/2022/20221016_echo_test.png"), caption: "beacon_server state 内容")

= 接下来的工作

`gate_server` 到这里暂告一段落，一个能够接受 `TCP` 客户端连接并且进行高并发通信的服务器就基本完成了。下一步我们将继续实现消息协议相关内容，引入 `Protobuf` 消息库并进行消息分发，进一步完善网关服务器功能。此部分功能等到下一步实现场景服务器 `scene_server` 后再回来继续，敬请期待！
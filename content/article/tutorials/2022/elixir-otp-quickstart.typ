#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Elixir+OTP简单实践",
  desc: [在这里，我们来看一个使用 Elixir 和 OTP 开发的完整例子，这个例子实现了一个简单的计数器服务器],
  date: "2022-12-27",
  tags: (
    blog-tags.elixir,
    blog-tags.server,
  ),
)

在这里，我们来看一个使用 Elixir 和 OTP 开发的完整例子，这个例子实现了一个简单的计数器服务器。

首先，我们需要创建一个新的 Elixir 项目。可以使用 `mix` 命令来创建项目：

```elixir
mix new counter
```

这将创建一个名为 `counter` 的新项目，并生成了一些初始的文件。

接下来，我们需要创建一个用于管理计数器状态的模块。这个模块将使用 `GenServer` 模块来管理状态。我们可以在项目的 `lib` 目录下创建一个新的模块文件，例如 `lib/counter.ex`，并编写如下代码：

```elixir
defmodule Counter do
  use GenServer

  def start_link(initial_count) do
    GenServer.start_link(__MODULE__, initial_count)
  end

  def increment(pid) do
    GenServer.call(pid, :increment)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def init(initial_count) do
    {:ok, initial_count}
  end

  def handle_call(:increment, _from, count) do 
    {:reply, :ok, count + 1}
  end

  def handle_call(:get, _from, count) do
    {:reply, count, count} 
  end
end
```

这里，我们创建了一个名为 `Counter` 的模块，并使用 `GenServer` 模块来管理状态。我们定义了三个函数：`start_link/1` 用于启动新的计数器进程，`increment/1` 用于将计数器的值加 1，`get/1` 用于获取当前计数器的值。 我们还定义了两个处理函数：`handle_call/3` 用于处理来自客户端的调用，`init/1` 用于初始化计数器的状态。 接下来，我们可以使用这个模块来创建新的计数器进程，并使用 `increment/1` 和 `get/1` 函数来操作计数器。例如，我们可以在 `iex` 中运行如下代码来创建新的计数器进程，并使用它来计数：

```elixir
iex> pid = Counter.start_link(0)
{:ok, #PID<0.119.0>}
iex> Counter.increment(pid) 
:ok 
iex> Counter.get(pid) 
1 
iex> Counter.increment(pid) 
:ok 
iex> Counter.get(pid)
2
```

在这个例子中，我们创建了一个新的计数器进程，并使用 `increment/1` 函数两次将计数器的值加 1。然后，我们使用 `get/1` 函数两次获取当前的计数器值，发现它已经变成了 2。

这就是一个使用 Elixir 和 OTP 开发的简单计数器服务器的完整例子。通过使用 OTP 提供的模块和工具，我们可以更快速、更高效地构建可维护的服务器端程序。

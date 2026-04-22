#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(13) - Rustler 介绍",
  desc: [Rustler 是一个用 Rust 语言来写 Erlang NIF 函数的库。 NIF(Native Im],
  date: "2022-11-27",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.elixir,
    blog-tags.rust,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

#link("https://github.com/rusterlium/rustler")[Rustler] 是一个用 `Rust` 语言来写 `Erlang NIF` 函数的库。

`NIF(Native Implemented Function)`，意为原生实现函数，是一类用C语言等语言原生实现的函数。这些函数以动态链接库的方式被 `Erlang` 虚拟机载入并调用，能够达到原生代码的运行速度。`NIF` 在调用时没有上下文切换，在 `Erlang` 所有调用类C代码的方式中（还有Port、PortDriver等）是 *最快* 的一种。

对于 `NIF` 来说，虽然速度很快效率很高，但也有自身的问题：

*第一* 就是由于没有上下文切换，那么一个 `NIF` 函数的执行就会一直占用 CPU。如果函数#link("https://www.erlang.org/doc/man/erl_nif.html#lengthy_work")[执行时间过长]，会导致虚拟机调度异常且程序无响应。因此`NIF` 函数的执行时间需要尽可能短，或者将一个运算量大的任务分割成若干个小任务。

*第二* 是一个 *致命缺陷* ——  `NIF` 代码如果出错崩溃（如内存错误等），会连带整个运行环境（Beam，Erlang 运行时虚拟机）崩溃，导致整个程序的崩溃退出。这一点在通常境况下来说是不可接受的，开发者需要将 `NIF` 函数写得尽可能安全，但这也是一项很艰难的工作，毕竟人所能考虑到的情况永远比实际可能发生的情况要少。这时候，`Rust` 就能体现其优势了。

`Rust` 语言拥有大量的安全设计，能够避免相当一部分程序错误的发生。在一般业务中，这个设计可能无足轻重，但是在这里就很关键了。`Rust` 的这种特性可以在很大程度上避免 `NIF` 的崩溃，从而使得 `NIF` 的使用变了更安全了，在很大程度上规避了上面所说的致命缺陷。这时，`Rust NIF` 就成为了提高 `Erlang/OTP` 代码运行效率的利器。*因此*，我在 `Elixir` 为主体的服务器框架中选择了这套方案来提高代码的执行速度，降低延迟。

虽然从性能上来说这个方案很美好，但是现实里我们还是不得不面对一些其他方面的问题，比如生态情况。`Rust` 作为目前仍然小众的语言，在现成轮子方面很不尽人意。尽管有越来越多的人在把一些 `C++` 库向 `Rust` 移植，但是进展缓慢，基本处于不可用状态。比如我近期打算在服务器上部署物理引擎，但是 `Rust` 方面像 `Physx` 那么完善成熟的物理引擎根本没有，我只能选择一个看起来功能比较全、文档还不错的项目来使用，并默默希望这个项目未来能稳步继续发展。

综上，`Rustler` 是一个提升 `Erlang/OTP` 代码运行效率的利器，这也是我在这个系列中使用它的原因。游戏服务器需要大计算量、低延迟，因此代码的运行速度就极为重要，这时 `Rustler` 的出现无疑就成为了最佳方案。虽然目前还没有碰到许多问题，但等到服务器功能相对完善之后我们再回过头来看时，就可以知道这个选型是对还是错了。

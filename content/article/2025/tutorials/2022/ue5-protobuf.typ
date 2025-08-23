#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "向UE5项目中集成Protobuf",
  desc: [向UE5项目中集成Protobuf],
  date: "2022-10-12",
  tags: (
    blog-tags.programming,
    blog-tags.ue5,
    blog-tags.protobuf,
  ),
)

*虚幻引擎版本：5.0.3*

*Protobuf版本：21.7*

#quote(block: true)[
  作为不懂C++的人，向UE集成C++库真的是一种折磨。

  ——沃兹基·硕德
]

#link("https://www.bilibili.com/video/BV1j54y1G7wE/")[B站上人宅的教程]说得很详细，从创建插件到`Protobuf`源码的导入，如果严格按照他的方法做的话最终结果*应该*是可以用的。但是我在跟随的过程中遇到了问题：

视频里有一个把`Protobuf`源代码拷贝到插件代码目录里的步骤，但是从视频中的文件列表可以看出其与官方源码不完全一致。我尝试过将官方源码原封不动放进插件，结果编译无法通过；

我又暂停视频，利用视频中的文件列表删掉多余的官方源码文件，再放进插件，结果插件本身是编译通过了，但是一旦用`proto`文件生成`C++`文件并在游戏代码中引入之后，编译又会报一堆的错误。

查阅众多资料之后发现，几乎没有一个最近还在更新的教程或者代码库，基本都失去了参考价值。最终找到了#link("https://gitee.com/love_linger/UE4Protobuf/blob/master/Protobuf.Build.cs")[这个代码]。代码中作者使用`引入预编译好的库文件`的方式实现`Protobuf`的集成给了我思路。预编译的库文件可以从官方源码中编译而来，而我只需要包含完整的头文件即可。因此我做了下面的工作：

= 从官方源码编译所需的包含文件(include)和库文件(.lib)

从#link("https://github.com/protocolbuffers/protobuf/releases")[官方Github仓库]下载源代码。在本人写下这篇文章时，最新的*Release*是`21.7`。下载时选择C++的压缩包：

#figure(image("/public/assets/img/2022/20221012_proto_source_download.png"), caption: "下载源码")

下载后解压，按照官方`README`的指示编译和安装。本人当时使用的是`CMake + VS2019`的方式得到最终的包含文件和库文件：

#figure(image("/public/assets/img/2022/20221012_proto_build_result.png"), caption: "Proto源码编译结果")

- `include`文件夹为要包含的头文件
- `lib`文件夹内有编译好的`.lib`库文件，我只使用了`libprotobuf.lib`
- `bin`文件夹内有转化`.proto`文件用的可执行程序`protoc.exe`

= 将编译结果整合进UE5插件

所以需要拷贝的东西如下（为了整洁，保持文件结构）：

- `include`文件夹
- `lib/libprotobuf.lib`
- `bin/protoc.exe`

把这三个东西放到插件目录下，我的插件名叫`SimpleProto5`，我放到了`插件/Source/SimpleProto5/ThirdParty/probuf`下：

#figure(image("/public/assets/img/2022/20221012_proto_plugin_structure.png"), caption: "放置路径")

文件到位之后，还需要修改插件的`.Build.cs`文件，添加头文件包含路径以及库文件查找路径：

```csharp
// 头文件包含路径
PublicSystemIncludePaths.AddRange(
  new string[]
  {
    Path.Combine(ThridPartyPath, "protobuf/include")
  }
);

// 库文件包含路径
PublicAdditionalLibraries.Add(Path.Combine(ThridPartyPath, "protobuf", "lib", "Win64", "libprotobuf.lib"));
```

其中库文件路径的写法是临时的，因为我的目标是不只支持`Windows`一个平台，因此后续可以根据不同平台添加不同的库文件路径。

= 后续操作

你可以选择继续跟着人宅的视频把这个插件做完，但是关于`Protobuf`引入的过程到这里就结束了。跟着文章做的小伙伴可以编译一下项目看看，如果没有其他问题的话项目应该是可以正常编译的。

如果编译过程中出现如下错误：

```text
inlined_string_field.h(430): [C4668] 没有将“GOOGLE_PROTOBUF_INTERNAL_DONATE_STEAL_INLINE”定义为预处理器宏，用“0”替换“#if/#elif”
```

只需要根据错误定位到`inlined_string_field.h`文件的第430行，把`#if`改为`#ifdef`即可。

祝各位在`UE5`中与`Protobuf`玩的开心！
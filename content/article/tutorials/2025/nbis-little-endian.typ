#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "在编译NBIS时强制使用小端序",
  desc: [自带编译配置不生效，在编译NBIS时强制使用小端序],
  date: "2025-09-14",
  tags: (
    blog-tags.programming,
    blog-tags.blog,
  ),
)

在编译#link("https://www.nist.gov/services-resources/software/nist-biometric-image-software-nbis", "NBIS")时，按照正常情况来说，源码自带Makefile会根据系统环境自动判断是否使用小端序。但是在实际使用中发现，这个配置在我的系统上不生效。

= 环境

系统：Ubuntu 22.04 WSL2

= 问题

使用NBIS工具包是为了对WSQ文件进行解析。WSQ数据文件是以大端序来排列字节的。一开始我并不知道大小端序的问题，直接编译生成链接库然后调用解析。正常情况下，大端序数据在进行内存拷贝的时候会自动进行大小端序的转换。但是当我把数据从WSQ文件中读取出来之后，直接进行内存拷贝，发现数据并没有被正确转换，导致标记字节反序：

```
// 数据中的大端序标记（程序应当读取到的正确标记）
0xFF 0xA0
// 转换后内存中的小端序标记（程序读取到的错误标记）
0xA0 0xFF
```

查看源码后发现，在读取数据的函数`getc_ushort`中，程序会根据一个`__NBISLE__`宏来判断是否要对两个字节进行交换：

```c
#ifdef __NBISLE__
   swap_short_bytes(shrt_dat);
#endif
```

但是这个宏明明由Makefile生成，却没有生效。我试过了各种通过make命令传入参数的方式，但都没有起效。

= 解决方案

最终我决定直接改源码，在源码中直接写死`__NBISLE__`宏：

```c
#ifndef __NBISLE__
#define __NBISLE__ 1
#endif
```

这样可以绝对确保程序在读取的时候一定能够读取到`__NBISLE__`宏。

经过一番AI和搜索，最终确定需要改的位置为：

- `commonnbis/include/defs.h` 中加入宏定义
- `imgtools/include/ioutil.h` 中引用上面的头文件

这样修改完编译之后，程序终于能够正确读取到数据中的大端序标记了。

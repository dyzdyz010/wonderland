#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "在 Ubuntu 18.04 LTS 上安装并运行 KBEngine",
  desc: [在 Ubuntu 18.04 LTS 上安装并运行 KBEngine],
  date: "2018-05-05",
  tags: (
    blog-tags.game,
    blog-tags.linux,
  ),
)

本文用到的组件和系统版本：
- *OS*: Ubuntu 18.04 LTS
- *MySQL*: 5.7.22
- *gcc*: 7.3.0
- *g++*: 7.3.0
- *Python*: 3.6.5

首先安装各种依赖：

```bash
sudo apt-get update
sudo apt-get install libssl-dev mysql-server libmysqld-dev mysql-client libmysqlclient-dev gcc g++ python3
```

= 编译引擎

下面从#link("https://github.com/kbengine/kbengine")[官方仓库]下载引擎源码，本人下载的是当时最新版本1.1.8：

```bash
wget https://github.com/kbengine/kbengine/archive/v1.1.8.tar.gz
tar -xzvf v1.1.8.tar.gz
```

接着就可以对代码进行编译了：

```bash
cd kbengine-1.1.8/kbe/src
chmod -R 755 .
make
```

我在编译过程中出现了以下错误：

```bash
/usr/lib/gcc/x86_64-linux-gnu/7/include/mm_malloc.h:34:16: error: declaration of 'int posix_memalign(void**, size_t, size_t) throw ()' has a different exception specifier
... (long error output)
```

如果遇到这个错误，请参考这个 #link("https://gist.github.com/johnmurrayvi/5879822")[Gist]。

如果编译没有任何错误地结束了，就说明编译成功了，接下来是在运行服务器之前的一些额外配置。

= 环境变量

根据你的 shell 选择对应的配置文件进行修改，此处我用默认的bash：

```bash
vim ~/.bashrc
```

将下面的内容复制到文件最底部：

```bash
ulimit -c unlimited
export KBE_ROOT=引擎文件夹根目录
export KBE_RES_PATH=$KBE_ROOT/kbe/res/:$KBE_ROOT/assets/:$KBE_ROOT/assets/scripts/:$KBE_ROOT/assets/res/
export KBE_BIN_PATH=$KBE_ROOT/kbe/bin/server/
```

保存退出并使之生效：

```bash
source ~/.bashrc
```

= 数据库配置

首先创建需要的数据库：

```
mysql> create database kbe;
```

创建需要的用户：

```
mysql> grant all privileges on *.* to kbe@'%' identified by 'pwd123456';
```

完成后退出 MySQL 然后用创建好的用户重新登录：

```bash
mysql -u kbe -p
```

并输入密码，如果可以进入 MySQL 说明创建成功。

上面创建的数据库名和用户名密码都是引擎的默认值，如果你按照自己的想法用了别的名字，则需要进入引擎配置文件做相应修改：

```bash
vim <引擎根目录>/kbe/res/server/kbengine_defaults.xml
```

在文件中找到以下部分：

```xml
<dbmgr>
        <databaseInterfaces>
            <default>
                <port> 3306 </port>
                <auth>
                    <username> kbe </username>
                    <password> kbe </password>
                    <encrypt> false </encrypt>
                </auth>
                <databaseName> kbe </databaseName>
            </default>
        </databaseInterfaces>
    </dbmgr>
```

在对应的字段做修改就可以了。

= 运行与关闭

接下来我们就可以运行服务器了：

```bash
# 已经设置环境变量
sh <引擎根目录>/assets/start_server.sh
# 未设置环境变量
cd <引擎根目录>/assets
sh start_server.sh
```

启动成功后会有9个进程，用以下方式查看是否启动成功：

```bash
ps -aux | grep <引擎根目录>
```

使用以下命令停止服务器：

```bash
sh kill_server.sh
```

或者：

```bash
sh safe_kill.sh
```

`注意：`使用 _safe_kill.sh_ 的时候需要用 `python` 命令来运行 py 脚本，而如果只安装了 python3 的话是不能通过 _python_ 命令进入的，因此我们对 python3 进行一个软链接：

```bash
sudo ln -s /usr/bin/python3.6 /usr/bin/python
```

至此大功告成！

== 参考文章：

- #link("https://www.comblockengine.com/docs/1.0/install/index/")[官方文档——引擎安装和启动详解]
- #link("https://blog.csdn.net/u012741077/article/details/51296832")[\[KBEngine\]安装及第一次启动]

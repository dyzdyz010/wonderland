#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "UOS 重置密码与登录钥匙环修复记录",
  desc: [通过 GRUB 临时 root shell 重置 UOS 用户密码，并处理 deepin 登录钥匙环无法用新密码解锁的问题。],
  date: "2026-05-23",
  tags: (
    blog-tags.linux,
    blog-tags.dev-ops,
    blog-tags.software,
  ),
)

有些故障不会给人留下很多思考空间：机器就在眼前，登录密码忘了，系统还能启动，但进不了桌面。UOS 这种基于 Linux 的桌面系统，最直接的处理方式是从 GRUB 临时接管启动流程，进入一个最小 root shell，挂载真实根分区，然后重置目标用户密码。#footnote[这篇记录默认你能接触到机器本身或虚拟机控制台，并且有权限维护这台系统。绕过登录密码是高权限恢复操作，不应被用于未授权设备。]

本文记录一次完整流程：先重置系统登录密码，再处理重启后 deepin 登录钥匙环无法解锁的问题。#footnote[登录密码和登录钥匙环密码不是同一个东西。前者由系统账户认证管理；后者通常用于保护桌面环境保存的应用凭据。重置系统密码并不会自动改写旧钥匙环的加密密码。]

= 总览

流程可以浓缩成五步：

#quote(block: true)[
  GRUB 编辑启动参数 → 进入 bash → 找到 `LABEL=Roota` → 挂载并 `passwd` → 删除失效的 `login.keyring`
]

真正需要小心的是两个边界：一是确认挂载的是 Roota 对应的根分区，二是理解删除 `login.keyring` 会让旧钥匙环里的保存凭据失效。#footnote[`Roota` 是 UOS/Deepin 系统分区布局中常见的根分区标签。不同安装方式可能略有差异，所以本文使用 `blkid` 现场确认，而不是假设它一定是 `/dev/sdaX` 或 `/dev/nvme0n1pX`。]

= 进入 GRUB 编辑界面

重启机器，在 GRUB 菜单出现时停住，选中要启动的 UOS 项目，按 `E` 进入编辑界面。

在编辑内容里找到以 `linux` 开头的那一行。它通常很长，包含内核路径、root 参数、quiet/splash 等启动参数。把光标移动到这一行末尾，追加：#footnote[这里的 `rw` 表示让根文件系统以可写方式挂载；`init=/bin/bash` 表示让内核启动后直接运行 bash，而不是正常进入 systemd/init 流程。]

```bash
rw init=/bin/bash
```

然后按 `F10` 启动。系统不会进入图形界面，而是直接落到命令行。#footnote[这一步只是一次性修改启动参数，不会永久写入 GRUB 配置；重启后正常启动项仍然按原配置工作。]

= 找到 Roota 分区

进入命令行后，先用 `blkid` 查看块设备标签：

```bash
blkid
```

在输出中找到 `LABEL="Roota"` 对应的设备名。它可能长得像：

```text
/dev/sda3: LABEL="Roota" UUID="..." TYPE="ext4"
/dev/nvme0n1p3: LABEL="Roota" UUID="..." TYPE="ext4"
```

记下这个设备名。后文用 `<设备名>` 表示它。#footnote[不要凭经验直接猜设备名。SATA 磁盘常见 `/dev/sda3`，NVMe 磁盘常见 `/dev/nvme0n1p3`，虚拟机和多盘环境还可能完全不同。`blkid` 的标签比设备顺序更可靠。]

= 挂载根分区

把 Roota 分区挂载到 `/root`：

```bash
mount -t ext4 <设备名> /root
```

例如，如果 `blkid` 显示 Roota 是 `/dev/nvme0n1p3`，则执行：

```bash
mount -t ext4 /dev/nvme0n1p3 /root
```

这里指定 `-t ext4` 是因为这次记录中的 Roota 是 ext4 文件系统。#footnote[如果你的系统实际显示的 `TYPE` 不是 `ext4`，就应该按 `blkid` 输出调整挂载类型；不要机械照抄。]

= 修改用户密码

挂载完成后，执行 `passwd` 修改目标用户密码：

```bash
passwd <用户名>
```

按提示输入新密码并确认。完成后可以退出临时 shell、卸载挂载点，然后强制重启：

```bash
exit
umount /root
reboot -f
```

重启后，正常进入 UOS 登录界面，使用刚设置的新密码登录即可。#footnote[`reboot -f` 是强制重启，适合这种没有完整 init/systemd 管理的临时 shell 场景。若在正常运行系统中使用，应该优先走正常重启流程。]

= 处理登录钥匙环无法解锁

系统密码改完后，可能会遇到一个新的提示：进入桌面后要求“解锁登录钥匙环”，但输入新密码不管用。

这是因为旧的登录钥匙环仍然由旧密码保护。系统登录密码已经被改掉，但钥匙环文件没有被重新加密，所以新密码无法打开它。#footnote[很多桌面环境都会有类似机制：登录成功之后，桌面会尝试用登录密码自动解锁保存浏览器、网络、应用 token 等凭据的 keyring。密码离线重置后，这个自动解锁链条就断了。]

如果不需要保留旧钥匙环里的凭据，可以删除当前用户目录下的 `login.keyring`，让系统后续重新生成：

```bash
cd ~/.local/share/deepin-keyrings-wb
rm -rf login.keyring
```

下次相关组件需要保存凭据时，会重新创建新的登录钥匙环。#footnote[删除 `login.keyring` 的代价是旧钥匙环中保存的密码、token 或应用凭据可能丢失。对于刚恢复登录、主要目标是进系统的场景，这是最省事的处理；如果里面有重要凭据，应先考虑备份该文件。]

= 快速命令清单

如果只需要照着操作，可以按下面顺序核对：

```bash
# 1. GRUB 中编辑 linux 行末尾追加：
rw init=/bin/bash

# 2. 进入 shell 后查找 Roota：
blkid

# 3. 挂载 Roota，对应设备名按实际替换：
mount -t ext4 <设备名> /root

# 4. 修改目标用户密码：
passwd <用户名>

# 5. 收尾并重启：
exit
umount /root
reboot -f

# 6. 登录桌面后，如果钥匙环无法解锁：
cd ~/.local/share/deepin-keyrings-wb
rm -rf login.keyring
```

= 复盘

这次问题本质上是两层密码状态不同步：

- 系统账户密码：通过 `passwd` 重置后，控制登录认证。
- deepin 登录钥匙环：仍然由旧密码加密，控制桌面凭据解锁。

前者解决“进不了系统”，后者解决“进系统后不断弹钥匙环”。把两步分开看，整个恢复过程就清楚了。
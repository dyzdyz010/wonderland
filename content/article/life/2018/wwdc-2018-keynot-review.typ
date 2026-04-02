#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "WWDC 2018 Keynot 个人总结",
  desc: [WWDC 2018 Keynote 个人总结，涵盖 iOS 12、watchOS 5、tvOS 和 macOS Mojave。],
  date: "2018-06-06",
  tags: (
    blog-tags.apple,
    blog-tags.misc,
  ),
)

文中图片来自#link("https://mp.weixin.qq.com/s/mwhcO9MI2mD5mxNICqiMCg")[爱范儿——苹果 WWDC 2018：最全总结在这里，不错过任何重点]

开场就说 Today is all about software，本来期待一些硬件更新的我有点小失望，但问题不大

= iOS 12

== Hotfix

首先是系统提速，确实 iPhone 感觉越用越慢，看来苹果也真正开始重视这个问题了，同时也解决了设备降速的问题，而且支持到了 5s，在我看来是有起码的诚意的。

#figure(image("/public/assets/img/2018/06/640.jpeg"))

#figure(image("/public/assets/img/2018/06/640-2.jpeg"))

== AR

苹果发布了新的模型格式 `USDZ`，包含了模型和动画数据，我的猜测是应该类似于目前 `Direct X` 拥有的 `X` 文件格式，用来一站式存储单个模型或场景的所有相关数据，用于 3D 应用中的模型数据管理，也算是苹果软件生态的一部分吧，看来 `Metal` 说不定在游戏领域还是有出头之日的。

#figure(image("/public/assets/img/2018/06/640-36.jpeg"))

AR 游戏现在有多人和旁观者模式了，同学聚会和团建上又可以多一种项目选择了

#figure(image("/public/assets/img/2018/06/640-3.jpeg"))

== 相册

向 Google 学习，相册变得更智能了，意味着更多的自动推荐选项，包括搜索啦，整理归档啦，这些都是小问题，更新颖的是能推荐分享内容，帮你选择比较适合分享的几张照片，而且接收方还能根据收到的照片把自己的相似的照片再分享回去，仔细想想其实这是个挺好的功能，让一次集体活动的记录视角在每个人的手机上更完整。然而在我的 iCloud 照片部分丢失后，我已经对照片这个应用不再感冒了，现在的主力照片存储在 Dropbox 上。

#figure(image("/public/assets/img/2018/06/640-4.jpeg"))

#figure(image("/public/assets/img/2018/06/640-5.jpeg"))

BTW 照片分享也是端到端加密的，苹果的安全技术我还是比较放心的。

== Siri

Siri 作为普遍认同的"人工智障"已经在成为语音指令助手的路上越走越远了......

这次发布了 `Shorcuts` 功能，按照我的理解，就是把一个特定的功能创建成一条语音指令_特例_，这样在用 siri 呼出的时候，就可以基本跳过语义分析之类的流程，直接输出结果，和函数调用有点类似。

除此之外，苹果还允许用户自己创建 `Workflow`，说白了就是用一条指令把一系列功能捆绑到一起，方便一次性调用。

这两个功能基本是属于 Siri 自己的功能，所以像 HomePod 和 Apple Watch 这样能呼出 Siri 的设备都可以使用这项功能。我猜测这个功能在未来的智能家居上应该能有大作为。

#figure(image("/public/assets/img/2018/06/640-6.jpeg"))

#figure(image("/public/assets/img/2018/06/640-7.jpeg"))

== Built-in Apps

苹果更新了自带的四个应用——新闻、股票、语音备忘录和 iBooks（已经改名为 Apple Books）——对我来说实在是鸡肋，属于从来不开的那种应用。不过值得一提的是股票应用结合了新闻，可以看到某支股票相关的财经新闻，可能方便炒股的人了解行情吧。

#figure(image("/public/assets/img/2018/06/640-8.jpeg"))

#figure(image("/public/assets/img/2018/06/640-9.jpeg"))

== CarPlay

CarPlay 开放了第三方导航软件，可喜可贺 然而我还是没有车

#figure(image("/public/assets/img/2018/06/640-10.jpeg"))

== 防沉迷

首先是 `勿扰模式（Do Not Disturb）`可以支持定时自动退出了，这只是一个弥补功能上的不足之举；再就是在晚上睡觉的时候，通知会被静默和隐藏，不至于让你醒来后看通知看到睡不着

#figure(image("/public/assets/img/2018/06/640-11.jpeg"))

接下来是对通知展现方式的改进。在 iOS 12 上，通知可以分组了，这样就不会在点亮屏幕的时候看到一长串的通知，把有可能是紧急的通知挤到下面看不见的地方；通知本身也可以被`静默化，没有弹窗、没有小红点，当然也不会有声音`；通知的展示和处理方式也被智能化了，系统可以提供智能化的回复建议，或者把可能是紧急的通知优先展示给用户。

#figure(image("/public/assets/img/2018/06/640-12.jpeg"))

#figure(image("/public/assets/img/2018/06/640-13.jpeg"))

再接下来就是传说中的_防沉迷_系统了。在 iOS 12 中，你可以看到自己对手机里应用程序的每日使用情况了，对你每天被什么样的程序耗费大量时间能有一个直观的了解，同时还能给某个应用程序设置使用时长限制，也方便你戒手机

#figure(image("/public/assets/img/2018/06/640-14.jpeg"))

除此之外还有针对小孩的设定，比如家长可以在自己的设备上看到小孩一天的手机使用情况，还可以限制儿童在某个特定应用上的使用时间，沉迷玩手机不能自拔的小孩们可能好日子要到头了

== Emoji

苹果对 Emoji 的使用和推广力度不是一般的大，这次对 Emoji 的进化版 Animoji 进行了更新，添加了几个新角色，而且新增了舌头检测

#figure(image("/public/assets/img/2018/06/640-15.jpeg"))

接下来是我最喜欢的部分——苹果宣布了新的 `Memoji` 技术，能够允许用户创建自己的 Animoji，并且能在视频聊天里使用，视频聊天也进化成了最高32人群聊。想知道 Memoji 的效果？去看皮克斯和迪士尼的3D 动画电影。这是我个人最喜欢的一个新功能了。

#figure(image("/public/assets/img/2018/06/640-16.jpeg"))

#figure(image("/public/assets/img/2018/06/640-17.jpeg"))

== 总结

看到网上人们都再说这次 WWDC 上 iOS 12 系统没有新功能出现，但是在我看来，上面每一个内容都是新功能，虽然可能不是那么让人感觉耳目一新，但是大部分可以说都是我们平时在使用手机的过程中频繁会涉及到的功能，比如设备提速。虽然没有人们在之前希望的黑暗模式出现，但是就现有的展示来看，iOS 12 已经是足够有诚意了，我很喜欢。

#figure(image("/public/assets/img/2018/06/640-18.jpeg"))

#figure(image("/public/assets/img/2018/06/640-19.jpeg"))

= watchOS 5

Apple Watch 从第一代不被人看好一路走到现在成为智能手表中的代表，也是不容易。刚开始的时候 Apple Watch 还没有找到自己的定位，但是现在就很清晰了——主打运动健身相关功能，看起来发展态势也是不错，虽然我没有就是了

#figure(image("/public/assets/img/2018/06/640-20.jpeg"))

== 成就系统 & 运动追踪

watchOS 5 现在有了一个七日挑战系统，可以向好友发起挑战，赢取奖章。我觉得苹果离建立自己的运动排行榜不远了

在 watchOS 5 上，系统可以自动检测用户的运动状态了，以便让用户记录的运动时间更准确。但是我一直觉得，这是一个应该从一开始就有的功能，这种让用户主动选择开始结束的做法是没有道理的，因为绝对会被滥用，导致大量的不准确数据，对设备的定位和口碑也是一种伤害。

#figure(image("/public/assets/img/2018/06/640-21.jpeg"))

== 对讲机

苹果还发布了一个 `Walkie-Talkie` 即对讲机的功能。但是这个功能貌似是走网络的，所以我很怀疑它的实时性和可用性。

#figure(image("/public/assets/img/2018/06/640-22.jpeg"))

== Siri & 通知

Siri `Shortcuts` 理所当然地配备到了 Apple Watch 上，而且成了表盘之一；你也不用每次都用 "Hi, Siri" 来唤醒，而是可以抬手唤醒了，确实能省下不少口水

watchOS 5 还支持了交互式通知，允许用户进行一些简单的交互操作，比如给滴滴司机评个分，住店 Check-in 之类的，手表的功能更多样化更强大了。

#figure(image("/public/assets/img/2018/06/640-23.jpeg"))

也有比较鸡肋的新功能，比如看网页......以及不那么鸡肋的功能，比如听 Podcast。

#figure(image("/public/assets/img/2018/06/640-24.jpeg"))

== 校园卡

比较令我振奋的是，watchOS 5 推出了校园卡功能，意味着你可以用 Apple Watch 刷卡宿舍门、洗衣房、食堂，etc... 确实很实用很方便，但目前只有美国那么几所高校开始使用，国内高校跟进恐怕遥遥无期

#figure(image("/public/assets/img/2018/06/640-25.jpeg"))

最后苹果掏出了全场唯一的硬件——一个彩虹表带和配套彩虹表盘，更丰富了佩戴人士的风格选择范围。

#figure(image("/public/assets/img/2018/06/640-26.jpeg"))

== 总结

苹果手表这么些年以来，定位逐渐清晰，功能逐渐丰富，风格也越来越多样化，感觉总体态势还是不错的。但是随着功能的增多，我比较担心电池和续航的问题，如果一只手表需要每天都充电，那我觉得给人带来的麻烦是再多功能也弥补不了的。随着 `eSIM` 的普及，我相信苹果手表还有更大的发挥空间。

= tvOS

这是为一款在国内买不到的设备设计的新操作系统，但是我很喜欢这样一个小巧的内容聚合平台...

这次 tvOS 为用户升级到了 `4K HDR` 画质...

#figure(image("/public/assets/img/2018/06/640-27.jpeg"))

同时，新的 tvOS 还支持了 `杜比全景声（Atmos）`...

#figure(image("/public/assets/img/2018/06/640-28.jpeg"))

如果你喜欢在客厅摆一个 Apple TV 的话，那么你之前下载的 `2160p HDR TrueHD 7.1 Atmos` 电影现在有用武之地了

当然，要想实现这些效果，光有一台 Apple TV 是不够的，你还需要全套的外围设备支持（7 HomePod 预定）

最后苹果更新了宇航员视角的新屏保，成为 `Aerial` 的一部分。

= macOS Mojave

命名来自于美国加利福尼亚西南的沙漠。

#figure(image("/public/assets/img/2018/06/640-29.jpeg"))

== 夜间模式

对于我等爱在晚上加班的人来说，黑暗模式真的很有用...

#figure(image("/public/assets/img/2018/06/640-30.jpeg"))

== 文件管理

新系统支持了对桌面文件进行智能分类...

#figure(image("/public/assets/img/2018/06/640-31.jpeg"))

在新系统上，在 `Finder` 中预览图片的时候，系统提供了一个功能更多的 `图库视图`...

#figure(image("/public/assets/img/2018/06/640-32.jpeg"))

在新系统中，截图功能得到了增强...

#figure(image("/public/assets/img/2018/06/640-33.jpeg"))

== 安全控制

现在新系统提供了粒度更细的权限控制，能在更多的方面限制应用程序对用户数据的获取。不得不说苹果的安全设计是在几大互联网企业中最良心的了。

== UIKit on macOS

虽然在 Keynote 上苹果明确说了 iOS 不会和 macOS 合为一体，但是苹果提供了一个折衷的方案，即把之前作为 iOS 核心框架的 `UIKit` 中的一部分添加到了 macOS app 的底层...

#figure(image("/public/assets/img/2018/06/640-34.jpeg"))

== App Store

新系统上重新设计了之前很不受待见的 `App Store` 应用商店...

#figure(image("/public/assets/img/2018/06/640-35.jpeg"))

= 总结

没有特别抢人眼球的新功能，但是生活中常用的功能更新无处不在，可以说更新的力度已经很大了...苹果还是那个有理想有原则有能力的苹果，作为果粉我不后悔。

#link("https://ws4.sinaimg.cn/large/006tKfTcgy1fs1hyuwyg2j31gw0pl4qp.jpg")[image]

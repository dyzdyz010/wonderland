#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(18) - Visualize Server(1) - PIXI.js 场景搭建",
  desc: [本节开始专注于前端可视化实现。 渲染库 我搜索了一大堆 2D、Web、引擎 等关键字，发现 PixiJS],
  date: "2022-12-02",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.ue5,
    blog-tags.tooling,
    blog-tags.software,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

本节开始专注于前端可视化实现。

= 渲染库

我搜索了一大堆 `2D、Web、引擎` 等关键字，发现 #link("https://pixijs.com/")[PixiJS] 总是出现在最上面，所以就它了。虽然它不是一个完整的游戏引擎，但是由于我们的需求也仅仅是把数据显示在页面上，没有什么高级的应用，所以一个单纯的渲染器我感觉也是足够的。

#quote(block: true)[
  后期万一有别的需求不够用了再说🙄
]

`PIXI.js` 是一个 `Web` 端 `2D` 渲染器，能够实现基本的场景元素管理、资源管理等功能，支持 `WebGL/Canvas` 绘制，默认为 `WebGL`。

*提前警告*：经过我这一天的搜索踩坑，这玩意的文档写得不是很好，有些函数解释得模糊不清，还有好多功能点压根就不提，要想重度使用的话要做好把搜索引擎翻烂的准备🙃

= 场景搭建

对于 `PIXI.js` 来说，他的场景管理是一个树形结构，从顶层的 *容器（Container）* 到底层的 *精灵（Sprite）*，上层包含下层，从而构成整个场景。

对于我们的场景来说，目前为了方便，就是下面这张图的范围：

#figure(image("/public/assets/img/2022/20221202-mmo-server-from-scratch(18)-visualize-server-pixijs-scene-setup-1.png"), caption: "scene.png")

这实际上是 `UE5` 自带第三人称模板场景的顶视图。为了简单，我们目前就只显示 `X, Y` 二维坐标。

*第一步*，是把 `PIXI` 的顶层对象 `Application` 加入到 `DOM树` 中，其实就是一个 `canvas` 标签。我为了方便就直接让他占了全屏（把它放到一个自适应的子元素下面会有各种尺寸问题我解决不了，我是菜鸡）。

*第二步*，是创建我们的场景容器。这一步是为了方便管理，后期可能会有多个场景拼在一起，这样我们可以把单个场景中的元素聚合在同一个容器元素下，方便统一进行移动缩放之类的操作。

*第三步*，向场景容器中加入一个 *精灵*，作为场景背景，也就是上面那张图。*PIXI.js* 中的 *精灵* 实际上就是加载一张图片，没什么特别的，注意尺寸就好。

到这里，场景初始化的流程就完成了。但是由于我用了 `Phoenix Liveview`，存在一个页面加载的问题，实测会影响 `PIXI` 场景的加载。因此以上代码需要在页面加载完成后再执行：

```javascript
window.addEventListener('phx:page-loading-stop', (info) => {
    makeScene()
    document.body.appendChild(app.view)

    app.renderer.backgroundColor = 0xbcbcbc;

    window.addEventListener('resize', resize);

    resize()

})
```

这里，`phx:page-loading-stop` 代表页面加载完成。我让页面监听 `resize` 事件，以应对窗口尺寸变化后让 `PIXI` 场景尺寸也跟着变化。

= 场景拖拽

显然，页面大小有时候不足以放下整个场景，只能显示一部分，我们需要能够拖动场景，以观看不同区域。这个功能我参照官方文档中的 #link("https://pixijs.io/examples/#/events/dragging.js")[Dragging - PixiJS Examples] 实现，整体上没有什么问题，但是有一个我觉得很难受的地方，就是不管鼠标按下的位置在哪里，开始拖动后总是以被拖动元素的最左上角为拖动点，因为 `PIXI` 的坐标系原点默认为左上角。

我希望的效果是，我按住哪里拖动，就直接以这个点为拖动点，而不是跳变到左上角跟随拖动，所以需要对链接中的例子进行一些小小的修改。

```javascript
function onDragStart(event) {
    this.alpha = 0.7
    dragTarget = this

    // 存储点击开始时点击点的全局坐标
    dragTarget.offCoord = event.global.clone()

    app.stage.on('pointermove', onDragMove)
}

function onDragMove(event) {

    if (dragTarget) {
        let movement = new PIXI.Point()

	// 计算拖动位移
        movement.x = event.global.x - dragTarget.offCoord.x
        movement.y = event.global.y - dragTarget.offCoord.y

	// 更新拖动元素坐标
        dragTarget.position.x += movement.x
        dragTarget.position.y += movement.y

	// 记录新的拖移点的全局坐标
        dragTarget.offCoord = event.global.clone()
    }
}
```

拖动结束的回调函数代码就不贴了，没有需要特别注意的。

这样一来我们只需要让我们的场景容器监听鼠标按下事件：

```javascript
scene.on('pointerdown', onDragStart, scene)
```

我们就可以拖动我们的场景容器了，里面的内容也会跟着一起移动。

= 下一步

下一步我们将显示表示玩家角色的 *精灵* 对象，同时寻找服务器定时推送数据的实现方式。


#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(22) - Visualize Server(5) - 前端坐标修正",
  desc: [上节我们说到，玩家角色的位置已经能够显示在网页上了，但是位置是错位的，因此本节我们来分析产生这个问题的原],
  date: "2022-12-13",
  tags: (
    blog-tags.programming,
    blog-tags.mmo,
    blog-tags.game,
    blog-tags.server,
    blog-tags.tooling,
    blog-tags.frontend,
  ),
)

#quote(block: true)[
  本系列代码仓库：#link("https://github.com/dyzdyz010/ex_mmo_cluster")[Stargazers · dyzdyz010/ex\_mmo\_cluster (github.com)]
]

上节我们说到，玩家角色的位置已经能够显示在网页上了，但是位置是错位的，因此本节我们来分析产生这个问题的原因，并解决这个问题。

经过比对，`PIXI.js` 的坐标轴方向与我截图的坐标方向是一致的，`x` 轴从左到右，`y` 轴从上到下，即坐标原点为左上角。

那就剩下一个问题：实际场景尺寸与场景截图的尺寸比例问题。

在网页中，场景的范围实际上就是我们对场景截图的范围，这个范围也就是图片的分辨率。

在 `PIXI.js` 中，图片的大小实际上就是精灵的尺寸：

```javascript
console.log(bg.width, bg.height)
```

这样一来，我们既有了真正场景的尺寸（从UE中得到），也有了网页中场景的尺寸，我们只需要对他们做一个映射，其实就是得到一个两者之间的比例：

```javascript
ratio = bg.width / 3000.0
```

这里 `3000.0` 就是 `UE` 中场景的宽度。

有了比例之后，我们就可以把角色在真实场景中的坐标转换为浏览器中场景的坐标了：

```javascript
clist.forEach(character => {
    if (players[character.cid] == null) {
        let sprite = PIXI.Sprite.from('/images/arrow_64.png')
        scene.addChild(sprite)

		// 应用比例
        sprite.position.set(character.location.x * ratio, character.location.y * ratio)
        sprite.scale.set(0.5)
        players[character.cid] = sprite
    } else {
		// 应用比例
        players[character.cid].position.set(character.location.x * ratio, character.location.y * ratio)
    }
});
```

我们在设置精灵坐标时，对坐标进行了变换，这样一来网页中玩家角色在场景中的位置就是正确的了：

#figure(image("/public/assets/img/2022/20221213-mmo-server-from-scratch(22)-visualize-server-frontend-coordinate-correction-1.png"), caption: "Pasted image 20221213211648.png")

虽然还有些误差，但是问题不大，截图可能歪了点。

= 下一步

可以从图中看到，我用了一个 *小箭头* 来表示玩家角色，从直觉出发的话，箭头的指向应该和角色的朝向保持一致，但是现在并没有相关的逻辑，所以箭头总是朝左的。下一步我们将实现这部分逻辑，让网页中的角色状态看起来更完善。


#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "从零开始的MMORPG游戏服务器(23) - Visualize Server(6) - 角色图标朝向问题修正",
  desc: [上节我们让玩家角色的指示图标以正确的位置显示在了网页中，但是当角色移动时，图标的方向并没有随着移动的方向],
  date: "2022-12-14",
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

上节我们让玩家角色的指示图标以正确的位置显示在了网页中，但是当角色移动时，图标的方向并没有随着移动的方向更新，而是一直朝着一个固定的方向，一点都不好看。本节我们来解决这个问题。

= 基本思路

指示图标的箭头指向实际上就应该是角色的移动方向。我们在为图标更新位置时，实际上我们有两个位置：

- 图标当前位置
- 图标所要更新的下一个位置

这样的话我们可以得出一个计算方向的思路：*用后一个位置减去前一个位置，得到一个位移向量*，这个向量的方向就是图标应该指向的方向。

= 实现

在 `PIXI.js` 中，精灵的旋转只能通过角度或者弧度来指定，不支持方向向量指定，因此我们还需要将方向向量转换为角度或者弧度。

`JS` 的 `atan2` 函数可以将向量坐标转换为其与 `x` 轴正方向的夹角弧度。到这里，我们其实就可以使用 `sprite.rotation` 来设置其旋转角度的弧度值了。如果想要角度的话，只需要对其进行变换：

d

e

g

r

e

e

s

=

r

a

d

i

a

n

s

∗

180

π

degrees = \\frac{radians \* 180}{\\pi}

d

e

g

rees

=

π

r

a

d

ian

s

∗

180

​

然后使用 `sprite.angle` 对其进行设置就行：

```javascript
function getAngle(x, y) {
    var angle = Math.atan2(y, x);   //弧度
    var degrees = 180 * angle / Math.PI;  //角度

    return degrees
}
```

这样设置完之后我发现，图标箭头的指示方向与我们的移动方向是相反的。这是因为我所使用的箭头图标的箭头方向是 `x` 轴负方向：

#figure(image("/public/assets/img/2022/20221214-mmo-server-from-scratch(23)-visualize-server-icon-facing-fix-1.png"), caption: "Pasted image 20221214205305.png")

因此我们给角度再加上 180°180\\degree180° 即可。对于弧度，则加上 π\\piπ。

现在方向正确了。但是当我们的角色停止移动的时候，箭头的方向又会回到 `x` 轴正方向，而不是与角色最后的移动方向保持一致。这是因为当静止时，精灵的两个坐标作差为0，所得到的角度就是 0°0\\degree0°。

要解决这个问题，我们只需要判断一下，只有在发生移动时才计算角度：

```javascript
const dx = character.location.x * ratio - players[character.cid].position.x
const dy = character.location.y * ratio - players[character.cid].position.y

if (dx != 0 || dy != 0) {
	// 正在移动，更新角度
    let angle = getAngle(dx, dy)
    players[character.cid].angle = angle + 180
}
```

= 下一步

到这里 `Visualize Server` 暂时告一段落，可以简单查看服务器端角色坐标状态了。之后我会继续聚焦物理引擎的加入和碰撞检测方面的逻辑。


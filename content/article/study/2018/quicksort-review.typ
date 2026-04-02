#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "快速排序算法理解",
  desc: [从 Haskell 的角度理解快速排序算法的工作原理。],
  date: "2018-05-18",
  tags: (
    blog-tags.algorithm,
    blog-tags.programming,
  ),
)

从本科到现在一直没有搞懂快排的原理，直到今天学习 Haskell 看到一张图，很直观地解释了快速排序的原理，这里我将以自己的理解向各位解释快排的工作原理。

快速排序的理念非常简单：

#quote(block: true)[从列表中取出一个元素，在剩下的元素中，选出所有比它小的元素放在它的左边，其余的放在右边。]

此时我们会遇到一个显而易见的问题：分别在被"选中"的元素左边和右边的两个列表，各自内部依然是乱序（未经过排序）的，因为这一步可以理解为对原列表的遍历，因此元素的顺序并没有变。

在这里，才是快速排序算法的真正体现——

#quote(block: true)[对各个列表，重复第一步的操作，直到选定元素两边的列表只剩至多一个元素。]

可以看出，这是一个递归操作。以数组 `[5, 1, 9, 4, 6, 7, 3]` 和排序函数 `quicksort` 为例：

== quicksort 开始

为了简化算法，我们直接在开始处理数组的时候，直接选择第一个元素作为被选定元素。经过筛选后，我们的结果此时变成了这样：

```haskell
quicksort([1, 4, 3]) ++ [5] ++ quicksort([9, 6, 7])
```

中间的`[5]`是我们选定的元素，左边是比它小的元素数组`[1, 4, 3]`，右边是比它大的`[9, 6, 7]`。可以看出，元素两侧的数组依然是乱序状态，仍然需要对其进行排序，因此上面的伪代码中写作 `quicksort(Array)`，即对两个数组继续应用排序操作。

这里以左边的数组为例，看看递归是如何工作的：

== quicksort 第一层递归

对新的数组 `[1, 4, 3]` 重复上面的操作，选定第一个元素 `1` 作为被选定元素，并筛选其两边的数组，结果变成这样：

```haskell
quicksort([]) ++ [1] ++ quicksort([4, 3])
```

左边已经成为空数组，意味着我们选定的 `1` 就是整个数组最小的元素了，因此没有比它更小的元素存在于它的左边位置了。这样就只剩右侧比它大的 `[4, 3]` 了，我们依然需要对其应用排序操作 quicksort：

== quicksort 第二层递归

对新的数组 `[4, 3]` 重复上面的操作，变成下面这样：

```haskell
quicksort([3]) ++ [4] + quicksort([])
```

至此，可以说递归的深度就到此为止了，左侧的 `quicksort([3])` 只剩一个元素不需要继续排序，将直接返回 3，右侧将直接返回空，此时上面的式子就完成了排序：

```haskell
quicksort([3]) ++ [4] ++ quicksort([])
= [3, 4]
```

== quicksort 第一层递归

将这个结果继续返回：

```haskell
quicksort([]) ++ [1] ++ quicksort([4, 3])
= [1] ++ [3, 4]
= [1, 3, 4]
```

== quicksort 顶层

继续返回：

```haskell
quicksort([1, 4, 3]) ++ [5] ++ quicksort([9, 6, 7])
= [1, 3, 4] ++ [5] ++ quicksort([9, 6, 7])
= [1, 3, 4, 5] ++ quicksort([9, 6, 7])
```

对最开始时候的式子的右边的 `quicksort([9, 6, 7])` 进行相同的操作，最终将得到排好序的数组：`[6, 7, 9]`。带入上式：

```haskell
[1, 3, 4, 5] ++ quicksort([9, 6, 7])
= [1, 3, 4, 5, 6, 7, 9]
```

大功告成！

到这里，整个快速排序算法过程就结束了。最后放上帮助我理解算法的图示和我写的 Haskell 实现，希望大家通过这篇文章，都能够轻松掌握快速排序

#figure(image("/public/assets/img/2018/05/quicksort.png"), caption: "快速排序图示")

```haskell
quicksort :: (Ord a) => [a] -> [a]
quicksort [] = []
quicksort (x:xs) =
  lessthan ++ [x] ++ largerthan
  where lessthan = quicksort [a | a <- xs, a < x]
        largerthan = quicksort [a | a <- xs, a >= x]
```

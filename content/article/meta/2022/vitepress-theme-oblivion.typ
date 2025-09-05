#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Oblivion - A Vitepress Theme",
  desc: [My new blog debut, with a new theme and a new look.],
  date: "2022-05-18",
  tags: (
    blog-tags.blog,
    blog-tags.theme,
    blog-tags.vitepress,
    blog-tags.vue,
  ),
)

上一个主题 #link("https://github.com/vuepress-reco/vuepress-theme-reco-1.x")[reco] 已经用了不短的时间了，最近关注 *Vitepress*，感觉很不错，于是萌生了自己再做一个主题的想法。

= 目前的功能

- toc
- Katex
- Tags 和 Collections
- Vitepress 默认主题中支持的几乎全部 Markdown 功能

= 加入各种功能时遇到的问题

在开发的过程中参考了很多现成主题的写法，包括 Vitepress 的 `default-theme`、#link("https://github.com/vuepress-reco/vuepress-theme-reco-1.x")[reco]、#link("https://github.com/clark-cui/vitepress-blog-zaun")[vitepress-blog-zaun]等等。

中间也遇到了好多问题，比如 Vue 动画效果在首次载入时的表现问题、SSR与客户端代码的区分问题、Katex 构建问题等等，到目前为止这几个问题都得到了解决。

= Katex

不得不说，Katex的加入给我带来了不小的麻烦，自定义标签会在 build 的时候报错：

#figure(image("/public/assets/img/2022/20220518katex-vitepress-build-error.png"), caption: "Katex构建错误")

找了好多的资料都没找到点上，最后还是在 Vitepress 自己的配置文件中增加了一项才解决问题。在 `.vitepress/config.ts` 中加入以下内容：

```typescript
// Katex用到的自定义 Tag 列表。参考：[](https://github.com/KaTeX/KaTeX/blob/main/src/mathMLTree.js#L23)
const mathTags = [
  "math", "annotation", "semantics",
  "mtext", "mn", "mo", "mi", "mspace",
  "mover", "munder", "munderover", "msup", "msub", "msubsup",
  "mfrac", "mroot", "msqrt",
  "mtable", "mtr", "mtd", "mlabeledtr",
  "mrow", "menclose",
  "mstyle", "mpadded", "mphantom", "mglyph"
]

// config 中加入 vue 字段
export default {
  vue: {
    template: {
      compilerOptions: {
          isCustomElement: tag => mathTags.includes(tag)
      }
    }
  },
}
```

*参考链接：*

1. #link("https://github.com/KaTeX/KaTeX/blob/main/src/mathMLTree.js#L23")[KaTeX]
2. #link("https://github.com/vuejs/vitepress/blob/main/src/node/config.ts#L44")[Vitepress]

== Server-side Rendering(SSR)

Vitepress 使用的是服务端构建，虽然官方文档中说要尽量区分客户端 js 代码和服务端 js 代码，但在实践中因为我之前压根没怎么接触过 Vue，所以对具体的实现方式一头雾水。在查阅大量资料之后，我的解决方案是，如果有只能在客户端执行的 js 代码（比如只有在浏览器中才存在的 `window` 对象），那我就把他放到 `onMounted` 方法中去。

例如在 Tags 组件中：

```vue
<script setup lang="ts">
import { useData } from "vitepress"
import { ref, computed, watchEffect, onMounted } from "vue"
import { getStorageTag, getPostsByTag } from "../helpers/tags.ts"
import { getStoragePage } from "../helpers/pagination.ts"

// 先设定默认值，可在服务端执行
const currentPage = ref(1)
const allPosts = useData().theme.value.posts
const currentTag = ref('')
const postsByTag = computed(() => getPostsByTag(currentTag.value))
const watchFun = ref(() => { })
const show = ref(false)

// 调用浏览器 API，只在客户端执行
onMounted(() => {
    currentPage.value = getStoragePage()
    currentTag.value = getStorageTag()

    watchEffect(() => {
        if (window.location.hash) {
            currentTag.value = window.location.hash.replace('#', '');
        }
    })

    show.value = true
})
</script>
```

这样就避免了构建过程中提示找不到对象的问题。

== Transition 动画在第一次载入页面时不生效

在构建成功后运行查看效果时，发现页面中加入的 `transition` 效果在清除缓存刷新页面时不起作用。后来经过#link("https://stackoverflow.com/questions/59627195/vue-js-transition-doesnt-apply-on-page-first-load")[查找资料]，我的解决方案是，在每个 `transition` 元素的子元素上增加 `v-if`，使其默认为 `false` 不显示，并在 `onMounted` 中将其设置为 `true` 显示：

```vue
<template>
  <transition appear enter-active-class="transition ease-out duration-300"
      enter-from-class="transform opacity-0 scale-95" enter-to-class="opacity-100 scale-100">
      <h1 v-if="show">Tags</h1>
  </transition>
</template>

<script setup lang="ts">
  const show = ref(false)
  onMounted(() => {
    show.value = true
  })
</script>
```

这样即使是第一次访问页面，动画效果也会存在。

= 下一步准备增加的功能

目前的功能只能说满足了基本的写作需求，但是类型还不够丰富，还是比较笼统。下一步准备实现更多功能：

1. *时间线* - 这个不用多说，就是仿 Facebook 时间线，给自己回顾的时候用。
2. *贡献热度图* - 就是 Github 贡献图的那个样子，打算自己用 svg 实现一个。
3. *微博* - 方便自己随便记录一些内容用，目前想法是给现有的文章增加一个新类别，结构和正常文章完全一致，后续有了新的想法再说。

= 给想拿来用的人

如果有人想尝试使用本主题，直接将 #link("https://github.com/dyzdyz010/vitepress-theme-oblivion")[vitepress-theme-oblivion] 的内容复制到自己的仓库里构建发布就可以。也可以参考本人的 Pages 仓库 #link("https://github.com/dyzdyz010/dyzdyz010.github.io")[dyzdyz010.github.io]。 有什么问题可以直接提 Issue。

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Wonderland 博客技术栈与复制部署指南",
  desc: [这篇文章记录本站的仓库结构和复制部署路径：Astro 负责站点，Typst 负责内容，Cloudflare 负责运行时，D1 只保存真正需要动态状态的数据。],
  date: "2026-06-25",
  tags: (
    blog-tags.blog,
    blog-tags.cloudflare,
    blog-tags.astro,
    blog-tags.typst,
    blog-tags.software,
  ),
  lang: "zh",
  i18nKey: "meta/2026/cloudflare-d1-typst-astro-blog-stack",
  sourceLang: "zh",
  aiAuthored: true,
)

我现在这套博客可以用一句话概括：*Astro 组织网站，Typst 写文章和生成内容，Cloudflare 承载运行时，D1 只存评论这类动态数据。*

这篇文章不是从零搭一个 Astro 博客的教程。更准确地说，它是 Wonderland 这个仓库的结构说明和复制部署指南：如果你喜欢这套形态，最省事的方式不是重新敲一遍依赖，而是复制这个仓库，改掉站点身份、Cloudflare 绑定、D1 数据库和 PDF artifact 配置，然后按项目已有脚本验证和部署。

下面的配置和命令都来自本站当前仓库；代码片段是为了说明而删减过的核心形状，不是完整文件逐字复制。

= 这套站点从哪里来

Wonderland 不是一个完全从空目录长出来的项目。站点的代码基础来自 #link("https://github.com/Myriad-Dreamin/tylant")[Myriad-Dreamin/tylant]，我当时复制了 Tylant 项目的基础代码，然后逐步改造成现在这套个人博客。

这也是为什么 Typst 在这个仓库里不是一个“附加小功能”。它从一开始就参与了内容模型和模板体系：文章源文件是 `.typ`，模板放在 `templates/`，Astro 通过 `astro-typst` 在构建时把 Typst 内容渲染成 HTML，PDF 则通过单独脚本生成并发布为 artifact。

= 技术栈分工

== Astro：站点编排层

Astro 负责路由、布局、内容集合、RSS、站点地图，以及把 Typst 渲染结果接进页面。本站使用 `output: "server"` 和 `@astrojs/cloudflare`，所以同一个仓库里可以同时存在：

- 预渲染文章页、列表页、标签页、归档页；
- 需要 Worker 运行时的 API 路由；
- 通过 Cloudflare adapter 生成的 Worker 入口和静态资源目录。

关键依赖可以在 `package.json` 里看到：

```json
{
  "@astrojs/cloudflare": "^12.6.6",
  "@astrojs/rss": "^4.0.12",
  "@astrojs/sitemap": "^3.5.0",
  "astro": "^5.13.2",
  "astro-typst": "^0.11.2",
  "@myriaddreamin/typst-ts-node-compiler": "^0.6.1-rc2",
  "drizzle-orm": "^0.44.5",
  "wrangler": "^4.33.1"
}
```

复制仓库部署时，不需要手动 `bun add` 这些依赖；直接 `bun install` 即可。

== Typst：内容和排版层

本站文章不是 Markdown，而是 `.typ` 文件。每篇文章都导入同一套模板和标签枚举：

```typst
#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "文章标题",
  desc: [文章摘要],
  date: "2026-06-25",
  tags: (
    blog-tags.blog,
    blog-tags.typst,
  ),
  lang: "zh",
  i18nKey: "meta/2026/example",
  sourceLang: "zh",
)
```

这套 Typst 写作方式的来源是 Tylant。复制仓库时，真正需要保留和理解的是这些边界：

- `content/article/`：文章源码，按语言和分类存放；
- `templates/blog.typ`：文章 HTML 渲染入口；
- `templates/enums.typ`：标签注册表；
- `templates/article-pdf.typ` 和 `templates/archive.typ`：PDF 导出模板；
- `packages/mathyml/`：本地 Typst 包，用于数学内容相关渲染；
- `assets/fonts/noto-cjk-sc/`：PDF 使用的 Noto CJK 字体，走 Git LFS 管理。

元数据仍然能被 Astro 内容集合读取。本站用 `src/content.config.ts` 约束 `title`、`date`、`tags`、`lang`、`i18nKey`、`translationStatus` 等字段，避免文章列表、RSS、归档和语言切换各维护一份事实。

== Cloudflare：部署和运行时层

本站不是把 Astro 输出成一堆纯静态文件后就结束。`astro.config.mjs` 里的核心形状是：

```js
export default defineConfig({
  site: "https://dyz.io",
  output: "server",
  integrations: [
    typst({ target: "html" }),
    sitemap(),
  ],
  adapter: cloudflare({
    platformProxy: {
      enabled: true,
    },
  }),
});
```

`output: "server"` 让 Astro 生成 Cloudflare Worker 入口；页面仍然可以通过 `export const prerender = true` 预渲染。本站文章详情页就是预渲染的，而评论组件和提交接口才是运行时。

配套的 `wrangler.toml` 至少需要 Worker 名字、静态资源绑定和 D1 绑定：

```toml
name = "wonderland"
compatibility_date = "2025-04-28"
compatibility_flags = ["nodejs_compat"]
main = "dist/_worker.js/index.js"

[assets]
directory = "./dist"
binding = "ASSETS"

[[d1_databases]]
binding = "DB"
database_name = "wonderland"
database_id = "替换成你自己的 D1 database_id"
```

其中 `[assets]` 很重要。Cloudflare adapter 生成的 Worker 会通过 `env.ASSETS.fetch(...)` 处理静态资源和兜底请求；如果没有绑定，部署后可能不是内容错了，而是 Worker 根本拿不到静态资源。

== D1：只保存动态状态

我的原则是：文章不要进 D1。文章、页面、归档、标签和翻译文件都应该进 Git，由构建系统生成。D1 只负责那些真的需要运行时状态的东西，例如评论。

本站的 D1 绑定名是 `DB`，评论模块使用 `drizzle-orm/d1`。迁移文件在 `migrations/` 下，目前包括：

- `0001_init.sql`：创建原始 `comments` 表；
- `0002_harden_comments.sql`：增加 `thread_key`、`status`、`email_hash`、`user_agent_hash`、`updated_at` 和索引。

评论现在是直接写入 `approved` 状态；`status` 字段主要是为后续审核、垃圾评论处理和删除状态预留。

= 仓库结构应该先看哪里

复制这个仓库前，建议先按职责看目录，而不是从某个框架教程开始看。

```text
content/article/              # 文章源码，zh/en 双语按 i18nKey 对齐
content/page/                 # about 等页面源码
templates/                    # Typst HTML/PDF 模板和标签枚举
src/content.config.ts         # Astro content collection schema
src/i18n/                     # 语言、路由、文案和内容选择逻辑
src/layouts/BlogPost.astro    # 文章详情页外壳，挂评论和 PDF 链接
src/components/comment/       # 评论 UI
src/features/comments/        # D1 schema、读写和表单校验
src/pages/api/comments/       # 评论提交 API
migrations/                   # D1 schema 迁移
scripts/d1-reset-local.mjs    # 本地 D1 reset helper
scripts/pdf/                  # PDF version、generate、publish、fetch
assets/fonts/noto-cjk-sc/     # PDF 字体，Git LFS 管理
astro.config.mjs              # Astro + Cloudflare adapter 配置
wrangler.toml                 # Cloudflare Worker、assets、D1 绑定
package.json                  # 统一脚本入口
```

这里最重要的是边界：`content/` 和 `templates/` 是内容源；`src/pages/` 决定哪些页面预渲染、哪些接口运行时执行；`src/features/comments/` 封装 D1；`scripts/pdf/` 把重型 PDF 生成从 Cloudflare 构建里拆出去。

= 复制一份仓库后要改什么

假设你已经 fork 或复制了仓库，可以按这个顺序改。

== 1. 克隆并拉取 LFS 字体

```bash
git clone https://github.com/<your-name>/<your-repo>.git
cd <your-repo>
git lfs install
git lfs pull
bun install
```

`git lfs pull` 不能省。PDF 生成依赖 `assets/fonts/noto-cjk-sc/` 下的 Noto CJK 字体；如果只拿到 Git LFS 指针文件，`pdf:generate` 会明确报错。

== 2. 修改站点身份

至少检查这些文件：

```text
astro.config.mjs          # site: "https://你的域名"
src/consts.ts             # SITE_TITLE / SITE_AUTHOR / SITE_DESCRIPTION
src/i18n/messages.ts      # 中英文站点描述和 UI 文案
content/page/zh/about.typ # 关于页中文说明
content/page/en/about.typ # 关于页英文说明
scripts/pdf/lib.mjs       # siteAuthor / siteUrl，用于 PDF 元数据和源链接
```

如果你只是复制部署测试，可以先只改域名和作者；如果要长期维护，关于页、RSS 文案和 PDF 元数据也应该一起改，否则生成出来的 HTML、RSS 或 PDF 里仍然会出现原站信息。

== 3. 修改 Cloudflare 配置

`wrangler.toml` 里至少要改：

```toml
name = "你的 worker 名字"
account_id = "你的 Cloudflare account_id"

[[d1_databases]]
binding = "DB"
database_name = "你的 D1 数据库名"
database_id = "你的 D1 database_id"
```

`binding = "DB"` 建议不要改，除非你也同步修改代码里读取 `Astro.locals.runtime?.env.DB` 的地方。

创建 D1 数据库：

```bash
bunx wrangler login
bunx wrangler d1 create <你的 D1 数据库名>
```

把输出里的 `database_id` 填回 `wrangler.toml`。

== 4. 初始化本地和远程 D1

本地开发可以直接用项目脚本：

```bash
bun run db:reset
```

生产库迁移要显式加 remote，项目里也有脚本封装：

```bash
bun run db:migrate:remote
```

或者使用等价的 Wrangler 命令：

```bash
bunx wrangler d1 migrations apply <你的 D1 数据库名> --remote
```

不要把 `DROP TABLE` 写进生产迁移里。需要本地清库时，用 `scripts/d1-reset-local.mjs` 这种名字明确的本地脚本。

== 5. 配置评论和 Turnstile

评论区读取 `Astro.locals.runtime?.env.DB`，通过 Drizzle 查询 D1。如果 D1 不可用，评论列表显示“Comments are temporarily unavailable.”，而不是让整篇文章崩掉。

Turnstile 是可选增强。本站逻辑是：

- 有 `TURNSTILE_SITE_KEY` 时，前端渲染 Turnstile widget；
- 有 `TURNSTILE_SECRET_KEY` 时，服务端验证 `cf-turnstile-response`。

生产环境要么两个都配，要么两个都不配。只配 secret 会导致前端没有 token、提交失败；只配 site key 则只是显示组件，服务端不会验证。

secret 可以这样配：

```bash
bunx wrangler secret put TURNSTILE_SECRET_KEY
```

`TURNSTILE_SITE_KEY` 不是秘密，可以放在 Cloudflare dashboard 的变量里，或按你的部署流程注入。

= 本地验证流程

复制和修改完成后，先跑内容检查：

```bash
bun run validate
bun run i18n:check:strict
```

再验证 HTML 和 Worker 产物：

```bash
bun run build:site
```

如果你需要 PDF，也要验证 PDF artifact：

```bash
bun run pdf:generate
```

完整生产构建是：

```bash
bun run build
```

本站的 `build` 实际上是：

```bash
astro build && node scripts/pdf/fetch.mjs
```

也就是说 HTML 由 Astro 构建，PDF 文件通过单独的 artifact 流程取回。这是为了避免 Cloudflare 构建时直接编译大量 Typst PDF：HTML 渲染可以进入正常构建，重型 PDF 生成更适合放在本地或单独 CI 里。

= PDF artifact 和 GitHub Release

这个仓库的 PDF 发布流程和 GitHub remote 有关。`scripts/pdf/lib.mjs` 会优先读取 `PDF_ARTIFACT_REPO`，否则从 `git remote get-url origin` 推断 GitHub 仓库，最后才回退到 `dyzdyz010/wonderland`。

所以复制仓库后，要么把 `origin` 指向你自己的 GitHub 仓库，要么显式设置：

```bash
export PDF_ARTIFACT_REPO=<your-name>/<your-repo>
```

生成并发布 PDF artifact：

```bash
bun run pdf:prepare
```

它等价于：

```bash
bun run pdf:generate
bun run pdf:publish
```

`pdf:publish` 使用 GitHub CLI 的 `gh release`，所以执行它的机器需要登录 GitHub，并且对目标仓库有 release 上传权限。

这里有一个很重要的前置条件：只要文章、PDF 模板、PDF 脚本或依赖锁文件变化，PDF version hash 就可能变化。`bun run build` 里的 `pdf:fetch` 会去找当前 hash 对应的 tarball；如果 GitHub Release 里还没有这个 artifact，它会报 404。此时不是 Astro 或 Cloudflare 配置错了，而是需要先生成并发布 PDF artifact。

= 部署到 Cloudflare

第一次部署前：

```bash
bunx wrangler login
bunx wrangler d1 create <你的 D1 数据库名>
bun run db:migrate:remote
```

部署前先确保 PDF artifact 已发布：

```bash
bun run pdf:prepare
```

然后构建并部署 Worker：

```bash
bun run build
bunx wrangler deploy
```

本站当前按 Workers + Static Assets + `wrangler deploy` 配置。如果你改用 Cloudflare Pages 的 Git 集成，需要在 Pages 项目里重新配置 D1 绑定和环境变量，并确保构建环境能下载已经发布的 PDF artifact；不要假设本文的 `wrangler.toml` 可以原样迁移。

= 部署后一定要验证什么

只看到首页能打开还不够。至少检查：

- 首页、文章页、标签页是否返回 200；
- 文章详情页 HTML 是否有正确标题、描述、语言切换和 canonical/hreflang；
- 评论 server island 是否真的能加载，而不是只在主 HTML 里留下一个占位；
- 评论提交失败时是否优雅降级；
- 随机打开一篇文章 PDF 和一个归档 PDF；
- D1 远程迁移是否已经应用到生产数据库。

尤其要注意评论。Astro 的主文章 HTML 可以是 200，但 server island 里的评论区仍然可能因为 D1 绑定、迁移或 Turnstile 配置错误而失败。所以评论区要单独看。

= 容易踩坑的地方

== 忘记改 PDF 元数据

`astro.config.mjs` 的 `site` 只影响 Astro 站点。PDF 的 `siteAuthor` 和 `siteUrl` 目前在 `scripts/pdf/lib.mjs` 里也有一份。复制仓库后如果只改 Astro 配置，PDF 里仍然可能出现原站作者或原站链接。

== 忘记 Git LFS 字体

PDF 生成依赖 `assets/fonts/noto-cjk-sc/`。如果新机器只 clone 了 LFS pointer，没有拉取字体，`bun run pdf:generate` 会失败。先跑：

```bash
git lfs pull
```

== 把所有东西都运行时化

这个栈的优势不是“什么都动态”，而是“动态边界足够小”。文章和归档越静态，Cloudflare Worker 的负担越小，部署越稳定，SEO 越简单。

== 在 Cloudflare runtime 里跑原生 Typst PDF 编译

Typst HTML 渲染和 Astro 构建可以发生在构建阶段。大量 PDF 生成最好不要塞进 Cloudflare 构建或 Worker runtime。本站用 artifact 流程把 PDF 从正常站点构建里分离出来，只在 `build` 末尾取回已经发布的 PDF。

如果 `astro build` 已经成功，但 `bun run build` 最后在 `pdf:fetch` 报 404，通常不是 Astro 或 Cloudflare adapter 配置错了，而是当前 PDF version 的 artifact 还没有发布。先运行 `bun run pdf:prepare`，或在只验证站点 HTML 时改用 `bun run build:site`。

== 忘记 `[assets]` 绑定

`@astrojs/cloudflare` 生成的 Worker 需要访问静态资源。`wrangler.toml` 里缺少：

```toml
[assets]
directory = "./dist"
binding = "ASSETS"
```

会导致一些路径在生产环境里以很奇怪的方式失败。

= 复制部署清单

最后整理成一份最小清单：

1. Fork 或复制 `dyzdyz010/wonderland` 到你自己的 GitHub 仓库。
2. `git clone` 后执行 `git lfs pull` 和 `bun install`。
3. 修改 `astro.config.mjs`、`src/consts.ts`、`src/i18n/messages.ts`、关于页和 `scripts/pdf/lib.mjs` 里的站点身份。
4. 在 Cloudflare 创建 D1 数据库，并把 `database_id` 写入 `wrangler.toml`。
5. 保持 D1 binding 为 `DB`，或同步修改代码里的 `env.DB`。
6. 本地跑 `bun run validate`、`bun run i18n:check:strict`、`bun run db:reset`、`bun run build:site`。
7. 需要 PDF 时跑 `bun run pdf:generate`；部署前跑 `bun run pdf:prepare` 发布 artifact。
8. 生产执行 `bun run db:migrate:remote`。
9. 最后跑 `bun run build` 和 `bunx wrangler deploy`。
10. 部署后验证文章页、评论区、D1、PDF 链接和 RSS/站点地图。

这套架构的关键不是某个库，而是边界：*内容是源码，页面尽量静态，Cloudflare 承载运行时，D1 只保存动态状态。* 复制仓库时也要按这个边界去改，别把内容、运行时数据、部署配置和 PDF artifact 混在一起。

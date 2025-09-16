#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "使用Cloudflare D1与Astro为博客添加评论功能",
  desc: [使用Cloudflare D1与Astro为博客添加评论功能],
  date: "2025-08-30",
  tags: (
    blog-tags.programming,
    blog-tags.cloudflare,
    blog-tags.astro,
    blog-tags.blog
  ),
)

自从博客部署到Cloudflare后，我就一直在寻找一个合适的评论系统。自我建立博客网站一开始，我的博客使用的是Disqus，但是Disqus在国内访问速度很慢，而且有时候还会被墙，所以我就放弃了。

后来了解了#link("https://valine.js.org/")[Valine]，一直想要尝试一下，但因为太懒了没有尝试。

直到最近，我了解到了Cloudflare D1，以及Astro的Drizzle ORM，所以我就想要尝试一下，为我的博客添加评论功能。

= 技术栈

- Cloudflare D1
- Astro
- Drizzle ORM
- Bun

= 实现步骤

== 创建数据库以及表

在项目中可以通过wrangler命令行工具创建数据库以及表。

```bash
bunx wrangler d1 create wonderland
```

然后我在项目中放置了`migrations/0001_init.sql`数据库迁移脚本。

```sql
DROP TABLE IF EXISTS comments;
CREATE TABLE
    IF NOT EXISTS comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_slug TEXT NOT NULL, -- 文章唯一标识/slug
        author_name TEXT NOT NULL,
        author_email TEXT NOT NULL,
        author_url TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (unixepoch ()),
        parent_id INTEGER,
        ip_hash TEXT
    );

CREATE INDEX IF NOT EXISTS idx_comments_post_created ON comments (post_slug, created_at DESC);

INSERT INTO comments (post_slug, author_name, author_email, author_url, content) VALUES ('test-slug', 'John Doe', 'john.doe@example.com', 'https://example.com', 'This is a test comment');
INSERT INTO comments (post_slug, author_name, author_email, author_url, content) VALUES ('test-slug', 'John Doe', 'john.doe@example.com', 'https://example.com', 'This is a test comment');
```

然后通过`wrangler d1 execute`命令执行数据库迁移脚本。

```bash
bunx wrangler d1 execute wonderland --local --file=./migrations/0001_init.sql
```

_D1_是一个非常神奇的数据库，它的命令可以分 _本地_ 和 _远程_ 执行，只需要在命令中添加`--local/--remote`参数即可，这大大方便了开发和调试，意味着你本地可以随便折腾，不用担心对生产环境造成影响。

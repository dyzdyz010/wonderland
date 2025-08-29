#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Hello",
  desc: [My new blog debut, with a new theme and a new look.],
  date: "2025-08-24",
  tags: (
    blog-tags.life,
    blog-tags.typst,
  ),
)
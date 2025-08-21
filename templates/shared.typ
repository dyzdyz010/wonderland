#import "@preview/shiroa:0.2.3": plain-text

#let shared-template(
  title: "Untitled",
  desc: [This is a blog post.],
  date: "2024-08-15",
  tags: (),
  collection: "SomeCollection",
  kind: "post",
  lang: none,
  region: none,
  show-outline: true,
  body,
) = {
  [#metadata((
    title: plain-text(title),
    author: "Myriad-Dreamin",
    description: plain-text(desc),
    date: date,
    tags: tags,
    lang: lang,
    region: region,
  )) <frontmatter>]

  body
}

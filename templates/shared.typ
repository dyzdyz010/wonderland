#import "@preview/shiroa:0.2.3": book-sys, is-html-target, is-pdf-target, is-web-target, plain-text, templates
#import templates: *
#import "mod.typ": static-heading-link
#import "code/rule.typ": code-block-rules, is-dark-theme, dash-color
#import "code/theme.typ": sys-is-html-target

#let is-html-target = is-html-target()
#let is-pdf-target = is-pdf-target()
#let is-web-target = is-web-target() or sys-is-html-target
#let sys-is-html-target = ("target" in dictionary(std))

#let text-fonts = (
  "Libertinus Serif",
  // todo: exclude it if language is not Chinese.
  "Noto Sans SC",
)

// Sizes
#let main-size = if sys-is-html-target {
  16pt
} else {
  10.5pt
}
// ,
#let heading-sizes = (22pt, 18pt, 14pt, 12pt, main-size)
#let list-indent = 0.5em


#let markup-rules(body, lang: none, region: none) = {
  set text(lang: lang) if lang != none
  set text(region: region) if region != none
  set text(font: text-fonts)

  set text(main-size) if sys-is-html-target
  set text(fill: rgb("dfdfd6")) if is-dark-theme and sys-is-html-target
  show link: set text(fill: dash-color)

  show heading: it => {
    set text(size: heading-sizes.at(it.level))

    block(
      spacing: 0.7em * 1.5 * 1.2,
      below: 0.7em * 1.2,
      {
        if is-web-target {
          show link: static-heading-link(it)
          heading-hash(it, hash-color: dash-color)
        }

        it
      },
    )
  }
  
  body
}

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
  show: it => {
    show: markup-rules.with(
      lang: lang,
      region: region,
    )

    show: code-block-rules

    set par(justify: true)

    it
  }

  [#metadata((
    title: plain-text(title),
    author: "Myriad-Dreamin",
    description: plain-text(desc),
    date: date,
    tags: tags,
    lang: lang,
    region: region,
  )) <frontmatter>]

  context if show-outline {
    if query(heading).len() == 0 {
      return
    }

    let outline-counter = counter("html-outline")
    outline-counter.update(0)
    show outline.entry: it => html.elem(
      "div",
      attrs: (
        class: "outline-item x-heading-" + str(it.level),
      ),
      {
        outline-counter.step(level: it.level)
        static-heading-link(it.element, body: [#sym.section#context outline-counter.display("1.") #it.element.body])
      },
    )
    html.elem(
      "div",
      attrs: (
        class: "toc",
      ),
      outline(title: none),
    )
    html.elem("hr")
  }

  body
}

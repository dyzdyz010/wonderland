#import "@preview/shiroa:0.2.3": book-sys, is-html-target, is-pdf-target, is-web-target, plain-text, templates
#import templates: *
#import "@preview/zebraw:0.5.5": zebraw, zebraw-init
#import "mod.typ": static-heading-link

#let is-html-target = is-html-target()
#let is-pdf-target = is-pdf-target()
#let is-web-target = is-web-target() or book-sys.is-html-target
// #let is-md-target = target == "md"
#let sys-is-html-target = ("target" in dictionary(std))

#let text-fonts = (
  "Libertinus Serif",
  // todo: exclude it if language is not Chinese.
  "Noto Sans SC",
)

#let code-font = (
  "DejaVu Sans Mono",
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


#let code-block-rules(body) = {
  let init-with-theme((code-extra-colors, is-dark)) = if is-dark {
    zebraw-init.with(
      // should vary by theme
      background-color: if code-extra-colors.bg != none {
        (code-extra-colors.bg, code-extra-colors.bg)
      },
      highlight-color: rgb("#3d59a1"),
      comment-color: rgb("#394b70"),
      lang-color: rgb("#3d59a1"),
      lang: false,
      numbering: false,
    )
  } else {
    zebraw-init.with(
      // should vary by theme
      background-color: if code-extra-colors.bg != none {
        (code-extra-colors.bg, code-extra-colors.bg)
      },
      lang: false,
      numbering: false,
    )
  }

  /// HTML code block supported by zebraw.
  show: init-with-theme((
    code-extra-colors: (
      bg: rgb("f0f0f0"),
      fg: black,
    ),
    is-dark: false,
  ))


  // let mk-raw(
  //   it,
  //   tag: "div",
  //   inline: false,
  // ) = theme-frame(
  //   tag: tag,
  //   theme => {
  //     show: init-with-theme(theme)
  //     let code-extra-colors = theme.code-extra-colors
  //     let use-fg = not inline and code-extra-colors.fg != none
  //     set text(fill: code-extra-colors.fg) if use-fg
  //     set text(fill: if theme.is-dark { rgb("dfdfd6") } else { black }) if not use-fg
  //     set raw(theme: theme-style.code-theme) if theme.style.code-theme.len() > 0
  //     set par(justify: false)
  //     zebraw(
  //       block-width: 100%,
  //       // line-width: 100%,
  //       wrap: false,
  //       it,
  //     )
  //   },
  // )

  show raw: set text(font: code-font)
  // show raw.where(block: false): it => context if shiroa-sys-target() == "paged" {
  //   it
  // } else {
  //   mk-raw(it, tag: "span", inline: true)
  // }
  // show raw.where(block: true): it => context if shiroa-sys-target() == "paged" {
  //   set raw(theme: theme-style.code-theme) if theme-style.code-theme.len() > 0
  //   rect(
  //     width: 100%,
  //     inset: (x: 4pt, y: 5pt),
  //     radius: 4pt,
  //     fill: code-extra-colors.bg,
  //     [
  //       #set text(fill: code-extra-colors.fg) if code-extra-colors.fg != none
  //       #set par(justify: false)
  //       // #place(right, text(luma(110), it.lang))
  //       #it
  //     ],
  //   )
  // } else {
  //   mk-raw(it)
  // }
  body
}

#let markup-rules(body, lang: none, region: none) = {
  set text(lang: lang) if lang != none
  set text(region: region) if region != none
  set text(font: text-fonts)

  set text(main-size) if sys-is-html-target
  // set text(fill: rgb("dfdfd6")) if is-dark-theme and sys-is-html-target
  // show link: set text(fill: dash-color)

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

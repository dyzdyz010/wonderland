#import "@preview/shiroa:0.2.3": book-sys, is-html-target, is-pdf-target, is-web-target, plain-text, templates
#import templates: *
#import "mod.typ": static-heading-link
#import "code/rule.typ": code-block-rules, is-dark-theme, dash-color
#import "code/theme.typ": sys-is-html-target, theme-frame

#let is-html-target = is-html-target()
#let is-pdf-target = is-pdf-target()
#let is-web-target = is-web-target() or sys-is-html-target
#let sys-is-html-target = ("target" in dictionary(std))

#let text-fonts = (
  "Libertinus Serif",
  // todo: exclude it if language is not Chinese.
  "PingFang SC",
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

#let div-frame(content, attrs: (:), tag: "div") = html.elem(tag, html.frame(content), attrs: attrs)
#let span-frame = div-frame.with(tag: "span")
#let p-frame = div-frame.with(tag: "p")


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

#let mathyml-equation-rules(body) = {
  import "../packages/mathyml/src/lib.typ": try-to-mathml

  // math rules
  show math.equation: set text(weight: 500)
  // show math.equation: to-mathml
  show math.equation: try-to-mathml


  body
}

#let equation-rules(body) = {
  show math.equation: set text(weight: 400)
  show math.equation.where(block: true): it => context if shiroa-sys-target() == "html" {
    theme-frame(
      tag: "div",
      theme => {
        set text(fill: theme.main-color)
        p-frame(attrs: ("class": "block-equation", "role": "math"), it)
      },
    )
  } else {
    it
  }
  show math.equation.where(block: false): it => context if shiroa-sys-target() == "html" {
    theme-frame(
      tag: "span",
      theme => {
        set text(fill: theme.main-color)
        span-frame(attrs: (class: "inline-equation"), it)
      },
    )
  } else {
    it
  }
  body
}

#let visual-rules(body) = {
  let url-base = "/"
  // Resolves the path to the image source
  let resolve(path) = (
    path.replace(
      // Substitutes the paths with some assumption.
      // In the astro sites, the assets are store in `public/` directory.
      regex("^[./]*/public/"),
      url-base,
    )
  )

  show image: it => context if shiroa-sys-target() == "paged" {
    it
  } else {
    html.elem("img", attrs: (src: resolve(it.source)))
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

    show: mathyml-equation-rules
    // show: equation-rules
    show: code-block-rules
    show: visual-rules

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

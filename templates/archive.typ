#import "@preview/shiroa:0.3.1": plain-text
#import "target.typ": sys-is-html-target

#let main(
  title: "Archive",
  desc: [],
  date: "2025-01-01",
  tags: ("Archive",),
  articles: (),
  body,
) = {
  let description = if type(desc) == content { plain-text(desc) } else { desc }
  [#metadata((title: title, description: description, date: date, tags: tags)) <frontmatter>]

  if not sys-is-html-target {
    set document(title: title, date: none)
    set page(
      paper: "a4",
      numbering: none,
      number-align: center,
      margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
    )
    set text(font: ("Libertinus Serif", "PingFang SC"), size: 10.5pt)
    set heading(numbering: none)
    set par(justify: true)

    // Style article title headings (level 1)
    show heading.where(level: 1): it => {
      pagebreak(weak: true)
      v(4em)
      align(center, text(24pt, weight: "bold", it.body))
      v(0.5em)
    }

    // Cover page
    align(center + horizon)[
      #text(36pt, weight: "bold")[#title]
      #v(2em)
      #text(13pt, fill: luma(80))[#desc]
    ]

    // Table of contents
    pagebreak()
    outline(title: [#text(18pt)[目录]], depth: 2, indent: 1.5em)

    // Switch to numbered pages for articles
    set page(numbering: "1")
    counter(page).update(1)

    // Articles
    for article in articles {
      heading(level: 1)[#article.at("title")]
      align(center)[
        #text(11pt, fill: luma(120))[#article.at("date")]
      ]
      v(2em)
      {
        set heading(offset: 1)
        include article.at("path")
      }
    }
  }
}

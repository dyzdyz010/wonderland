#import "@preview/shiroa:0.3.1": plain-text
#import "target.typ": sys-is-html-target
#import "pdf/typography.typ": *

#let main(
  title: "Archive",
  desc: [],
  date: "2025-01-01",
  author: "dyzdyz010",
  tags: ("Archive",),
  articles: (),
  body,
) = {
  let description = if type(desc) == content { plain-text(desc) } else { desc }
  let copyright-notice = "© " + author + ". All rights reserved unless otherwise noted."
  [#metadata((title: title, author: author, description: description, date: date, tags: tags, count: articles.len(), copyright: copyright-notice)) <frontmatter>]

  if not sys-is-html-target {
    set document(title: title, author: author, date: none)
    set page(
      paper: "a4",
      numbering: none,
      number-align: center,
      margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
      footer: align(center)[#pdf-ui-text(size: 7.5pt)[© #author]],
    )
    set text(font: pdf-body-fonts, size: 10.5pt)
    set heading(numbering: none)
    set par(justify: true)

    // Style article title headings (level 1)
    show heading.where(level: 1): it => {
      pagebreak(weak: true)
      v(4em)
      align(center, pdf-heading-text(size: 24pt, weight: "bold")[#it.body])
      v(0.5em)
    }

    // Cover page
    align(center + horizon)[
      #pdf-heading-text(size: 36pt, weight: "bold")[#title]
      #v(2em)
      #pdf-body-text(size: 13pt, fill: luma(80))[#desc]
      #v(2em)
      #pdf-ui-text(size: 9pt)[#copyright-notice]
    ]

    // Table of contents
    pagebreak()
    outline(title: [#pdf-heading-text(size: 18pt)[目录]], depth: 2, indent: 1.5em)

    // Switch to numbered pages for articles
    set page(numbering: "1")
    counter(page).update(1)

    // Articles
    for article in articles {
      heading(level: 1)[#article.at("title")]
      align(center)[
        #pdf-ui-text(size: 11pt)[#article.at("date")]
      ]
      v(2em)
      {
        set heading(offset: 1)
        include article.at("path")
      }
    }
  }
}

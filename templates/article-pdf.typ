#import "@preview/shiroa:0.3.1": plain-text

#let accent = rgb("1f4f82")
#let accent-soft = rgb("eef5fb")
#let ink = rgb("172033")
#let muted = rgb("657083")
#let rule = rgb("d7dce3")
#let paper-tint = rgb("fbfcfe")

#let stringify(value) = if type(value) == content { plain-text(value) } else { value }

#let metadata-row(label, value) = grid(
  columns: (3.1cm, 1fr),
  column-gutter: 1em,
  row-gutter: 0.4em,
  text(8.5pt, fill: muted, weight: "semibold")[#label],
  text(9pt, fill: ink)[#value],
)

#let render-tags(tags) = {
  if tags.len() == 0 {
    text(8.5pt, fill: muted)[No tags]
  } else {
    for tag in tags {
      box(
        inset: (x: 0.55em, y: 0.24em),
        radius: 4pt,
        fill: accent-soft,
        stroke: 0.45pt + rule,
      )[
        #text(8pt, fill: accent, weight: "medium")[#tag]
      ]
      h(0.35em)
    }
  }
}

#let main(
  title: "Untitled",
  desc: [],
  date: "2024-01-01",
  updated_date: none,
  author: "Myriad-Dreamin",
  source_url: "https://dyz.io/",
  tags: (),
  copyright_notice: none,
  body,
) = {
  let description = stringify(desc)
  let notice = if copyright_notice == none {
    "© " + author + ". Original article and authorship information preserved from the source page. All rights reserved unless otherwise noted."
  } else {
    copyright_notice
  }

  [#metadata((
    title: title,
    author: author,
    description: description,
    date: date,
    updatedDate: updated_date,
    tags: tags,
    source: source_url,
    copyright: notice,
  )) <frontmatter>]

  set document(title: title, author: author, date: none)
  set text(font: ("Libertinus Serif", "PingFang SC"), size: 10.5pt, fill: ink)
  set par(justify: true, leading: 0.62em)
  set page(
    paper: "a4",
    margin: (top: 2.2cm, bottom: 2.2cm, left: 2.35cm, right: 2.35cm),
    numbering: none,
    fill: paper-tint,
  )

  // Cover page: intentionally not a heading, so the generated outline only
  // reflects the article body.
  block(width: 100%, height: 100%)[
    #v(1.2cm)
    #rect(width: 3.2cm, height: 2.2pt, fill: accent)
    #v(1.15cm)
    #text(28pt, weight: "bold", fill: ink)[#title]
    #v(0.75cm)
    #block(width: 88%)[
      #text(12pt, fill: muted)[#description]
    ]
    #v(1.2cm)
    #box(
      width: 100%,
      inset: 1em,
      radius: 8pt,
      fill: white,
      stroke: 0.55pt + rule,
    )[
      #metadata-row("Author", author)
      #v(0.42em)
      #metadata-row("Published", date)
      #if updated_date != none {
        v(0.42em)
        metadata-row("Updated", updated_date)
      }
      #v(0.42em)
      #metadata-row("Source", link(source_url)[#source_url])
      #v(0.55em)
      #grid(
        columns: (3.1cm, 1fr),
        column-gutter: 1em,
        text(8.5pt, fill: muted, weight: "semibold")[Tags],
        render-tags(tags),
      )
    ]
    #v(1fr)
    #block(width: 100%, inset: (top: 0.85em), stroke: (top: 0.55pt + rule))[
      #text(8.3pt, fill: muted)[#notice]
    ]
  ]

  context if query(heading).len() > 0 {
    pagebreak()
    v(1.2cm)
    text(18pt, weight: "semibold", fill: ink)[Contents]
    v(0.7em)
    outline(title: none, depth: 2, indent: 1.5em)
  }

  pagebreak()
  set page(
    paper: "a4",
    margin: (top: 2cm, bottom: 2.15cm, left: 2.35cm, right: 2.35cm),
    numbering: "1",
    fill: white,
    header: align(right)[
      #text(7.5pt, fill: muted)[#title]
    ],
    footer: context align(center)[
      #text(7.5pt, fill: muted)[© #author · #counter(page).display("1")]
    ],
  )
  counter(page).update(1)

  show link: set text(fill: accent)
  show figure.caption: set text(size: 8.8pt, fill: muted)

  body
}

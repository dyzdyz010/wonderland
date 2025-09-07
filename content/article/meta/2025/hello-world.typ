#import "/templates/blog.typ": *
#import "/templates/enums.typ": *
#import "@preview/pintorita:0.1.4"
#import "/templates/mod.typ": typ_frame

#show raw.where(lang: "pintora"): it => pintorita.render(it.text)

#show: main.with(
  title: "Hello",
  desc: [My new blog debut, with a new theme and a new look.],
  date: "2025-08-24",
  tags: (
    blog-tags.life,
    blog-tags.typst,
  ),
)

= Hello World!

这是一篇测试用文章，用来测试评论功能。

// #html.elem("div", attrs: (class: "pintora-diagram flex justify-center"))[
//   #html.frame[
//     #import "@preview/chronos:0.2.1"
//     #align(center)[
//       #chronos.diagram({
//         import chronos: *
//         _par("Alice", color: red)
//         _par("Bob", color: blue)

//         _seq("Alice", "Bob", comment: "Hello", color: green)
//       })
//     ]
//   ]
// ]

#figure(caption: "Sequence Diagram Example", kind: image)[
  #typ_frame("pintora-diagram flex justify-center")[
    #show raw.where(lang: "pintora"): it => pintorita.render(it.text, style: "dark")
    ```pintora
    sequenceDiagram
    autonumber
    participant [<actor> User]
    User->>Pintora: Draw me a sequence diagram（with DSL）
    activate Pintora
    Pintora->>Pintora: Parse DSL, draw diagram
    alt DSL is correct
      Pintora->>User: Return the drawn diagram
    else DSL is incorrect
      Pintora->>User: Return error message
    end
    deactivate Pintora
    @start_note left of Pintora
    Different output formats according to render targets
    1. In browser side. output SVG or Canvas
    2. In Node.js side. output PNG file
    @end_note
    ```
  ]
]

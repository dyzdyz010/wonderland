#import "/templates/blog.typ": *
#import "/templates/enums.typ": *
#import "@preview/kouhu:0.2.0": kouhu

#show: main.with(
  title: "Typst Syntax",
  desc: [List of Typst Syntax, for rendering tests.],
  date: "2025-05-27",
  tags: (
    blog-tags.programming,
    blog-tags.typst,
  ),
)

= Raw Blocks

#quote(block: true)[
  This is an inline raw block `class T`.
]

== Examples

=== Inline Raw Blocks

==== Block Definition

This is an inline raw block `class T`.

This is an inline raw block ```js class T```.

This is a long inline raw block ```js class T {}; class T {}; class T {}; class T {}; class T {}; class T {}; class T {}; class T {}; class T {};```.

Js syntax highlight are handled by syntect:

```js
class T {};
```

Typst syntax hightlight are specially handled internally:

```typ
#let f(x) = x;
```

= Custom Blocks

Hello?

#kouhu(length: 50)

$"H3" Delta = 2$

$ "ax"^2 + "bx" + c = 0 $

aaa

```elixir
f("foo")

def foo do
  "bar"
end
```
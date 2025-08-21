#import "@preview/shiroa:0.2.3": plain-text, templates
#import templates: get-label-disambiguator, label-disambiguator, make-unique-label

#let static-heading-link(elem, body: "#") = context {
  let id = {
    let title = plain-text(elem).trim()
    "label-"
    str(
      make-unique-label(
        title,
        disambiguator: label-disambiguator.at(elem.location()).at(title, default: 0) + 1,
      ),
    )
  }
  html.elem(
    "a",
    attrs: (
      "href": "#" + id,
      ..if body == "#" { ("id": id, "data-typst-label": id) },
    ),
    body,
  )
}

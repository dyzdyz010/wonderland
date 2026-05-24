// PDF typography roles.
//
// Keep font choices semantic instead of scattering concrete family names across
// templates. The required Noto CJK SC font files are vendored under
// `assets/fonts/noto-cjk-sc/`, and the PDF routes assert that they exist before
// compiling so builds do not silently depend on system-installed fonts.

#let pdf-heading-fonts = (
  "Noto Sans CJK SC",
  "Noto Sans SC",
  "Noto Sans",
  "PingFang SC",
  "Arial",
)

#let pdf-body-fonts = (
  "Noto Serif CJK SC",
  "Noto Serif SC",
  "Noto Serif",
  "Songti SC",
  "Libertinus Serif",
)

#let pdf-mono-fonts = (
  "JetBrains Mono",
  "SF Mono",
  "Menlo",
  "DejaVu Sans Mono",
)

#let pdf-heading-text(size: 18pt, weight: "semibold", fill: black, body) = {
  set text(font: pdf-heading-fonts, size: size, weight: weight, fill: fill)
  body
}

#let pdf-body-text(size: 10.5pt, fill: black, body) = {
  set text(font: pdf-body-fonts, size: size, fill: fill)
  body
}

#let pdf-ui-text(size: 9pt, weight: "regular", fill: luma(120), body) = {
  set text(font: pdf-heading-fonts, size: size, weight: weight, fill: fill)
  body
}

#import "/templates/blog.typ": *
#import "/templates/enums.typ": *

#show: main.with(
  title: "Enable latex-export-logging in org-mode",
  desc: [Enable latex-export-logging in org-mode],
  date: "2018-05-11",
  tags: (
    blog-tags.emacs,
    blog-tags.tooling,
  ),
)

Emacs version: GNU Emacs 26.1(Also works in Emacs 24 or maybe even in earlier versions)

By default, when exporting latex and PDF file from emacs org-mode, log files are removed when the process finishes, you may want to reserve it.

To make emacs stop removing log files, do as below:

`M-x` -> `customize-variable`, `RET` -> `org-latex-remove-logfiles`

By default this variable is set to `true`, means log files are removed automatically, then you just need to toggle it to `false`, save, restart Emacs, and you're good to go

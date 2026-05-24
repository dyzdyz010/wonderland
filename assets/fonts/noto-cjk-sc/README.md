# Vendored Noto CJK SC fonts

These fonts are vendored so Typst PDF generation does not depend on fonts installed on the build machine.

The `.otf` files are tracked with Git LFS. Run `git lfs install` before cloning or `git lfs pull` after cloning if the files appear as LFS pointer text instead of binary fonts. The PDF build checks for unresolved LFS pointer files and fails with an explicit `git lfs pull` message.

Included font files:

- `NotoSansCJKsc-Regular.otf`
- `NotoSansCJKsc-Bold.otf`
- `NotoSerifCJKsc-Regular.otf`
- `NotoSerifCJKsc-Bold.otf`

The PDF typography roles in `templates/pdf/typography.typ` use Noto Sans CJK SC for headings/UI text and Noto Serif CJK SC for body text.

License: SIL Open Font License 1.1, see `LICENSE-OFL.txt`.

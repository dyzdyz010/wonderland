import { existsSync, readFileSync, statSync } from "node:fs";
import * as path from "node:path";

const REQUIRED_PDF_FONT_DIR = "assets/fonts/noto-cjk-sc";
const REQUIRED_PDF_FONT_FILES = [
  "NotoSansCJKsc-Regular.otf",
  "NotoSansCJKsc-Bold.otf",
  "NotoSerifCJKsc-Regular.otf",
  "NotoSerifCJKsc-Bold.otf",
];
const LFS_POINTER_PREFIX = "version https://git-lfs.github.com/spec/v1";

const PROJECT_FONT_DIRS = [
  REQUIRED_PDF_FONT_DIR,
  "assets/fonts",
  "public/fonts",
];

function isGitLfsPointer(filePath: string): boolean {
  const header = readFileSync(filePath, "utf8").slice(0, LFS_POINTER_PREFIX.length);
  return header === LFS_POINTER_PREFIX;
}

function assertRequiredPdfFonts(projectRoot: string) {
  const missingFonts: string[] = [];
  const pointerFonts: string[] = [];

  for (const fileName of REQUIRED_PDF_FONT_FILES) {
    const fontPath = path.join(projectRoot, REQUIRED_PDF_FONT_DIR, fileName);

    if (!existsSync(fontPath)) {
      missingFonts.push(fileName);
      continue;
    }

    // Git LFS leaves a small text pointer when the binary object was not pulled.
    // Detect that explicitly so CI fails with a clear remediation instead of
    // letting Typst fall back to system fonts or fail with an opaque font error.
    if (statSync(fontPath).size < 1024 && isGitLfsPointer(fontPath)) {
      pointerFonts.push(fileName);
    }
  }

  if (missingFonts.length > 0) {
    throw new Error(
      `[typst-fonts] Missing vendored PDF fonts in ${REQUIRED_PDF_FONT_DIR}: ${missingFonts.join(", ")}`,
    );
  }

  if (pointerFonts.length > 0) {
    throw new Error(
      `[typst-fonts] Git LFS fonts were not pulled in ${REQUIRED_PDF_FONT_DIR}: ${pointerFonts.join(", ")}. Run \`git lfs pull\` before building.`,
    );
  }
}

export function getTypstCompilerOptions(projectRoot: string) {
  assertRequiredPdfFonts(projectRoot);

  const fontPaths = PROJECT_FONT_DIRS
    .map((dir) => path.join(projectRoot, dir))
    .filter((dir) => existsSync(dir));

  return {
    workspace: projectRoot,
    fontArgs: [{ fontPaths }],
  };
}

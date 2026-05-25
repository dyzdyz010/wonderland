#!/usr/bin/env node
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import {
  artifactDirForVersion,
  buildArchiveSummaries,
  ensureEmptyDir,
  formatDate,
  getArchivePdfOutputPath,
  getArticlePdfOutputPath,
  getTypstCompilerOptions,
  packArtifact,
  pdfVersion,
  readArticles,
  renderArchivePdfSource,
  renderArticlePdfSource,
  root,
  walkFiles,
  writeFileEnsured,
} from "./lib.mjs";

const args = new Set(process.argv.slice(2));
const shouldPack = args.has("--pack");
const version = pdfVersion();
const artifactDir = artifactDirForVersion(version);
const generatedSourceDir = join(root, ".astro", "generated-pdf-sources", version);

console.log(`[pdf:generate] version=${version}`);
console.log(`[pdf:generate] output=${relative(root, artifactDir)}`);

ensureEmptyDir(artifactDir);
ensureEmptyDir(generatedSourceDir);

const compiler = NodeCompiler.create(getTypstCompilerOptions(root));
const posts = readArticles();
const files = [];

function compilePdf(mainFilePath, outputRelativePath, label) {
  const outputPath = join(artifactDir, outputRelativePath);
  mkdirSync(dirname(outputPath), { recursive: true });
  try {
    const pdfBuffer = compiler.pdf({ mainFilePath });
    writeFileSync(outputPath, pdfBuffer);
    files.push(outputRelativePath.replaceAll("\\", "/"));
    console.log(`[pdf:generate] ${label} -> ${outputRelativePath}`);
  } catch (error) {
    console.error(`[pdf:generate] Failed ${label}: ${error?.code ?? error?.message ?? String(error)}`);
    throw error;
  }
}

for (const post of posts) {
  const sourceRelativePath = join("article", post.data.lang, `${post.data.i18nKey.replace(/[^a-zA-Z0-9._-]+/g, "__")}.typ`);
  const mainFilePath = join(generatedSourceDir, sourceRelativePath);
  writeFileEnsured(mainFilePath, renderArticlePdfSource(post));
  compilePdf(mainFilePath, getArticlePdfOutputPath(post), `${post.data.lang}/${post.data.i18nKey}`);
}

for (const locale of ["zh", "en"]) {
  for (const archive of buildArchiveSummaries(posts, locale)) {
    const mainFilePath = join(generatedSourceDir, "archive", locale, `${archive.year}.typ`);
    writeFileEnsured(mainFilePath, renderArchivePdfSource(archive));
    compilePdf(mainFilePath, getArchivePdfOutputPath(archive), `${locale}/archive/${archive.year}`);
  }
}

const artifactManifestFileName = "pdf-manifest.json";
const manifest = {
  version,
  generatedAt: new Date().toISOString(),
  sourceCommit: null,
  generator: "scripts/pdf/generate.mjs",
  fileCount: files.length,
  files: files.sort(),
};
try {
  const { execFileSync } = await import("node:child_process");
  manifest.sourceCommit = execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
} catch {}

writeFileEnsured(join(artifactDir, artifactManifestFileName), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`[pdf:generate] wrote ${files.length} PDFs`);
console.log(`[pdf:generate] manifest=${relative(root, join(artifactDir, artifactManifestFileName))}`);

if (shouldPack) {
  const archivePath = packArtifact(version);
  console.log(`[pdf:generate] archive=${relative(root, archivePath)}`);
}

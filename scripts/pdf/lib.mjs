import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { execFileSync } from "node:child_process";

export const root = process.cwd();
export const articleRoot = resolve(root, "content/article");
export const artifactRoot = resolve(root, ".pdf-artifacts");
export const pdfVersionPrefix = "pdf-v1";
export const artifactReleaseTag = process.env.PDF_ARTIFACT_RELEASE_TAG || "pdf-artifacts";
export const siteAuthor = "dyzdyz010";
export const siteUrl = "https://dyz.io";

const requiredPdfFontDir = "assets/fonts/noto-cjk-sc";
const requiredPdfFontFiles = [
  "NotoSansCJKsc-Regular.otf",
  "NotoSansCJKsc-Bold.otf",
  "NotoSerifCJKsc-Regular.otf",
  "NotoSerifCJKsc-Bold.otf",
];
const lfsPointerPrefix = "version https://git-lfs.github.com/spec/v1";
const projectFontDirs = [requiredPdfFontDir, "assets/fonts", "public/fonts"];

export function walkFiles(dir, suffixes = null) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      out.push(...walkFiles(path, suffixes));
    } else if (!suffixes || suffixes.some((suffix) => path.endsWith(suffix))) {
      out.push(path);
    }
  }
  return out.sort();
}

export function sha256Bytes(buffer) {
  return createHash("sha256").update(buffer).digest("hex");
}

export function sha256Text(text) {
  return createHash("sha256").update(text).digest("hex");
}

export function escapeTypstString(value) {
  return String(value ?? "").replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

export function formatDate(date) {
  if (date instanceof Date) return date.toISOString().slice(0, 10);
  return String(date).slice(0, 10);
}

export function normalizeSlug(value) {
  return String(value ?? "").replace(/^\/+|\/+$/g, "");
}

export function parseStringField(raw, name) {
  return new RegExp(`${name}\\s*:\\s*"([^"]+)"`).exec(raw)?.[1];
}

export function parseContentField(raw, name) {
  return new RegExp(`${name}\\s*:\\s*\\[([^]*?)\\]\\s*,`, "m").exec(raw)?.[1]?.trim() ?? "";
}

function metadataBlock(raw) {
  const lines = raw.split(/\r?\n/);
  let inShow = false;
  const out = [];
  for (const line of lines) {
    if (line.includes("#show:") && line.includes("main.with")) inShow = true;
    if (inShow) out.push(line);
    if (inShow && line.trim() === ")") break;
  }
  return out.join("\n");
}

function parseTagRegistry() {
  const raw = readFileSync(resolve(root, "templates/enums.typ"), "utf8");
  const match = /#let\s+blog-tags\s*=\s*\(([^]*?)\)/m.exec(raw);
  const registry = new Map();
  if (!match) return registry;
  for (const entry of match[1].matchAll(/([A-Za-z0-9-]+)\s*:\s*"([^"]+)"/g)) {
    registry.set(entry[1], entry[2]);
  }
  return registry;
}

function parseTags(metadata, registry) {
  const tagBlock = /tags\s*:\s*\(([^]*?)\),/m.exec(metadata)?.[1] ?? "";
  return [...tagBlock.matchAll(/blog-tags\.([A-Za-z0-9-]+)/g)].map((match) => registry.get(match[1]) ?? match[1]);
}

export function readArticles() {
  const tagRegistry = parseTagRegistry();
  return walkFiles(articleRoot, [".typ"]).map((path) => {
    const raw = readFileSync(path, "utf8");
    const metadata = metadataBlock(raw);
    const id = relative(articleRoot, path).replaceAll("\\", "/").replace(/\.typ$/, "");
    const [lang, ...rest] = id.split("/");
    const pathKey = rest.join("/");
    const dateString = parseStringField(metadata, "date") ?? "1970-01-01";
    const i18nKey = normalizeSlug(parseStringField(metadata, "i18nKey") ?? pathKey);
    const title = parseStringField(metadata, "title") ?? "Untitled";
    return {
      id,
      filePath: relative(root, path).replaceAll("\\", "/"),
      data: {
        lang,
        i18nKey,
        title,
        description: parseContentField(metadata, "desc"),
        date: new Date(`${dateString}T00:00:00.000Z`),
        dateString,
        updatedDate: parseStringField(metadata, "updatedDate")
          ? new Date(`${parseStringField(metadata, "updatedDate")}T00:00:00.000Z`)
          : undefined,
        tags: parseTags(metadata, tagRegistry),
        translationStatus: parseStringField(metadata, "translationStatus") ?? "source",
      },
    };
  });
}

export function postsForLocale(posts, locale) {
  const byKey = new Map();
  for (const post of posts) {
    const key = normalizeSlug(post.data.i18nKey);
    const group = byKey.get(key) ?? [];
    group.push(post);
    byKey.set(key, group);
  }
  return Array.from(byKey.values()).map((group) => (
    group.find((post) => post.data.lang === locale) ??
    group.find((post) => post.data.translationStatus === "source") ??
    group[0]
  ));
}

export function sortPostsOldestFirst(posts) {
  return [...posts].sort((a, b) => {
    const dateCompare = a.data.date.valueOf() - b.data.date.valueOf();
    if (dateCompare !== 0) return dateCompare;
    return normalizeSlug(a.data.i18nKey).localeCompare(normalizeSlug(b.data.i18nKey), undefined, { sensitivity: "base" });
  });
}

export function buildArchiveSummaries(posts, locale) {
  const postsByYear = new Map();
  for (const post of postsForLocale(posts, locale)) {
    const year = String(post.data.date.getUTCFullYear());
    const group = postsByYear.get(year) ?? [];
    group.push(post);
    postsByYear.set(year, group);
  }
  return [...postsByYear.entries()]
    .sort(([a], [b]) => b.localeCompare(a))
    .map(([year, yearPosts]) => {
      const sortedPosts = sortPostsOldestFirst(yearPosts);
      const latestDate = sortedPosts.at(-1)?.data.date ?? new Date(`${year}-01-01T00:00:00.000Z`);
      return {
        locale,
        year,
        title: locale === "zh" ? `${year} 博客归档` : `Blog Archive ${year}`,
        description: locale === "zh" ? `${year} 年博客文章合集` : `${year} blog article collection`,
        date: latestDate,
        dateString: formatDate(latestDate),
        count: sortedPosts.length,
        articles: sortedPosts.map((post) => ({
          title: post.data.title,
          date: formatDate(post.data.date),
          path: getArticleTypstPath(post),
        })),
      };
    });
}

export function getArticleTypstPath(post) {
  return `/${post.filePath ?? `content/article/${post.id}.typ`}`;
}

export function getArticleUrl(post) {
  return new URL(`/${post.data.lang}/article/${normalizeSlug(post.data.i18nKey)}/`, siteUrl).toString();
}

export function getArticlePdfOutputPath(post) {
  return `${post.data.lang}/article/${normalizeSlug(post.data.i18nKey)}.pdf`;
}

export function getArchivePdfOutputPath(archive) {
  return `${archive.locale}/archive/${archive.year}.pdf`;
}

export function renderStringTuple(values) {
  if (!values || values.length === 0) return "()";
  return `(${values.map((value) => `"${escapeTypstString(value)}"`).join(", ")},)`;
}

export function renderArticlePdfSource(post) {
  const description = post.data.description ?? "";
  const date = formatDate(post.data.date);
  const updatedDate = post.data.updatedDate ? `"${formatDate(post.data.updatedDate)}"` : "none";
  const tags = renderStringTuple(post.data.tags ?? []);
  const articlePath = getArticleTypstPath(post);
  const sourceUrl = getArticleUrl(post);
  const copyrightNotice = `© ${siteAuthor}. Original article: ${sourceUrl}. All rights reserved unless otherwise noted.`;
  return `#import "/templates/article-pdf.typ": *

#show: main.with(
  title: "${escapeTypstString(post.data.title)}",
  desc: "${escapeTypstString(description)}",
  date: "${date}",
  updated_date: ${updatedDate},
  author: "${escapeTypstString(siteAuthor)}",
  source_url: "${escapeTypstString(sourceUrl)}",
  tags: ${tags},
  copyright_notice: "${escapeTypstString(copyrightNotice)}",
)

#include "${escapeTypstString(articlePath)}"
`;
}

export function renderArchivePdfSource(archive) {
  const articles = archive.articles
    .map((article) => `    (title: "${escapeTypstString(article.title)}", date: "${article.date}", path: "${article.path}"),`)
    .join("\n");
  return `#import "/templates/archive.typ": *

#show: main.with(
  title: "${escapeTypstString(archive.title)}",
  desc: [${archive.description}],
  date: "${archive.dateString}",
  tags: ("Archive",),
  articles: (
${articles}
  ),
)
`;
}

function isGitLfsPointer(filePath) {
  const header = readFileSync(filePath, "utf8").slice(0, lfsPointerPrefix.length);
  return header === lfsPointerPrefix;
}

export function assertRequiredPdfFonts(projectRoot = root) {
  const missingFonts = [];
  const pointerFonts = [];
  for (const fileName of requiredPdfFontFiles) {
    const fontPath = join(projectRoot, requiredPdfFontDir, fileName);
    if (!existsSync(fontPath)) {
      missingFonts.push(fileName);
      continue;
    }
    if (statSync(fontPath).size < 1024 && isGitLfsPointer(fontPath)) {
      pointerFonts.push(fileName);
    }
  }
  if (missingFonts.length > 0) {
    throw new Error(`[typst-fonts] Missing vendored PDF fonts in ${requiredPdfFontDir}: ${missingFonts.join(", ")}`);
  }
  if (pointerFonts.length > 0) {
    throw new Error(`[typst-fonts] Git LFS fonts were not pulled in ${requiredPdfFontDir}: ${pointerFonts.join(", ")}. Run \`git lfs pull\` before generating PDFs.`);
  }
}

export function getTypstCompilerOptions(projectRoot = root) {
  assertRequiredPdfFonts(projectRoot);
  const fontPaths = projectFontDirs.map((dir) => join(projectRoot, dir)).filter((dir) => existsSync(dir));
  return { workspace: projectRoot, fontArgs: [{ fontPaths }] };
}

export function ensureEmptyDir(dir) {
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
}

export function writeFileEnsured(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

function hashFileInto(hash, path) {
  const rel = relative(root, path).replaceAll("\\", "/");
  hash.update(`file:${rel}\n`);
  hash.update(readFileSync(path));
  hash.update("\n");
}

export function pdfInputFiles() {
  const files = [
    ...walkFiles(resolve(root, "content/article"), [".typ"]),
    ...walkFiles(resolve(root, "templates"), [".typ"]),
    ...walkFiles(resolve(root, "scripts/pdf"), [".mjs"]),
    resolve(root, "package.json"),
  ];
  const bunLock = resolve(root, "bun.lock");
  if (existsSync(bunLock)) files.push(bunLock);
  return files.filter(existsSync).sort();
}

export function pdfVersion() {
  const hash = createHash("sha256");
  hash.update(`${pdfVersionPrefix}\n`);
  for (const file of pdfInputFiles()) hashFileInto(hash, file);
  return `${pdfVersionPrefix}-${hash.digest("hex").slice(0, 16)}`;
}

export function artifactDirForVersion(version = pdfVersion()) {
  return resolve(artifactRoot, version);
}

export function artifactArchiveName(version = pdfVersion()) {
  return `wonderland-pdf-${version}.tar.gz`;
}

export function artifactArchivePath(version = pdfVersion()) {
  return resolve(artifactRoot, artifactArchiveName(version));
}

export function artifactManifestName(version = pdfVersion()) {
  return `wonderland-pdf-${version}.manifest.json`;
}

export function artifactManifestPath(version = pdfVersion()) {
  return resolve(artifactRoot, artifactManifestName(version));
}

export function packArtifact(version = pdfVersion()) {
  const dir = artifactDirForVersion(version);
  if (!existsSync(dir)) {
    throw new Error(`[pdf:pack] Missing artifact directory ${relative(root, dir)}. Run bun run pdf:generate first.`);
  }
  mkdirSync(artifactRoot, { recursive: true });
  const archivePath = artifactArchivePath(version);
  rmSync(archivePath, { force: true });
  execFileSync("tar", ["-czf", archivePath, "-C", dir, "."], { stdio: "inherit" });
  const manifest = join(dir, "pdf-manifest.json");
  if (existsSync(manifest)) {
    writeFileSync(artifactManifestPath(version), readFileSync(manifest));
  }
  return archivePath;
}

export function ownerRepo() {
  if (process.env.PDF_ARTIFACT_REPO) return process.env.PDF_ARTIFACT_REPO;
  try {
    const remote = execFileSync("git", ["remote", "get-url", "origin"], { encoding: "utf8" }).trim();
    const match = /github\.com[:/]([^/]+\/[^/.]+)(?:\.git)?$/.exec(remote);
    if (match) return match[1];
  } catch {}
  return "dyzdyz010/wonderland";
}

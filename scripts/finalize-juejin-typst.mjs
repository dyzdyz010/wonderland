import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");

const archiveRoot = path.join(projectRoot, "content", "archive");
const enumsPath = path.join(projectRoot, "templates", "enums.typ");
const reportPath = path.join(
  projectRoot,
  "output",
  "juejin-migration",
  "migration-report.json"
);

const parser = unified().use(remarkParse).use(remarkGfm);

const duplicateDateOverrides = new Map([
  [
    "content/article/meta/2022/vitepress-theme-oblivion.typ",
    "2022-10-16",
  ],
  [
    "content/article/mmo-server-from-scratch/2022/20220608-mmo-server-from-scratch(0)-introduction.typ",
    "2022-10-12",
  ],
  [
    "content/article/mmo-server-from-scratch/2022/20220610-mmo-server-from-scratch(1)-beacon-server.typ",
    "2022-10-15",
  ],
  [
    "content/article/mmo-server-from-scratch/2022/20221016-mmo-server-from-scratch(2)-gate-server.typ",
    "2022-10-17",
  ],
  [
    "content/article/study/2018/quicksort-review.typ",
    "2022-10-20",
  ],
  [
    "content/article/tutorials/2020/bulletproof-task-management-priority-formula.typ",
    "2022-10-14",
  ],
  [
    "content/article/tutorials/2022/ue5-protobuf.typ",
    "2022-10-13",
  ],
]);

const tagOverrides = new Map([
  ["掘金·日新计划", null],
  ["算法", "Algorithm"],
  ["排序算法", "Algorithm"],
  ["游戏开发", "Game"],
  ["函数式编程", "Programming"],
  ["Vue.js", "Vue"],
  ["LaTex", "Tooling"],
  ["C++", "Programming"],
  ["CSS", "Tooling"],
  ["JavaScript", "Programming"],
  ["TypeScript", "Programming"],
]);

async function main() {
  const report = JSON.parse(await fs.readFile(reportPath, "utf8"));
  const enumTagIdsByLabel = await readEnumTagIdsByLabel();

  const importedTypEntries = [];
  for (const imported of report.imported) {
    const sourcePath = path.join(projectRoot, imported.file);

    if (sourcePath.endsWith(".md")) {
      const typPath = sourcePath.replace(/\.md$/i, ".typ");
      const raw = await fs.readFile(sourcePath, "utf8");
      const { frontmatter, body } = parseMarkdownFile(raw);
      const typContent = renderTypstDocument(frontmatter, body, enumTagIdsByLabel);

      await fs.writeFile(typPath, typContent, "utf8");
      await fs.unlink(sourcePath);

      imported.file = path.relative(projectRoot, typPath).replaceAll("\\", "/");
      importedTypEntries.push({
        title: frontmatter.title,
        date: frontmatter.date,
        path: `/${imported.file.replaceAll("\\", "/")}`,
      });
      continue;
    }

    if (sourcePath.endsWith(".typ")) {
      const raw = await fs.readFile(sourcePath, "utf8");
      const cleaned = cleanGeneratedTyp(raw);
      if (cleaned !== raw) {
        await fs.writeFile(sourcePath, cleaned, "utf8");
      }
      importedTypEntries.push(await readTypMetadata(`/${imported.file.replaceAll("\\", "/")}`));
      continue;
    }

    throw new Error(`Unsupported imported file type: ${imported.file}`);
  }

  await applyDuplicateDateOverrides();
  await rebuildArchives(importedTypEntries);
  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), "utf8");
}

async function readEnumTagIdsByLabel() {
  const raw = await fs.readFile(enumsPath, "utf8");
  const block = /#let\s+blog-tags\s*=\s*\(([^]*?)\)/m.exec(raw)?.[1] ?? "";
  return new Map(
    [...block.matchAll(/([A-Za-z0-9-]+)\s*:\s*"([^"]+)"/g)].map((match) => [match[2], match[1]])
  );
}

function parseMarkdownFile(raw) {
  const match = /^---\s*[\r\n]+([\s\S]*?)[\r\n]+---[\r\n]*([\s\S]*)$/m.exec(raw);
  if (!match) {
    throw new Error("Invalid markdown frontmatter");
  }

  const [, fm, body] = match;
  const title = fm.match(/^title:\s*"?(.*?)"?\s*$/m)?.[1] ?? "";
  const description = fm.match(/^description:\s*"?(.*?)"?\s*$/m)?.[1] ?? title;
  const date = fm.match(/^date:\s*"?(.*?)"?\s*$/m)?.[1] ?? "";
  const tags = [...fm.matchAll(/^\s*-\s*"?(.+?)"?\s*$/gm)].map((m) => m[1]);

  return {
    frontmatter: {
      title,
      description,
      date,
      tags,
    },
    body: body.trim(),
  };
}

function renderTypstDocument(frontmatter, markdown, enumTagIdsByLabel) {
  const tree = parser.parse(markdown);
  const bodyNodes = [...tree.children];
  while (bodyNodes[0]?.type === "thematicBreak") {
    bodyNodes.shift();
  }
  const body = renderBlocks(bodyNodes).trim();
  const tags = normalizeTags(frontmatter.tags, enumTagIdsByLabel);

  const tagBlock =
    tags.length === 0
      ? "  tags: (),"
      : [
          "  tags: (",
          ...tags.map((tag) =>
            tag.id
              ? `    blog-tags.${tag.id},`
              : `    ${renderTypstString(tag.label)},`
          ),
          "  ),",
        ].join("\n");

  return [
    '#import "/templates/blog.typ": *',
    '#import "/templates/enums.typ": *',
    "",
    "#show: main.with(",
    `  title: ${renderTypstString(frontmatter.title)},`,
    `  desc: [${escapeInlineText(frontmatter.description)}],`,
    `  date: ${renderTypstString(frontmatter.date)},`,
    tagBlock,
    ")",
    "",
    body,
    "",
  ].join("\n");
}

function cleanGeneratedTyp(raw) {
  return raw.replace(/\)\n\n#line\(length: 100%\)\n\n/, ")\n\n");
}

function normalizeTags(tags, enumTagIdsByLabel) {
  const output = [];
  const seen = new Set();

  for (const tag of tags) {
    const candidate = tagOverrides.has(tag) ? tagOverrides.get(tag) : tag;
    if (!candidate) {
      continue;
    }

    const id = enumTagIdsByLabel.get(candidate) ?? null;
    const dedupeKey = id ?? `raw:${candidate}`;

    if (!seen.has(dedupeKey)) {
      seen.add(dedupeKey);
      output.push({
        label: candidate,
        id,
      });
    }
  }

  return output;
}

function renderBlocks(nodes, depth = 0) {
  return nodes.map((node, index) => renderBlock(node, depth, index)).join("");
}

function renderBlock(node, depth = 0, index = 0) {
  switch (node.type) {
    case "heading":
      return `${"=".repeat(node.depth)} ${renderInlineNodes(node.children).trim()}\n\n`;

    case "paragraph":
      if (node.children.every((child) => child.type === "image")) {
        return (
          node.children.map((child) => `${renderImageFigure(child)}\n\n`).join("")
        );
      }
      return `${renderInlineNodes(node.children).trim()}\n\n`;

    case "code":
      return `\`\`\`${node.lang ?? ""}\n${String(node.value).replace(/\r/g, "").trimEnd()}\n\`\`\`\n\n`;

    case "blockquote": {
      const inner = renderBlocks(node.children, depth + 1).trim();
      return `#quote(block: true)[\n${indentBlock(inner)}\n]\n\n`;
    }

    case "list":
      return renderList(node, depth);

    case "thematicBreak":
      return "#line(length: 100%)\n\n";

    case "table":
      return renderTable(node);

    case "html":
      return node.value?.trim() ? `\`\`\`\n${node.value.trim()}\n\`\`\`\n\n` : "";

    default:
      return "";
  }
}

function renderList(node, depth) {
  return (
    node.children
      .map((item, index) => renderListItem(item, node.ordered, depth, index))
      .join("") + "\n"
  );
}

function renderListItem(item, ordered, depth, index) {
  const indent = "  ".repeat(depth);
  const marker = ordered ? `${index + 1}.` : "-";
  const [first, ...rest] = item.children;

  let line = "";
  if (first?.type === "paragraph") {
    line = `${indent}${marker} ${renderInlineNodes(first.children).trim()}\n`;
  } else if (first) {
    line = `${indent}${marker}\n${indentBlock(renderBlock(first, depth + 1), depth + 1)}`;
  } else {
    line = `${indent}${marker}\n`;
  }

  if (rest.length === 0) {
    return line;
  }

  const trailing = rest
    .map((child) => {
      if (child.type === "list") {
        return child.children
          .map((nested, nestedIndex) => renderListItem(nested, child.ordered, depth + 1, nestedIndex))
          .join("");
      }
      return indentBlock(renderBlock(child, depth + 1), depth + 1);
    })
    .join("");

  return `${line}${trailing}`;
}

function renderTable(node) {
  const columnCount = Math.max(...node.children.map((row) => row.children.length), 1);
  const rows = node.children.map((row) =>
    row.children.map((cell) => renderInlineNodes(cell.children).trim())
  );
  const header = rows[0] ?? [];
  const body = rows.slice(1);

  const lines = [
    `#table(columns: (${Array.from({ length: columnCount }, () => "auto").join(", ")}),`,
    `  table.header(${header.map((cell) => `[${cell}]`).join(", ")}),`,
  ];

  for (const row of body) {
    for (const cell of row) {
      lines.push(`  [${cell}],`);
    }
  }

  lines.push(")");
  return `${lines.join("\n")}\n\n`;
}

function renderInlineNodes(nodes) {
  return nodes.map((node) => renderInline(node)).join("");
}

function renderInline(node) {
  switch (node.type) {
    case "text":
      return escapeInlineText(node.value);

    case "strong":
      return `*${renderInlineNodes(node.children)}*`;

    case "emphasis":
      return `_${renderInlineNodes(node.children)}_`;

    case "inlineCode":
      return `\`${String(node.value).replace(/`/g, "\\`")}\``;

    case "link": {
      const url = normalizeUrl(node.url);
      const label = renderInlineNodes(node.children).trim() || url;
      return `#link(${renderTypstString(url)})[${label}]`;
    }

    case "image":
      return renderImageFigure(node);

    case "break":
      return "\\\n";

    case "delete":
      return renderInlineNodes(node.children);

    default:
      return "";
  }
}

function renderImageFigure(node) {
  let src = normalizeUrl(node.url);
  if (src.startsWith("/assets/")) {
    src = `/public${src}`;
  }
  const caption = (node.alt || "").trim();
  if (caption) {
    return `#figure(image(${renderTypstString(src)}), caption: ${renderTypstString(caption)})`;
  }
  return `#figure(image(${renderTypstString(src)}))`;
}

function normalizeUrl(url) {
  try {
    const parsed = new URL(url);
    if (parsed.hostname.endsWith("link.juejin.cn")) {
      const target = parsed.searchParams.get("target");
      if (target) {
        return decodeURIComponent(target);
      }
    }
    return parsed.toString();
  } catch {
    return url;
  }
}

function renderTypstString(value) {
  return JSON.stringify(String(value));
}

function escapeInlineText(value) {
  return String(value)
    .replace(/\\/g, "\\\\")
    .replace(/([#\[\]\*_`$])/g, "\\$1")
    .replace(/\u00A0/g, " ");
}

function indentBlock(value, depth = 1) {
  const indent = "  ".repeat(depth);
  return value
    .split("\n")
    .map((line) => (line ? `${indent}${line}` : line))
    .join("\n");
}

async function applyDuplicateDateOverrides() {
  for (const [relativePath, date] of duplicateDateOverrides.entries()) {
    const absolutePath = path.join(projectRoot, relativePath);
    const raw = await fs.readFile(absolutePath, "utf8");
    const next = raw.replace(/date:\s*"[^"]+"/, `date: "${date}"`);
    await fs.writeFile(absolutePath, next, "utf8");
  }
}

async function rebuildArchives(importedTypEntries) {
  const current2022 = await parseArchivePaths(path.join(archiveRoot, "2022.typ"));
  const entries2022 = new Map();
  const entries2023 = new Map();

  for (const archivePath of current2022) {
    entries2022.set(archivePath, await readTypMetadata(archivePath));
  }

  for (const entry of importedTypEntries) {
    const year = entry.date.slice(0, 4);
    if (year === "2022") {
      entries2022.set(entry.path, await readTypMetadata(entry.path));
    } else if (year === "2023") {
      entries2023.set(entry.path, await readTypMetadata(entry.path));
    }
  }

  for (const relativePath of duplicateDateOverrides.keys()) {
    const archivePath = `/${relativePath.replaceAll("\\", "/")}`;
    const metadata = await readTypMetadata(archivePath);
    if (metadata.date.startsWith("2022")) {
      entries2022.set(archivePath, metadata);
    } else if (metadata.date.startsWith("2023")) {
      entries2023.set(archivePath, metadata);
    }
  }

  await writeArchiveFile("2022", [...entries2022.values()]);
  await writeArchiveFile("2023", [...entries2023.values()]);
}

async function parseArchivePaths(archivePath) {
  const raw = await fs.readFile(archivePath, "utf8");
  return [...raw.matchAll(/path:\s*"([^"]+)"/g)].map((match) => match[1]);
}

async function readTypMetadata(archivePath) {
  const relativePath = archivePath.replace(/^\//, "");
  const absolutePath = path.join(projectRoot, relativePath);
  const raw = await fs.readFile(absolutePath, "utf8");
  const title = raw.match(/title:\s*"([^"]+)"/)?.[1] ?? path.basename(relativePath, ".typ");
  const date = raw.match(/date:\s*"([^"]+)"/)?.[1] ?? "1970-01-01";
  return {
    title,
    date,
    path: archivePath.replaceAll("\\", "/"),
  };
}

async function writeArchiveFile(year, entries) {
  const sorted = [...entries].sort((a, b) => {
    if (a.date === b.date) {
      return a.title.localeCompare(b.title, "zh-Hans-CN");
    }
    return a.date.localeCompare(b.date);
  });

  const latestDate = sorted.at(-1)?.date ?? `${year}-01-01`;
  const archivePath = path.join(archiveRoot, `${year}.typ`);
  const body = [
    '#import "/templates/archive.typ": *',
    "",
    "#show: main.with(",
    `  title: "Blog Archive ${year}",`,
    `  desc: [${year} 年博客文章合集],`,
    `  date: "${latestDate}",`,
    '  tags: ("Archive",),',
    "  articles: (",
    ...sorted.map(
      (entry) =>
        `    (title: ${renderTypstString(entry.title)}, date: ${renderTypstString(
          entry.date
        )}, path: ${renderTypstString(entry.path)}),`
    ),
    "  ),",
    ")",
    "",
  ].join("\n");

  await fs.writeFile(archivePath, body, "utf8");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

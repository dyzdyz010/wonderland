import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { chromium } from "playwright";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const migrationDir = path.join(projectRoot, "output", "juejin-migration");
const listPath = path.join(migrationDir, "article-list.json");
const reportPath = path.join(migrationDir, "migration-report.json");
const storageStatePath = path.join(migrationDir, "storage-state.json");
const contentRoot = path.join(projectRoot, "content", "article");
const imageRoot = path.join(projectRoot, "public", "assets", "img");

const titlePrefixPatterns = [
  /^从零开始的mmorpg游戏服务器\(\d+\)\s*-\s*/i,
  /^mmo\s*server\s*from\s*scratch\(\d+\)\s*-\s*/i,
  /^vitepress\s*博客主题\s*-\s*/i,
  /^oblivion\s*-\s*/i,
];

const preferredTagMap = new Map([
  ["ffmpeg", "Tooling"],
  ["elixir", "Elixir"],
  ["erlang", "Erlang"],
  ["otp", "Elixir"],
  ["rust", "Rust"],
  ["rustler", "Rust"],
  ["rabbitmq", "Software"],
  ["rocketmq", "Software"],
  ["kafka", "Software"],
  ["redis", "Software"],
  ["grpc", "Software"],
  ["rest api", "Software"],
  ["protobuf", "Protobuf"],
  ["ue5", "UE5"],
  ["notion", "Notion"],
  ["algorithm", "Algorithm"],
  ["设计模式", "Software Engineering"],
  ["phoenix", "Software"],
  ["liveview", "Software"],
  ["tailwind", "Frontend"],
  ["pixi", "Frontend"],
  ["frontend", "Frontend"],
]);

const explicitTagMap = new Map([
  ["掘金·日新计划", null],
  ["算法", "Algorithm"],
  ["排序算法", "Algorithm"],
  ["数据结构", "Algorithm"],
  ["设计模式", "Software Engineering"],
  ["游戏开发", "Game"],
  ["游戏", "Game"],
  ["函数式编程", "Programming"],
  ["Vue.js", "Vue"],
  ["LaTex", "Tooling"],
  ["C++", "Programming"],
  ["CSS", "Frontend"],
  ["JavaScript", "Programming"],
  ["TypeScript", "Programming"],
  ["前端", "Frontend"],
  ["数据库", "Software"],
  ["消息队列", "Server"],
  ["服务器", "Server"],
  ["Redis", "Redis"],
  ["FFmpeg", "FFmpeg"],
  ["Erlang", "Erlang"],
]);

// Manually reviewed reposts already present in the blog with slightly different titles.
const manualDuplicateMap = new Map([
  [
    "7154995979173756942",
    path.join(
      "content",
      "article",
      "meta",
      "2022",
      "vitepress-theme-oblivion.typ"
    ),
  ],
  [
    "7153450083172761637",
    path.join(
      "content",
      "article",
      "mmo-server-from-scratch",
      "2022",
      "20220608-mmo-server-from-scratch(0)-introduction.typ"
    ),
  ],
]);

async function main() {
  const articles = JSON.parse(await fs.readFile(listPath, "utf8"));
  const existingPosts = await loadExistingPosts(contentRoot);
  const occupiedTitles = new Set(existingPosts.map((post) => post.normalizedTitle));

  const browser = await chromium.launch({
    channel: "chrome",
    headless: true,
  });
  const context = await browser.newContext({
    storageState: (await fileExists(storageStatePath)) ? storageStatePath : undefined,
    viewport: { width: 1440, height: 1200 },
  });

  const report = {
    total: articles.length,
    imported: [],
    skipped: [],
    failed: [],
  };

  try {
    for (const article of articles) {
      process.stdout.write(`Processing ${article.title}\n`);

      let scraped;
      const page = await context.newPage();
      try {
        scraped = await scrapeArticle(page, article.href);
      } catch (error) {
        report.failed.push({
          title: article.title,
          url: article.href,
          error: String(error),
        });
        await page.close();
        continue;
      }
      await page.close();

      const titleHit = findDuplicateByTitle(scraped.title, existingPosts);
      if (titleHit) {
        report.skipped.push({
          title: scraped.title,
          url: article.href,
          reason: `title:${path.relative(projectRoot, titleHit.filePath)}`,
        });
        continue;
      }

      const manualDuplicate = manualDuplicateMap.get(String(scraped.articleId));
      if (manualDuplicate) {
        report.skipped.push({
          title: scraped.title,
          url: article.href,
          reason: `manual:${manualDuplicate.replaceAll("\\", "/")}`,
        });
        continue;
      }

      const contentHit = findDuplicateByContent(scraped, existingPosts);
      if (contentHit) {
        report.skipped.push({
          title: scraped.title,
          url: article.href,
          reason: `content:${path.relative(projectRoot, contentHit.filePath)}`,
        });
        continue;
      }

      const year = (scraped.date || "1970-01-01").slice(0, 4);
      const baseSlug = buildSlug(scraped.title, scraped.articleId);
      const relativePath = classifyArticleTarget({
        title: scraped.title,
        tags: scraped.tags,
        text: scraped.text,
        year,
        baseSlug,
      });
      const outputPath = path.join(projectRoot, relativePath);
      const normalizedTitle = normalizeTitle(scraped.title);

      if (occupiedTitles.has(normalizedTitle)) {
        report.skipped.push({
          title: scraped.title,
          url: article.href,
          reason: "title:generated-conflict",
        });
        continue;
      }

      const imageDir = path.join(imageRoot, year);
      await fs.mkdir(imageDir, { recursive: true });

      const rewrittenMarkdown = await rewriteImages(
        scraped.markdown,
        scraped.images,
        imageDir,
        year,
        baseSlug
      );

      const frontmatter = renderFrontmatter({
        title: scraped.title,
        author: scraped.author || "Etern1ty",
        description: scraped.brief || scraped.title,
        date: scraped.date,
        tags: chooseTags(scraped.tags, scraped.title, scraped.text, relativePath),
      });

      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      await fs.writeFile(
        outputPath,
        `${frontmatter}\n${rewrittenMarkdown.trim()}\n`,
        "utf8"
      );

      occupiedTitles.add(normalizedTitle);
      report.imported.push({
        title: scraped.title,
        url: article.href,
        file: relativePath.replaceAll("\\", "/"),
      });
    }
  } finally {
    await context.close();
    await browser.close();
  }

  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), "utf8");
  process.stdout.write(
    `Imported ${report.imported.length}, skipped ${report.skipped.length}, failed ${report.failed.length}\n`
  );
}

async function loadExistingPosts(rootDir) {
  const files = await walkFiles(rootDir);
  const posts = [];

  for (const filePath of files) {
    if (!filePath.endsWith(".typ") && !filePath.endsWith(".md")) {
      continue;
    }

    const raw = await fs.readFile(filePath, "utf8");
    const title = extractTitle(raw, filePath);
    if (!title) {
      continue;
    }

    posts.push({
      filePath,
      title,
      normalizedTitle: normalizeTitle(title),
      normalizedBody: normalizeContent(stripFrontmatterAndBoilerplate(raw, filePath)),
    });
  }

  return posts;
}

async function walkFiles(dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  const output = [];

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      output.push(...(await walkFiles(fullPath)));
    } else {
      output.push(fullPath);
    }
  }

  return output;
}

function extractTitle(raw, filePath) {
  if (filePath.endsWith(".typ")) {
    return raw.match(/title:\s*"([^"]+)"/)?.[1] ?? null;
  }

  const fmMatch = raw.match(/^---\s*[\r\n]+([\s\S]*?)[\r\n]+---/);
  if (!fmMatch) {
    return null;
  }

  return fmMatch[1].match(/^title:\s*"?(.*?)"?\s*$/m)?.[1] ?? null;
}

function stripFrontmatterAndBoilerplate(raw, filePath) {
  if (filePath.endsWith(".md")) {
    return raw.replace(/^---\s*[\r\n]+[\s\S]*?[\r\n]+---/, "").trim();
  }

  return raw
    .replace(/^#import .*$/gm, "")
    .replace(/^#show:\s*main\.with\([\s\S]*?\)\s*/m, "")
    .trim();
}

function normalizeTitle(title) {
  let value = title
    .normalize("NFKC")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();

  for (const pattern of titlePrefixPatterns) {
    value = value.replace(pattern, "");
  }

  return value.replace(/[^\p{L}\p{N}\p{Script=Han}]+/gu, "");
}

function normalizeContent(text) {
  return text
    .normalize("NFKC")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\p{Script=Han}]+/gu, "");
}

function findDuplicateByTitle(title, existingPosts) {
  const normalized = normalizeTitle(title);
  return existingPosts.find((post) => post.normalizedTitle === normalized) ?? null;
}

function findDuplicateByContent(scraped, existingPosts) {
  const normalized = normalizeContent(stripJuejinCampaign(scraped.text));
  const probe = normalized.slice(0, 120);
  if (probe.length < 60) {
    return null;
  }

  return (
    existingPosts.find(
      (post) => post.normalizedBody.length >= probe.length && post.normalizedBody.includes(probe)
    ) ?? null
  );
}

function buildSlug(title, articleId) {
  const ascii = title
    .normalize("NFKD")
    .replace(/[^\x00-\x7F]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64);

  return ascii ? `${ascii}-${articleId}` : String(articleId);
}

function classifyArticleTarget({ title, tags, text, year, baseSlug }) {
  const haystack = `${title}\n${tags.join(" ")}\n${text}`.toLowerCase();

  if (
    /mmorpg游戏服务器|mmo server from scratch/u.test(title) ||
    /ue5 客户端对时实现/u.test(title)
  ) {
    return path.join(
      "content",
      "article",
      "mmo-server-from-scratch",
      year,
      `${baseSlug}.md`
    );
  }

  if (
    /ffmpeg|luatex/.test(haystack) ||
    /搭建.+环境|简单实践/u.test(title)
  ) {
    return path.join("content", "article", "tutorials", year, `${baseSlug}.md`);
  }

  return path.join("content", "article", "study", year, `${baseSlug}.md`);
}

function renderFrontmatter({ title, author, description, date, tags }) {
  const tagBlock =
    tags.length === 0
      ? ""
      : `tags:\n${tags.map((tag) => `  - ${quoteYaml(tag)}`).join("\n")}\n`;

  return [
    "---",
    `title: ${quoteYaml(title)}`,
    `author: ${quoteYaml(author)}`,
    `description: ${quoteYaml(description)}`,
    `date: ${quoteYaml(date)}`,
    tagBlock.trimEnd(),
    "---",
  ]
    .filter(Boolean)
    .join("\n");
}

function stripJuejinCampaign(text) {
  return String(text)
    .replace(
      /^开启掘金成长之旅！这是我参与「[^」]+」的第\d+天，?\[?点击查看活动详情\]?\([^)]+\)\s*/u,
      ""
    )
    .replace(
      /^开启掘金成长之旅！这是我参与「[^」]+」的第\d+天，点击查看活动详情\s*/u,
      ""
    )
    .replace(
      /^持续创作，加速成长！这是我参与「[^」]+」的第\d+天，?\[?点击查看活动详情\]?\([^)]+\)\s*/u,
      ""
    )
    .replace(
      /^持续创作，加速成长！这是我参与「[^」]+」的第\d+天，点击查看活动详情\s*/u,
      ""
    )
    .trim();
}

function quoteYaml(value) {
  return JSON.stringify(String(value));
}

function chooseTags(tags, title, text, relativePath = "") {
  const picked = new Set();
  const haystack = `${title}\n${text}`.toLowerCase();

  for (const tag of tags) {
    if (!tag || !tag.trim()) {
      continue;
    }

    const normalized = explicitTagMap.has(tag.trim())
      ? explicitTagMap.get(tag.trim())
      : tag.trim();

    if (normalized) {
      picked.add(normalized);
    }
  }

  for (const [needle, mapped] of preferredTagMap.entries()) {
    if (haystack.includes(needle)) {
      picked.add(mapped);
    }
  }

  if (relativePath.includes(`${path.sep}mmo-server-from-scratch${path.sep}`)) {
    picked.add("Programming");
    picked.add("MMO");
    picked.add("Game");
    if (!/ue5 客户端对时实现/u.test(title)) {
      picked.add("Server");
    }
  }

  return Array.from(picked).slice(0, 8);
}

async function scrapeArticle(page, url) {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await page.waitForSelector(".article-viewer.markdown-body");

  const data = await page.evaluate(() => {
    const entry = window.__NUXT__?.state?.view?.column?.entry;
    const info = entry?.article_info ?? {};
    const author = entry?.author_user_info?.user_name ?? "";
    const tags = Array.isArray(entry?.tags)
      ? entry.tags
          .map((tag) => tag?.tag_name ?? tag?.name ?? "")
          .filter(Boolean)
      : [];
    const root = document.querySelector(".article-viewer.markdown-body");

    function escapeMarkdown(text) {
      return text
        .replace(/\r/g, "")
        .replace(/\\/g, "\\\\")
        .replace(/([`*_{}\[\]()#+\-!>])/g, "\\$1");
    }

    function normalizeLineBreaks(text) {
      return text.replace(/\u00a0/g, " ").replace(/\r\n/g, "\n");
    }

    function renderInline(node) {
      if (node.nodeType === Node.TEXT_NODE) {
        return escapeMarkdown(normalizeLineBreaks(node.textContent || ""));
      }

      if (node.nodeType !== Node.ELEMENT_NODE) {
        return "";
      }

      const tag = node.tagName.toLowerCase();

      if (tag === "br") {
        return "  \n";
      }

      if (tag === "code" && node.closest("pre") == null) {
        const text = normalizeLineBreaks(node.textContent || "").replace(/`/g, "\\`");
        return text ? `\`${text}\`` : "";
      }

      if (tag === "a") {
        const href = node.getAttribute("href") || "";
        const text = renderInlineChildren(node).trim() || href;
        return href ? `[${text}](${href})` : text;
      }

      if (tag === "img") {
        const src = node.getAttribute("src") || "";
        const alt = escapeMarkdown(node.getAttribute("alt") || "");
        return src ? `![${alt}](${src})` : "";
      }

      if (tag === "strong" || tag === "b") {
        return `**${renderInlineChildren(node).trim()}**`;
      }

      if (tag === "em" || tag === "i") {
        return `*${renderInlineChildren(node).trim()}*`;
      }

      return renderInlineChildren(node);
    }

    function renderInlineChildren(node) {
      return Array.from(node.childNodes).map(renderInline).join("");
    }

    function renderCodeBlock(pre) {
      const clone = pre.cloneNode(true);
      clone.querySelectorAll(".code-block-extension-header").forEach((el) => el.remove());
      const lang =
        pre.querySelector(".code-block-extension-lang")?.textContent?.trim() ||
        pre.querySelector("code")?.className?.match(/language-([a-zA-Z0-9_-]+)/)?.[1] ||
        "";
      let code = normalizeLineBreaks(
        clone.querySelector("code")?.textContent || clone.textContent || ""
      );
      code = code
        .split("\n")
        .filter(
          (line) =>
            !["体验AI代码助手", "代码解读", "复制代码"].includes(line.trim())
        )
        .join("\n")
        .trimEnd();
      if (lang && code.startsWith(`${lang}\n`)) {
        code = code.slice(lang.length + 1);
      }
      return `\`\`\`${lang}\n${code}\n\`\`\`\n\n`;
    }

    function renderList(node, ordered, depth = 0) {
      const items = Array.from(node.children).filter((child) => child.tagName === "LI");
      return (
        items
          .map((li, index) => renderListItem(li, ordered ? `${index + 1}.` : "-", depth))
          .join("") + "\n"
      );
    }

    function renderListItem(li, bullet, depth) {
      const indent = "  ".repeat(depth);
      let main = "";
      let nested = "";

      for (const child of Array.from(li.childNodes)) {
        if (
          child.nodeType === Node.ELEMENT_NODE &&
          (child.tagName === "UL" || child.tagName === "OL")
        ) {
          nested += renderList(child, child.tagName === "OL", depth + 1);
        } else if (child.nodeType === Node.ELEMENT_NODE && child.tagName === "P") {
          main += renderInlineChildren(child).trim();
        } else {
          main += renderInline(child);
        }
      }

      let block = `${indent}${bullet} ${main.trim()}\n`;
      if (nested) {
        block += nested;
      }
      return block;
    }

    function renderTable(node) {
      const rows = Array.from(node.querySelectorAll("tr")).map((tr) =>
        Array.from(tr.children).map((cell) =>
          renderInlineChildren(cell)
            .replace(/\|/g, "\\|")
            .replace(/\n+/g, " ")
            .trim()
        )
      );
      if (rows.length === 0) {
        return "";
      }

      const header = rows[0];
      const separator = header.map(() => "---");
      const body = rows.slice(1);
      const lines = [
        `| ${header.join(" | ")} |`,
        `| ${separator.join(" | ")} |`,
        ...body.map((row) => `| ${row.join(" | ")} |`),
      ];
      return `${lines.join("\n")}\n\n`;
    }

    function renderBlock(node) {
      if (node.nodeType === Node.TEXT_NODE) {
        const text = normalizeLineBreaks(node.textContent || "").trim();
        return text ? `${escapeMarkdown(text)}\n\n` : "";
      }

      if (node.nodeType !== Node.ELEMENT_NODE) {
        return "";
      }

      const tag = node.tagName.toLowerCase();

      if (tag === "style") {
        return "";
      }

      if (tag === "h1") {
        return `# ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "h2") {
        return `## ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "h3") {
        return `### ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "h4") {
        return `#### ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "h5") {
        return `##### ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "h6") {
        return `###### ${renderInlineChildren(node).trim()}\n\n`;
      }

      if (tag === "p") {
        const content = renderInlineChildren(node).trim();
        return content ? `${content}\n\n` : "";
      }

      if (tag === "pre") {
        return renderCodeBlock(node);
      }

      if (tag === "blockquote") {
        const text = renderChildren(node)
          .trim()
          .split("\n")
          .map((line) => (line ? `> ${line}` : ">"))
          .join("\n");
        return `${text}\n\n`;
      }

      if (tag === "ul") {
        return renderList(node, false);
      }

      if (tag === "ol") {
        return renderList(node, true);
      }

      if (tag === "hr") {
        return `---\n\n`;
      }

      if (tag === "img") {
        return `${renderInline(node)}\n\n`;
      }

      if (tag === "table") {
        return renderTable(node);
      }

      if (tag === "figure" && node.querySelector("img")) {
        return `${renderInline(node.querySelector("img"))}\n\n`;
      }

      return renderChildren(node);
    }

    function renderChildren(node) {
      return Array.from(node.childNodes).map(renderBlock).join("");
    }

    const markdown = root
      ? renderChildren(root)
          .replace(/\n{3,}/g, "\n\n")
          .replace(/^\s+|\s+$/g, "")
      : "";

    const text = root
      ? normalizeLineBreaks(root.textContent || "")
          .replace(/\s+/g, " ")
          .trim()
      : "";

    const images = root
      ? Array.from(root.querySelectorAll("img"))
          .map((img) => ({
            src: img.getAttribute("src") || "",
            alt: img.getAttribute("alt") || "",
          }))
          .filter((img) => img.src)
      : [];

    return {
      articleId: info.article_id || "",
      title: info.title || document.querySelector("h1")?.textContent?.trim() || "",
      brief: info.brief_content || "",
      author,
      tags,
      date: info.ctime
        ? new Date(Number(info.ctime) * 1000).toISOString().slice(0, 10)
        : "",
      markdown,
      text,
      images,
    };
  });

  if (!data.title || !data.markdown) {
    throw new Error(`Failed to extract article content from ${url}`);
  }

  data.markdown = stripJuejinCampaign(data.markdown);
  data.text = stripJuejinCampaign(data.text);
  data.brief = stripJuejinCampaign(data.brief || data.title);

  return data;
}

async function rewriteImages(markdown, images, imageDir, year, baseSlug) {
  let output = markdown;
  const seen = new Map();
  let index = 1;

  for (const image of images) {
    const src = image.src;
    if (!src || seen.has(src)) {
      continue;
    }

    const response = await fetch(src);
    if (!response.ok) {
      continue;
    }

    const contentType = response.headers.get("content-type") || "";
    const ext = resolveImageExtension(src, contentType);
    const fileName = `${baseSlug}-${index}${ext}`;
    const outputPath = path.join(imageDir, fileName);
    const publicPath = `/assets/img/${year}/${fileName}`;
    const buffer = Buffer.from(await response.arrayBuffer());

    await fs.writeFile(outputPath, buffer);
    seen.set(src, publicPath);
    output = output.split(src).join(publicPath);
    index += 1;
  }

  return output;
}

function resolveImageExtension(src, contentType) {
  if (contentType.includes("png")) {
    return ".png";
  }
  if (contentType.includes("gif")) {
    return ".gif";
  }
  if (contentType.includes("webp")) {
    return ".webp";
  }
  if (contentType.includes("svg")) {
    return ".svg";
  }
  if (contentType.includes("jpeg") || contentType.includes("jpg")) {
    return ".jpg";
  }

  const pathname = new URL(src).pathname.toLowerCase();
  const ext = path.extname(pathname);
  return ext || ".png";
}

async function fileExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

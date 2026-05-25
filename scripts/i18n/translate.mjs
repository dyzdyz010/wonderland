#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { createHash } from "node:crypto";

const root = process.cwd();
loadDotEnv(resolve(root, ".env"));
const articleRoot = resolve(root, "content/article");
const pageRoot = resolve(root, "content/page");
const locales = ["zh", "en"];
const defaultTranslationStatus = "source";
const model = process.env.OPENAI_TRANSLATION_MODEL || "gpt-5";
const promptVersion = "wonderland-i18n-v1";

function parseArgs(argv) {
  const args = { all: false, write: false, forceReviewed: false, key: null, from: null, to: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--all") args.all = true;
    else if (arg === "--write") args.write = true;
    else if (arg === "--force-reviewed") args.forceReviewed = true;
    else if (arg === "--key") args.key = argv[++i];
    else if (arg === "--from") args.from = argv[++i];
    else if (arg === "--to") args.to = argv[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return args;
}

function loadDotEnv(path) {
  if (!existsSync(path)) return;
  const raw = readFileSync(path, "utf8");
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) continue;
    const [rawKey, ...valueParts] = trimmed.replace(/^export\s+/, "").split("=");
    const key = rawKey.trim();
    if (!key || process.env[key] !== undefined) continue;
    let value = valueParts.join("=").trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    process.env[key] = value;
  }
}

function walkFiles(dir, suffix) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) out.push(...walkFiles(path, suffix));
    else if (path.endsWith(suffix)) out.push(path);
  }
  return out.sort();
}

function sha256(text) {
  return `sha256:${createHash("sha256").update(text).digest("hex")}`;
}

function escapeTypstString(value) {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function escapeTypstContent(value) {
  return value.replace(/\[/g, "\\[").replace(/\]/g, "\\]");
}

function parseStringField(raw, name) {
  return new RegExp(`${name}\\s*:\\s*"([^"]+)"`).exec(raw)?.[1];
}

function parseContentField(raw, name) {
  return new RegExp(`${name}\\s*:\\s*\\[([^]*?)\\]\\s*,`, "m").exec(raw)?.[1]?.trim() ?? "";
}

function parseOptionalLine(raw, name) {
  return new RegExp(`^\\s*${name}\\s*:\\s*([^\\n]+),\\s*$`, "m").exec(raw)?.[0];
}

function parseTagBlock(raw) {
  return /tags\s*:\s*\(([^]*?)\),/m.exec(raw)?.[1] ?? "";
}

function findShowClose(lines) {
  let inShow = false;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (line.includes("#show:") && line.includes("main.with")) {
      inShow = true;
      continue;
    }
    if (inShow && line.trim() === ")") return i;
  }
  return -1;
}

function metadataBlock(lines, close) {
  const start = lines.findIndex((line) => line.includes("#show:") && line.includes("main.with"));
  return lines.slice(start, close + 1).join("\n");
}

function preambleBlock(lines) {
  const start = lines.findIndex((line) => line.includes("#show:") && line.includes("main.with"));
  return lines.slice(0, start).join("\n").trimEnd();
}

function parseFile(path, rootDir, kind) {
  const raw = readFileSync(path, "utf8");
  const relativeToKind = relative(rootDir, path).replaceAll("\\", "/");
  const [lang, ...rest] = relativeToKind.split("/");
  const pathKey = rest.join("/").replace(/\.typ$/, "");
  const lines = raw.split(/\r?\n/);
  const close = findShowClose(lines);
  if (close < 0) throw new Error(`${relative(root, path)}: cannot find #show: main.with metadata close`);
  const metadata = metadataBlock(lines, close);

  return {
    kind,
    path,
    rootDir,
    raw,
    preamble: preambleBlock(lines),
    hash: sha256(raw),
    lang,
    pathKey,
    body: lines.slice(close + 1).join("\n").trimStart(),
    title: parseStringField(metadata, "title") ?? "Untitled",
    desc: parseContentField(metadata, "desc"),
    date: parseStringField(metadata, "date") ?? "2024-01-01",
    updatedDateLine: parseOptionalLine(metadata, "updatedDate"),
    collectionLine: parseOptionalLine(metadata, "collection"),
    tagsBlock: parseTagBlock(metadata),
    i18nKey: parseStringField(metadata, "i18nKey") ?? pathKey,
    sourceLang: parseStringField(metadata, "sourceLang") ?? lang,
    translationStatus: parseStringField(metadata, "translationStatus") ?? defaultTranslationStatus,
  };
}

function targetLocale(source) {
  return source.lang === "zh" ? "en" : "zh";
}

function targetPath(source, to) {
  return join(source.rootDir, to, `${source.i18nKey}.typ`);
}

function readStatus(path) {
  if (!existsSync(path)) return null;
  return parseStringField(readFileSync(path, "utf8"), "translationStatus");
}

function renderMetadata(source, translated, to) {
  const importLine = source.preamble || (source.kind === "page" ? '#import "/templates/page.typ": *' : '#import "/templates/blog.typ": *\n#import "/templates/enums.typ": *');
  const optionalLines = [source.updatedDateLine, source.collectionLine].filter(Boolean).map((line) => `  ${line.trim()}`).join("\n");
  const tags = source.tagsBlock.trim() ? `\n${source.tagsBlock}\n  ` : "";
  const tagsField = `tags: (${tags}),`;
  return `${importLine}\n\n// @generated by scripts/i18n/translate.mjs\n// prompt_version: ${promptVersion}\n// model: ${model}\n// source: ${relative(root, source.path).replaceAll("\\", "/")}\n// source_sha256: ${source.hash}\n\n#show: main.with(\n  title: "${escapeTypstString(translated.title)}",\n  desc: [${escapeTypstContent(translated.desc)}],\n  date: "${source.date}",\n${optionalLines ? optionalLines + "\n" : ""}  ${tagsField}\n  lang: "${to}",\n  i18nKey: "${escapeTypstString(source.i18nKey)}",\n  sourceLang: "${source.sourceLang}",\n  translationSourceHash: "${source.hash}",\n  translationStatus: "machine",\n)\n\n${translated.body.trim()}\n`;
}

async function translate(source, to, apiKey) {
  const system = `You are translating a Typst blog source file for a bilingual personal website. Translate natural-language prose from ${source.lang} to ${to}. Preserve Typst syntax exactly: commands, imports, code fences, inline code/raw spans, URLs, image paths, math, labels, references, and tag identifiers. Translate headings, paragraphs, quote text, footnote prose, link labels, title, and description. Return strict JSON only.`;
  const user = JSON.stringify({
    targetLocale: to,
    title: source.title,
    description: source.desc,
    body: source.body,
    outputShape: { title: "translated title", desc: "translated description as Typst content without surrounding brackets", body: "translated Typst body only, no metadata imports" },
  });

  const requestBody = {
    model,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: system },
      { role: "user", content: user },
    ],
  };
  if (!model.startsWith("gpt-5")) {
    requestBody.temperature = 0.2;
  }

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OpenAI request failed ${response.status}: ${text.slice(0, 1000)}`);
  }

  const payload = await response.json();
  const content = payload.choices?.[0]?.message?.content;
  if (!content) throw new Error("OpenAI response did not include message content");
  const parsed = JSON.parse(content);
  const title = parsed.title ?? parsed["translated title"];
  const desc = parsed.desc ?? parsed.description ?? parsed["translated description"];
  const body = parsed.body ?? parsed["translated Typst body only, no metadata imports"];
  if (!title || !desc || !body) {
    throw new Error(`OpenAI response missing title/desc/body: ${content.slice(0, 500)}`);
  }
  return { title, desc, body };
}

const args = parseArgs(process.argv.slice(2));
if (!args.all && !args.key) {
  throw new Error("Pass --all or --key <i18nKey>");
}
const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) throw new Error("OPENAI_API_KEY is required");

const sources = [
  ...walkFiles(articleRoot, ".typ").map((path) => parseFile(path, articleRoot, "article")),
  ...walkFiles(pageRoot, ".typ").map((path) => parseFile(path, pageRoot, "page")),
].filter((item) => item.translationStatus === "source");

const selected = sources.filter((source) => {
  const to = args.to ?? targetLocale(source);
  if (args.from && source.lang !== args.from) return false;
  if (args.to && to !== args.to) return false;
  if (args.key && source.i18nKey !== args.key) return false;
  return args.all || source.i18nKey === args.key;
});

console.log(`Translating ${selected.length} source file(s) with ${model}. write=${args.write}`);

for (const source of selected) {
  const to = args.to ?? targetLocale(source);
  const outPath = targetPath(source, to);
  const status = readStatus(outPath);
  if (status === "reviewed" && !args.forceReviewed) {
    console.log(`skip reviewed ${relative(root, outPath)}`);
    continue;
  }
  if (existsSync(outPath)) {
    const existing = readFileSync(outPath, "utf8");
    const existingHash = parseStringField(existing, "translationSourceHash");
    if (existingHash === source.hash && status === "machine") {
      console.log(`fresh ${relative(root, outPath)}`);
      continue;
    }
  }

  console.log(`translate ${relative(root, source.path)} -> ${relative(root, outPath)}`);
  const translated = await translate(source, to, apiKey);
  const rendered = renderMetadata(source, translated, to);
  if (args.write) {
    mkdirSync(dirname(outPath), { recursive: true });
    writeFileSync(outPath, rendered);
  } else {
    console.log(rendered.slice(0, 1200));
  }
}

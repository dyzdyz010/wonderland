import type { APIContext } from "astro";
import { getCollection, type CollectionEntry } from "astro:content";
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";
import { mkdirSync, writeFileSync } from "node:fs";
import * as path from "node:path";
import { SITE_AUTHOR } from "../../consts";

export const prerender = true;

type BlogEntry = CollectionEntry<"blog">;

export async function getStaticPaths() {
  const posts = await getCollection("blog");

  return posts.map((post) => ({
    params: { slug: post.id },
    props: { post },
  }));
}

function escapeTypstString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function getArticleTypstPath(post: BlogEntry): string {
  return `/${post.filePath ?? `content/article/${post.id}.typ`}`;
}

function getArticleUrl(site: URL | undefined, post: BlogEntry): string {
  const base = site ?? new URL("https://dyz.io");
  return new URL(`/article/${post.id}/`, base).toString();
}

function getPdfFileName(post: BlogEntry): string {
  const lastSegment = post.id.split("/").at(-1) || "article";
  return `${lastSegment.replace(/[^\p{L}\p{N}._-]+/gu, "-")}.pdf`;
}

function renderStringTuple(values: string[]): string {
  if (values.length === 0) return "()";

  return `(${values.map((value) => `"${escapeTypstString(value)}"`).join(", ")},)`;
}

function renderArticlePdfSource(post: BlogEntry, sourceUrl: string): string {
  const description = post.data.description ?? "";
  const author = SITE_AUTHOR;
  const date = formatDate(post.data.date);
  const updatedDate = post.data.updatedDate ? `"${formatDate(post.data.updatedDate)}"` : "none";
  const tags = renderStringTuple(post.data.tags ?? []);
  const articlePath = getArticleTypstPath(post);
  const copyrightNotice = `© ${author}. Original article: ${sourceUrl}. All rights reserved unless otherwise noted.`;

  return `#import "/templates/article-pdf.typ": *

#show: main.with(
  title: "${escapeTypstString(post.data.title)}",
  desc: "${escapeTypstString(description)}",
  date: "${date}",
  updated_date: ${updatedDate},
  author: "${escapeTypstString(author)}",
  source_url: "${escapeTypstString(sourceUrl)}",
  tags: ${tags},
  copyright_notice: "${escapeTypstString(copyrightNotice)}",
)

#include "${escapeTypstString(articlePath)}"
`;
}

function writeGeneratedArticleSource(projectRoot: string, post: BlogEntry, sourceUrl: string): string {
  const generatedDir = path.join(projectRoot, ".astro", "generated-article-pdfs");
  mkdirSync(generatedDir, { recursive: true });

  const generatedFileName = `${post.id.replace(/[^a-zA-Z0-9._-]+/g, "__")}.typ`;
  const mainFilePath = path.join(generatedDir, generatedFileName);
  writeFileSync(mainFilePath, renderArticlePdfSource(post, sourceUrl));

  return mainFilePath;
}

function toArrayBuffer(buffer: Buffer): ArrayBuffer {
  return buffer.buffer.slice(
    buffer.byteOffset,
    buffer.byteOffset + buffer.byteLength,
  ) as ArrayBuffer;
}

export async function GET({ props, params, site }: APIContext<{ post: BlogEntry }>) {
  const projectRoot = process.cwd();
  const post = props.post;

  if (!post) {
    throw new Error(`[article-pdf] Missing post props for ${params.slug}`);
  }

  const compiler = NodeCompiler.create({ workspace: projectRoot });
  const sourceUrl = getArticleUrl(site, post);
  const mainFilePath = writeGeneratedArticleSource(projectRoot, post, sourceUrl);

  let pdfBuffer: Buffer;
  try {
    pdfBuffer = compiler.pdf({ mainFilePath });
  } catch (e: any) {
    console.error(`[article-pdf] Failed to compile ${post.id}: ${e?.code ?? e?.message ?? String(e)}`);
    throw e;
  }

  return new Response(toArrayBuffer(pdfBuffer), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${getPdfFileName(post)}"`,
    },
  });
}

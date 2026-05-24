import type { APIContext } from "astro";
import { getCollection } from "astro:content";
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";
import { mkdirSync, writeFileSync } from "node:fs";
import * as path from "node:path";
import { buildArchiveSummaries, type ArchiveSummary } from "../../../utils/archives";
import { getTypstCompilerOptions } from "../../../utils/typst-fonts";
import { assertLocale } from "../../../i18n/config";

export const prerender = true;

export async function getStaticPaths() {
  const posts = await getCollection("blog");
  return ["zh", "en"].flatMap((localeValue) => {
    const locale = assertLocale(localeValue);
    return buildArchiveSummaries(posts, locale).map((archive) => ({
      params: { locale, slug: archive.year },
      props: { archive },
    }));
  });
}

function escapeTypstString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function renderArchiveSource(archive: ArchiveSummary): string {
  const articles = archive.articles
    .map(
      (article) =>
        `    (title: "${escapeTypstString(article.title)}", date: "${article.date}", path: "${article.path}"),`,
    )
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

function writeGeneratedArchiveSource(projectRoot: string, archive: ArchiveSummary): string {
  const generatedDir = path.join(projectRoot, ".astro", "generated-archives", archive.locale);
  mkdirSync(generatedDir, { recursive: true });

  const mainFilePath = path.join(generatedDir, `${archive.year}.typ`);
  writeFileSync(mainFilePath, renderArchiveSource(archive));

  return mainFilePath;
}

function toArrayBuffer(buffer: Buffer): ArrayBuffer {
  return buffer.buffer.slice(
    buffer.byteOffset,
    buffer.byteOffset + buffer.byteLength,
  ) as ArrayBuffer;
}

export async function GET({ props, params }: APIContext<{ archive: ArchiveSummary }>) {
  const projectRoot = process.cwd();
  const archive = props.archive;

  if (!archive) {
    throw new Error(`[archive] Missing archive props for ${params.locale}/${params.slug}`);
  }

  const compiler = NodeCompiler.create(getTypstCompilerOptions(projectRoot));
  const mainFilePath = writeGeneratedArchiveSource(projectRoot, archive);

  let pdfBuffer: Buffer;
  try {
    pdfBuffer = compiler.pdf({ mainFilePath });
  } catch (e: any) {
    console.error(`[archive] Failed to compile ${archive.locale}/${archive.year}: ${e?.code ?? e?.message ?? String(e)}`);
    throw e;
  }

  return new Response(toArrayBuffer(pdfBuffer), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${archive.locale}-${archive.year}.pdf"`,
    },
  });
}

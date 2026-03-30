import type { APIContext } from "astro";
import { getCollection } from "astro:content";
import { NodeCompiler } from "@myriaddreamin/typst-ts-node-compiler";
import * as path from "node:path";

export const prerender = true;

export async function getStaticPaths() {
  const archives = await getCollection("archive");
  return archives.map((post) => ({
    params: { slug: post.id },
    props: post,
  }));
}

export async function GET({ params }: APIContext) {
  const projectRoot = process.cwd();
  const compiler = NodeCompiler.create({ workspace: projectRoot });
  const mainFilePath = path.join(
    projectRoot,
    "content",
    "archive",
    `${params.slug}.typ`
  );

  let pdfBuffer: Buffer;
  try {
    pdfBuffer = compiler.pdf({ mainFilePath });
  } catch (e: any) {
    console.error(`[archive] Failed to compile ${params.slug}: ${e?.code ?? e?.message ?? String(e)}`);
    throw e;
  }

  return new Response(pdfBuffer, {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `inline; filename="${params.slug}.pdf"`,
    },
  });
}

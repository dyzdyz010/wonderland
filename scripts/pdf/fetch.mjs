#!/usr/bin/env node
import { createWriteStream, existsSync, mkdirSync, rmSync } from "node:fs";
import { get } from "node:https";
import { execFileSync } from "node:child_process";
import { dirname, relative, resolve } from "node:path";
import {
  artifactArchiveName,
  artifactArchivePath,
  artifactReleaseTag,
  ownerRepo,
  pdfVersion,
  root,
} from "./lib.mjs";

const version = pdfVersion();
const name = artifactArchiveName(version);
const localArchive = artifactArchivePath(version);
const distDir = resolve(root, "dist");
const repo = ownerRepo();
const url = `https://github.com/${repo}/releases/download/${artifactReleaseTag}/${name}`;

function download(url, destination, redirects = 0) {
  return new Promise((resolvePromise, reject) => {
    const headers = { "User-Agent": "wonderland-pdf-fetch" };
    if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
    get(url, { headers }, (response) => {
      if ([301, 302, 303, 307, 308].includes(response.statusCode ?? 0) && response.headers.location) {
        response.resume();
        if (redirects > 5) reject(new Error(`Too many redirects downloading ${url}`));
        else resolvePromise(download(response.headers.location, destination, redirects + 1));
        return;
      }
      if (response.statusCode !== 200) {
        let body = "";
        response.setEncoding("utf8");
        response.on("data", (chunk) => { body += chunk; });
        response.on("end", () => reject(new Error(`HTTP ${response.statusCode} downloading ${url}: ${body.slice(0, 500)}`)));
        return;
      }
      mkdirSync(dirname(destination), { recursive: true });
      const file = createWriteStream(destination);
      response.pipe(file);
      file.on("finish", () => file.close(resolvePromise));
      file.on("error", reject);
    }).on("error", reject);
  });
}

console.log(`[pdf:fetch] version=${version}`);
console.log(`[pdf:fetch] release=${artifactReleaseTag}`);
console.log(`[pdf:fetch] target=${relative(root, distDir)}`);

let archive = localArchive;
if (!existsSync(archive)) {
  archive = resolve(root, ".pdf-artifacts", "download", name);
  rmSync(archive, { force: true });
  console.log(`[pdf:fetch] download=${url}`);
  try {
    await download(url, archive);
  } catch (error) {
    throw new Error([
      `[pdf:fetch] Missing PDF artifact for ${version}.`,
      `Expected asset: ${url}`,
      "Generate and publish it before deploying:",
      "  bun run pdf:generate",
      "  bun run pdf:publish",
      `Original error: ${error?.message ?? String(error)}`,
    ].join("\n"));
  }
} else {
  console.log(`[pdf:fetch] using local archive=${relative(root, archive)}`);
}

mkdirSync(distDir, { recursive: true });
execFileSync("tar", ["-xzf", archive, "-C", distDir], { stdio: "inherit" });
console.log("[pdf:fetch] extracted PDFs into dist");

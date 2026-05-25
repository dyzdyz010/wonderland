#!/usr/bin/env node
import { existsSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { relative } from "node:path";
import {
  artifactArchivePath,
  artifactManifestPath,
  artifactReleaseTag,
  packArtifact,
  pdfVersion,
  root,
} from "./lib.mjs";

const version = pdfVersion();
const archivePath = existsSync(artifactArchivePath(version)) ? artifactArchivePath(version) : packArtifact(version);
const manifestPath = artifactManifestPath(version);

function gh(args, options = {}) {
  return execFileSync("gh", args, { stdio: "inherit", ...options });
}

console.log(`[pdf:publish] version=${version}`);
console.log(`[pdf:publish] release=${artifactReleaseTag}`);
console.log(`[pdf:publish] archive=${relative(root, archivePath)}`);

try {
  execFileSync("gh", ["release", "view", artifactReleaseTag], { stdio: "ignore" });
} catch {
  gh([
    "release",
    "create",
    artifactReleaseTag,
    "--title",
    "PDF artifacts",
    "--notes",
    "Versioned generated PDF artifacts for Wonderland deployments.",
  ]);
}

const uploadTargets = [archivePath];
if (existsSync(manifestPath)) uploadTargets.push(manifestPath);
gh(["release", "upload", artifactReleaseTag, ...uploadTargets, "--clobber"]);
console.log("[pdf:publish] uploaded");

#!/usr/bin/env node
import { pdfInputFiles, pdfVersion, root } from "./lib.mjs";
import { relative } from "node:path";

const version = pdfVersion();
console.log(version);

if (process.argv.includes("--verbose")) {
  console.error("\nPDF version inputs:");
  for (const file of pdfInputFiles()) {
    console.error(`- ${relative(root, file).replaceAll("\\", "/")}`);
  }
}

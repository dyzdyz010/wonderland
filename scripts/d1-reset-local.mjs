#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const database = process.argv.find((arg, index) => index >= 2 && !arg.startsWith("-")) ?? "wonderland";
const includeSeed = process.argv.includes("--seed");
const wranglerBin = existsSync(resolve(process.cwd(), "node_modules/.bin/wrangler"))
  ? resolve(process.cwd(), "node_modules/.bin/wrangler")
  : "wrangler";

function runWrangler(label, args) {
  console.log(label);
  const result = spawnSync(wranglerBin, args, {
    stdio: "inherit",
    shell: false,
  });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  if ((result.status ?? 1) !== 0) process.exit(result.status ?? 1);
}

function runLocalSql(label, sql) {
  const trimmed = sql.trim();
  if (!trimmed) return;
  runWrangler(`Executing ${label} on local D1 database "${database}"...`, [
    "d1",
    "execute",
    database,
    "--local",
    `--command=${trimmed}`,
  ]);
}

runLocalSql(
  "local destructive reset",
  `DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS d1_migrations;`,
);

runWrangler(`Applying migrations to local D1 database "${database}"...`, [
  "d1",
  "migrations",
  "apply",
  database,
  "--local",
]);

if (includeSeed) {
  runLocalSql("seeds/comments.dev.sql", readFileSync(resolve(process.cwd(), "seeds/comments.dev.sql"), "utf8"));
}

console.log("Local D1 comments database reset complete.");

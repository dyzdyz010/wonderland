#!/usr/bin/env node

import { existsSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const usage = `Usage:
  node scripts/d1-execute-sql.mjs [database] [--local|--remote] [sql-file]

Examples:
  node scripts/d1-execute-sql.mjs
  node scripts/d1-execute-sql.mjs wonderland --local ./migrations/0001_init.sql
  node scripts/d1-execute-sql.mjs wonderland --remote ./migrations/0001_init.sql
`;

const args = process.argv.slice(2);

let database = "wonderland";
let mode = "--local";
let sqlFile = "./migrations/0001_init.sql";

for (const arg of args) {
  if (arg === "--help" || arg === "-h") {
    console.log(usage.trim());
    process.exit(0);
  }

  if (arg === "--local" || arg === "--remote") {
    mode = arg;
    continue;
  }

  if (arg.endsWith(".sql")) {
    sqlFile = arg;
    continue;
  }

  database = arg;
}

const sqlPath = resolve(process.cwd(), sqlFile);

if (!existsSync(sqlPath)) {
  console.error(`SQL file not found: ${sqlPath}`);
  process.exit(1);
}

const sql = readFileSync(sqlPath, "utf8").trim();

if (!sql) {
  console.error(`SQL file is empty: ${sqlPath}`);
  process.exit(1);
}

const isDestructive = /\b(drop|delete|truncate|alter)\b/i.test(sql);

if (mode === "--remote" && isDestructive) {
  const message = [
    "Refusing to run a destructive SQL file against remote D1.",
    `Database: ${database}`,
    `SQL file: ${sqlPath}`,
    "This helper is meant for local development resets. Split schema migrations",
    "from seed/reset SQL before running remote migrations.",
    "To override intentionally, set ALLOW_DESTRUCTIVE_REMOTE_D1=1.",
  ].join("\n");

  if (process.env.ALLOW_DESTRUCTIVE_REMOTE_D1 !== "1") {
    console.error(message);
    process.exit(1);
  }

  console.warn(`ALLOW_DESTRUCTIVE_REMOTE_D1=1 set. ${message}`);
}

console.log(`Executing ${sqlFile} on D1 database "${database}" (${mode})...`);

// Use --command instead of --file. With wrangler 4.33.1 on this machine,
// `wrangler d1 execute --file=...` can fail with:
//   A FileHandle object was closed during garbage collection
// Passing SQL as an argv value avoids shell quoting issues and the --file path.
const result = spawnSync(
  "wrangler",
  ["d1", "execute", database, mode, "--command", sql],
  {
    stdio: "inherit",
    shell: false,
  },
);

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}

process.exit(result.status ?? 1);

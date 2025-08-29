/// <reference types="astro/client" />

type ENV = {
  // Replace `MY_KV` with the actual name of your KV namespace binding
  MY_KV: KVNamespace;
  // Add other Cloudflare bindings (e.g., R2Bucket, D1Database) here
  // MY_BUCKET: R2Bucket;
  // MY_DB: D1Database;
};

// Use a default runtime configuration (advanced mode)
type Runtime = import("@astrojs/cloudflare").Runtime<ENV>;

declare namespace App {
  interface Locals extends Runtime {}
}

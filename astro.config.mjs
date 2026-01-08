// @ts-check
import { defineConfig } from "astro/config";
import { typst } from "astro-typst";
import tailwindcss from "@tailwindcss/vite";
import icon from "astro-icon";

import sitemap from "@astrojs/sitemap";

import cloudflare from "@astrojs/cloudflare";

// https://astro.build/config
export default defineConfig({
  site: "https://dyz.io",
  output: "server",

  integrations: [
    icon(),
    typst({
      // Always builds HTML files
      target: "html",
    }),
    sitemap(),
  ],

  vite: {
    plugins: [tailwindcss()],
    server: {
      watch: {
        // 在 WSL2 环境下使用轮询模式，确保能检测到文件变化
        usePolling: true,
        interval: 1000,
        ignored: ['!**/templates/**'],
      },
    },
    build: {
      assetsInlineLimit(filePath, content) {
        const KB = 1024;
        return content.length < (filePath.endsWith(".css") ? 100 * KB : 4 * KB);
      },
    },
    ssr: {
      external: [
        "@myriaddreamin/typst-ts-node-compiler",
        "node:fs",
        "node:fs/promises",
        "node:path",
        "node:url",
        "node:crypto",
      ],
      noExternal: ["@fontsource-variable/inter"],
    },
  },

  adapter: cloudflare({
    platformProxy: {
      enabled: true,
    },
  }),
});

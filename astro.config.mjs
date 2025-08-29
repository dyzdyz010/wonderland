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
    build: {
      assetsInlineLimit(filePath, content) {
        const KB = 1024;
        return content.length < (filePath.endsWith(".css") ? 100 * KB : 4 * KB);
      },
    },
    ssr: {
      external: ["@myriaddreamin/typst-ts-node-compiler"],
      noExternal: ["@fontsource-variable/inter"],
    },
  },

  adapter: cloudflare({
    platformProxy: {
      enabled: true,
    },
  }),
});

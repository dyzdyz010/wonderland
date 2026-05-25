import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

import { DEFAULT_TRANSLATION_STATUS } from "./i18n/translation";

const localizedContentSchema = z.object({
  title: z.string(),
  author: z.string().optional(),
  description: z.string().optional(),
  date: z.coerce.date(),
  updatedDate: z.coerce.date().optional(),
  tags: z.array(z.string()).optional(),
  collection: z.string().optional(),
  lang: z.enum(["zh", "en"]),
  i18nKey: z.string(),
  sourceLang: z.enum(["zh", "en"]).optional(),
  translationStatus: z.enum(["source", "machine", "reviewed"]).default(DEFAULT_TRANSLATION_STATUS),
  translationSourceHash: z.string().optional(),
});

const blog = defineCollection({
  loader: glob({ base: "./content/article", pattern: "**/*.typ" }),
  schema: localizedContentSchema,
});

const page = defineCollection({
  loader: glob({ base: "./content/page", pattern: "**/*.typ" }),
  schema: localizedContentSchema,
});

export const collections = { blog, page };

import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
	// Load Markdown and MDX files in the `src/content/blog/` directory.
	loader: glob({ base: './content/article', pattern: '**/*.typ' }),
	// Type-check frontmatter using a schema
	schema: z.object({
		title: z.string(),
		author: z.string().optional(),
		description: z.string().optional(),
		// Transform string to Date object
		date: z.coerce.date(),
		updatedDate: z.coerce.date().optional(),
		tags: z.array(z.string()).optional(),
		collection: z.string().optional(),
	})
});

export const collections = { blog };

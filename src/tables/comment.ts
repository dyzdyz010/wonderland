import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

const commentsTable = sqliteTable("comments", {
  id: integer("id").primaryKey(),
  post_slug: text("post_slug").notNull(),
  author_name: text("author_name").notNull(),
  author_email: text("author_email").notNull(),
  author_url: text("author_url").notNull(),
  content: text("content").notNull(),
  created_at: integer("created_at").notNull(),
  status: text("status").notNull(),
  parent_id: integer("parent_id"),
  ip_hash: text("ip_hash"),
});

export { commentsTable };

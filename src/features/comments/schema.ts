import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

export const COMMENT_STATUSES = ["pending", "approved", "spam", "deleted"] as const;
export type CommentStatus = (typeof COMMENT_STATUSES)[number];

export const commentsTable = sqliteTable("comments", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  // Legacy path key kept for compatibility with the original D1 table.
  // New code writes the same logical value to thread_key and post_slug.
  post_slug: text("post_slug").notNull(),
  thread_key: text("thread_key").notNull(),
  author_name: text("author_name").notNull(),
  // Legacy column kept empty by new writes. Prefer email_hash.
  author_email: text("author_email").notNull(),
  email_hash: text("email_hash"),
  author_url: text("author_url"),
  content: text("content").notNull(),
  status: text("status").notNull(),
  created_at: integer("created_at").notNull(),
  updated_at: integer("updated_at").notNull(),
  parent_id: integer("parent_id"),
  ip_hash: text("ip_hash"),
  user_agent_hash: text("user_agent_hash"),
});

export type CommentRow = typeof commentsTable.$inferSelect;
export type NewCommentRow = typeof commentsTable.$inferInsert;

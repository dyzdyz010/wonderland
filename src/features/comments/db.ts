import { and, asc, eq } from "drizzle-orm";
import { drizzle } from "drizzle-orm/d1";
import { commentsTable, type CommentRow, type NewCommentRow } from "./schema";
import { normalizeCommentThreadKey } from "./validation";

type RuntimeEnv = {
  DB?: D1Database;
};

export async function insertComment(env: RuntimeEnv, values: NewCommentRow): Promise<void> {
  if (!env.DB) throw new Error("D1 binding DB is not configured");
  const db = drizzle(env.DB);
  await db.insert(commentsTable).values(values);
}

export async function listApprovedComments(env: RuntimeEnv, threadKey: string): Promise<CommentRow[]> {
  if (!env.DB) throw new Error("D1 binding DB is not configured");
  const normalizedThreadKey = normalizeCommentThreadKey(threadKey);
  const db = drizzle(env.DB);
  return db
    .select()
    .from(commentsTable)
    .where(and(eq(commentsTable.thread_key, normalizedThreadKey), eq(commentsTable.status, "approved")))
    .orderBy(asc(commentsTable.created_at));
}

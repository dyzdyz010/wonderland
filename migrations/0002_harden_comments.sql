-- Harden the original comments prototype schema without destroying data.
-- This migration is forward-only: do not edit after applying to production D1.

ALTER TABLE comments ADD COLUMN thread_key TEXT NOT NULL DEFAULT '';
UPDATE comments SET thread_key = post_slug WHERE thread_key = '';

ALTER TABLE comments ADD COLUMN status TEXT NOT NULL DEFAULT 'approved';
ALTER TABLE comments ADD COLUMN email_hash TEXT;
ALTER TABLE comments ADD COLUMN user_agent_hash TEXT;
ALTER TABLE comments ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0;
UPDATE comments SET updated_at = created_at WHERE updated_at = 0;

CREATE INDEX IF NOT EXISTS idx_comments_thread_status_created
  ON comments (thread_key, status, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_comments_parent_id
  ON comments (parent_id);

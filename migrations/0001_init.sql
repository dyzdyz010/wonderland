CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  post_slug TEXT NOT NULL DEFAULT '', -- legacy route/thread key kept for compatibility
  author_name TEXT NOT NULL,
  author_email TEXT NOT NULL DEFAULT '', -- legacy column; new writes keep this empty and use email_hash
  author_url TEXT,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000),
  parent_id INTEGER,
  ip_hash TEXT
);

CREATE INDEX IF NOT EXISTS idx_comments_post_created
  ON comments (post_slug, created_at DESC);

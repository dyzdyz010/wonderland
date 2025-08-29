CREATE TABLE
    IF NOT EXISTS comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_slug TEXT NOT NULL, -- 文章唯一标识/slug
        author_name TEXT NOT NULL,
        author_email TEXT NOT NULL,
        author_url TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (unixepoch ()),
        status TEXT NOT NULL DEFAULT 'approved', -- 也可做人工审核
        parent_id INTEGER,
        ip_hash TEXT
    );

CREATE INDEX IF NOT EXISTS idx_comments_post_created ON comments (post_slug, created_at DESC);

INSERT INTO comments (post_slug, author_name, author_email, author_url, content) VALUES ('test-slug', 'John Doe', 'john.doe@example.com', 'https://example.com', 'This is a test comment');
INSERT INTO comments (post_slug, author_name, author_email, author_url, content) VALUES ('test-slug', 'John Doe', 'john.doe@example.com', 'https://example.com', 'This is a test comment');
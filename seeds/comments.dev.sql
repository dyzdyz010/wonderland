INSERT INTO comments (
  post_slug,
  thread_key,
  author_name,
  author_email,
  email_hash,
  author_url,
  content,
  status,
  created_at,
  updated_at
) VALUES (
  'test-slug',
  'test-slug',
  'John Doe',
  '',
  '836f82db99121b3481011f1ca9d538f860d2cf9c7ef251b776912a9c3575d0b7',
  'https://example.com',
  'This is a local development test comment.',
  'approved',
  unixepoch() * 1000,
  unixepoch() * 1000
);

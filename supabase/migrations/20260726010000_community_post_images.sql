-- Storage object path in the public `community-post-images` bucket. The path
-- is a bare generated filename (no phone number or other identifier) since
-- the bucket is public and the path is embedded in the returned image URL.
alter table public.community_posts
  add column if not exists image_path text;

-- Community posts are already served in full (author label, content, tags)
-- by the unauthenticated `/api/community/posts` feed, so a public bucket for
-- attached photos matches the existing privacy model. Only the upload path
-- is authenticated (server-side, via the service role key); reads are public.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'community-post-images',
  'community-post-images',
  true,
  6291456,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Community authorship privacy.
--
-- `community_posts.author` and `community_replies.author` are public display
-- labels served by the unauthenticated `/api/community/posts` endpoint, but the
-- app previously stored the signed-in user's phone number there. Split the
-- private authorship key out into `author_phone` so the public label can never
-- hold a phone number.
--
-- Existing rows are migrated by `server/scripts/backfill-community-authors.js`,
-- which needs the users table to resolve display names and so cannot run here.

alter table public.community_posts
  add column if not exists author_phone text;

alter table public.community_replies
  add column if not exists author_phone text;

create index if not exists idx_community_posts_author_phone
  on public.community_posts (author_phone);

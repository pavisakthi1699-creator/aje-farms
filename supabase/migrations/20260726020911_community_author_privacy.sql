-- Community authorship privacy.
--
-- `community_posts.author` and `community_replies.author` are public display
-- labels served by the unauthenticated /api/community/posts endpoint. The
-- signed-in user's phone number must never land there, so the private
-- authorship key moves to `author_phone`.
--
-- Additive and nullable: the currently deployed build ignores these columns,
-- so this is safe to apply before the new server code ships.

alter table public.community_posts
  add column if not exists author_phone text;

alter table public.community_replies
  add column if not exists author_phone text;

create index if not exists idx_community_posts_author_phone
  on public.community_posts (author_phone);;

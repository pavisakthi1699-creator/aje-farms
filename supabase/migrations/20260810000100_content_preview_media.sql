-- Public preview assets are intentionally separate from private source PDFs
-- and enrolled-learner lesson videos.
alter table public.courses
  add column if not exists cover_image_url text,
  add column if not exists intro_video_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'content-media', 'content-media', true, 209715200,
  array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime', 'video/webm']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

begin;

insert into public.content_course_revisions (
  course_id,
  previous_status,
  previous_payload,
  reason
)
select
  cc.id,
  cc.status,
  cc.payload,
  '2026-07-16: hide unverified catalogue and remove learner quiz/checklist/faq/pdf entries'
from public.content_courses cc
where not exists (
  select 1
  from public.content_course_revisions revision
  where revision.course_id = cc.id
    and revision.reason = '2026-07-16: hide unverified catalogue and remove learner quiz/checklist/faq/pdf entries'
);

update public.content_courses cc
set
  status = 'draft',
  payload = jsonb_set(
    cc.payload,
    '{lessons}',
    coalesce(
      (
        select jsonb_agg(lesson order by lesson_order)
        from (
          select lesson, lesson_order
          from jsonb_array_elements(coalesce(cc.payload->'lessons', '[]'::jsonb))
            with ordinality as item(lesson, lesson_order)
          where lesson->>'type' in ('reading', 'video')
        ) supported
      ),
      '[]'::jsonb
    ),
    true
  ),
  updated_at = now();

update public.content_documents
set status = 'draft',
    updated_at = now()
where status <> 'draft';

update public.courses
set status = 'draft',
    published_at = null,
    updated_at = now()
where status in ('approved', 'published')
  and source_link_status <> 'linked';

update public.course_modules
set status = 'draft',
    published_at = null,
    updated_at = now()
where status in ('approved', 'published')
  and source_link_status <> 'linked';

update public.lessons
set status = case when risk_level = 'high' then 'needs_review'::public.content_status else 'draft'::public.content_status end,
    published_at = null,
    updated_at = now()
where status in ('approved', 'published')
   or lesson_type not in ('reading', 'video');

update public.lessons
set lesson_type = case
      when lesson_type = 'video' then 'video'
      else 'reading'
    end,
    updated_at = now()
where lesson_type not in ('reading', 'video');

update public.lesson_resources
set status = 'draft',
    updated_at = now()
where status <> 'draft';

update public.curriculum_staging_rows
set promotion_result = coalesce(promotion_result, '{}'::jsonb) || jsonb_build_object(
      'ignored', true,
      'reason', 'Quizzes are not part of the AJE Farms learner content model.'
    ),
    updated_at = now()
where item_type = 'quiz';

commit;

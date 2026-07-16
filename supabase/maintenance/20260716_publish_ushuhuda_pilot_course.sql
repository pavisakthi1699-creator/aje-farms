-- Publish one source-reviewed text course as the end-to-end ingestion pilot.
-- Scope is intentionally limited to three lessons whose statements are
-- directly supported by the cited pages of Ushuhuda Wangu, Toleo la 4.

begin;

insert into public.content_course_revisions (
  course_id,
  previous_status,
  previous_payload,
  reason
)
select
  c.code,
  c.status::text,
  jsonb_build_object(
    'course', to_jsonb(c),
    'modules', (
      select coalesce(jsonb_agg(to_jsonb(m) order by m.sort_order), '[]'::jsonb)
      from public.course_modules m
      where m.course_id = c.id
    ),
    'lessons', (
      select coalesce(jsonb_agg(to_jsonb(l) order by m.sort_order, l.sort_order), '[]'::jsonb)
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where m.course_id = c.id
    ),
    'facts', (
      select coalesce(jsonb_agg(to_jsonb(gf) order by gf.external_id), '[]'::jsonb)
      from public.grounding_facts gf
      where gf.course_id = c.id
    )
  ),
  '2026-07-16: before publishing the three-lesson Ushuhuda source-review pilot'
from public.courses c
where c.code = 'CRS-USH-01'
  and not exists (
    select 1
    from public.content_course_revisions revision
    where revision.course_id = c.code
      and revision.reason =
        '2026-07-16: before publishing the three-lesson Ushuhuda source-review pilot'
  );

update public.source_documents
set processing_status = 'published',
    updated_at = now()
where id = 'cefcf001-b03e-4ff2-bd4c-a6b4471d664b';

update public.source_segments
set review_status = 'published',
    risk_level = 'medium',
    reviewed_at = now(),
    updated_at = now()
where id in (
  '83217158-7b15-4688-a902-52be0a2f3b54',
  '9f5f29f4-ed7c-4bb7-8dbd-ac2ebde34348',
  'ea61cb6f-57c6-4b64-9e8d-1469aa6d3c01'
);

update public.courses
set title_sw = 'Misingi ya Ujasiriamali wa Kilimo',
    summary_sw =
      'Mafunzo matatu kutoka Ushuhuda Wangu kuhusu kuanza kidogo, kilimo mseto, na nguzo za mfumo, watu na bidhaa.',
    description_sw =
      'Kozi hii inawasilisha uzoefu wa mwandishi wa Ushuhuda Wangu. Inasaidia kutafakari biashara ya kilimo; si ushauri binafsi wa kifedha.',
    delivery_type = 'text',
    status = 'published',
    risk_level = 'normal',
    source_link_status = 'linked',
    published_at = now(),
    updated_at = now()
where code = 'CRS-USH-01';

update public.course_modules
set title_sw = 'Misingi Mitatu ya Biashara ya Kilimo',
    summary_sw =
      'Anza kwa kiwango kinachodhibitika, punguza utegemezi wa zao moja, na jenga mfumo unaounganisha watu na bidhaa.',
    status = 'published',
    risk_level = 'normal',
    source_link_status = 'linked',
    published_at = now(),
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-USH-01')
  and code = 'mod-ush-02';

update public.course_modules
set status = 'archived',
    published_at = null,
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-USH-01')
  and code <> 'mod-ush-02';

update public.lessons
set module_id = (select id from public.course_modules where code = 'mod-ush-02'),
    title_sw = 'Anza Kidogo na Ujifunze Biashara',
    body_sw =
      'Mwandishi anaeleza kuwa kusubiri mtaji kamili kunaweza kuchelewesha kuanza. Katika uzoefu wake, alianza kwa kiwango kidogo na kurekebisha mapungufu kadiri alivyoendelea. Anashauri mtu asiweke mtaji wote mara moja kwenye biashara ambayo bado haijui; aanze kwa sehemu ndogo, ajifunze namna biashara inavyofanya kazi, kisha aamue kama apanue. Somo hili ni tafakari ya uzoefu wa mwandishi, si ushauri binafsi wa uwekezaji au mkopo.',
    lesson_type = 'reading',
    duration_minutes = 4,
    status = 'published',
    risk_level = 'normal',
    source_link_status = 'linked',
    sort_order = 10,
    published_at = now(),
    updated_at = now()
where code = 'lsn-ush-001';

update public.lessons
set module_id = (select id from public.course_modules where code = 'mod-ush-02'),
    title_sw = 'Kilimo Mseto na Mapato ya Nyakati Tofauti',
    body_sw =
      'Kwa mujibu wa uzoefu wa mwandishi, kuwa na mazao au shughuli tofauti kunaweza kuleta mapato katika nyakati tofauti badala ya kusubiri msimu mmoja. Anaeleza pia tukio la mwaka 2018 ambapo bei ya nyanya ilikuwa chini ya matarajio, lakini zao jingine lilisaidia kupunguza athari ya hasara. Kilimo mseto hakiondoi hatari zote; uchaguzi wa mazao unahitaji kuzingatia eneo, soko, uwezo wa usimamizi na ushauri wa kitaalamu.',
    lesson_type = 'reading',
    duration_minutes = 5,
    status = 'published',
    risk_level = 'normal',
    source_link_status = 'linked',
    sort_order = 20,
    published_at = now(),
    updated_at = now()
where code = 'lsn-ush-002';

update public.lessons
set module_id = (select id from public.course_modules where code = 'mod-ush-02'),
    title_sw = 'Nguzo Tatu: Mfumo, Watu na Bidhaa',
    body_sw =
      'Mwandishi anatumia mfano wa biashara ya chakula kueleza nguzo tatu: Process, People na Product. Process ni mchakato mzima wa kazi, kuanzia maandalizi hadi kumfikia mteja. People ni watu sahihi wenye majukumu, maarifa na uongozi. Product ni bidhaa au huduma inayotolewa. Katika mfano wake, bidhaa na timu vilikuwepo, lakini udhaifu wa mchakato wa usambazaji uliifanya biashara ishindwe kuwafikia wateja kwa wakati.',
    lesson_type = 'reading',
    duration_minutes = 5,
    status = 'published',
    risk_level = 'normal',
    source_link_status = 'linked',
    sort_order = 30,
    published_at = now(),
    updated_at = now()
where code = 'mod-ush-03-reading-01';

update public.lessons
set status = 'archived',
    published_at = null,
    updated_at = now()
where id in (
  select l.id
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  where m.course_id = (select id from public.courses where code = 'CRS-USH-01')
)
and code not in (
  'lsn-ush-001',
  'lsn-ush-002',
  'mod-ush-03-reading-01'
);

delete from public.content_source_links
where content_type = 'lesson'
  and content_id in (
    select l.id
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    where m.course_id = (select id from public.courses where code = 'CRS-USH-01')
      and l.code in ('lsn-ush-001', 'lsn-ush-002', 'mod-ush-03-reading-01')
  );

insert into public.content_source_links (
  content_type,
  content_id,
  source_segment_id,
  source_document_id,
  link_status,
  evidence_note,
  updated_at
)
select
  'lesson',
  l.id,
  mapping.source_segment_id,
  ss.source_document_id,
  'linked',
  mapping.evidence_note,
  now()
from (
  values
    (
      'lsn-ush-001',
      '83217158-7b15-4688-a902-52be0a2f3b54'::uuid,
      'Ushuhuda Wangu, kurasa 80-81: kuanza kidogo na kujifunza biashara.'
    ),
    (
      'lsn-ush-002',
      '9f5f29f4-ed7c-4bb7-8dbd-ac2ebde34348'::uuid,
      'Ushuhuda Wangu, kurasa 82-84: kilimo mseto na mapato ya nyakati tofauti.'
    ),
    (
      'mod-ush-03-reading-01',
      'ea61cb6f-57c6-4b64-9e8d-1469aa6d3c01'::uuid,
      'Ushuhuda Wangu, kurasa 151-155: Process, People na Product.'
    )
) as mapping(lesson_code, source_segment_id, evidence_note)
join public.lessons l on l.code = mapping.lesson_code
join public.source_segments ss on ss.id = mapping.source_segment_id
on conflict (content_type, content_id, source_segment_id) do update
set link_status = excluded.link_status,
    evidence_note = excluded.evidence_note,
    updated_at = now();

delete from public.content_source_links
where (
    content_type = 'course'
    and content_id = (select id from public.courses where code = 'CRS-USH-01')
  )
  or (
    content_type = 'module'
    and content_id = (select id from public.course_modules where code = 'mod-ush-02')
  );

insert into public.content_source_links (
  content_type,
  content_id,
  source_segment_id,
  source_document_id,
  link_status,
  evidence_note,
  updated_at
)
select
  target.content_type,
  target.content_id,
  ss.id,
  ss.source_document_id,
  'linked',
  'Reviewed pilot course evidence from Ushuhuda Wangu.',
  now()
from (
  select 'course'::text as content_type, c.id as content_id
  from public.courses c
  where c.code = 'CRS-USH-01'
  union all
  select 'module'::text, m.id
  from public.course_modules m
  where m.code = 'mod-ush-02'
) target
cross join public.source_segments ss
where ss.id in (
  '83217158-7b15-4688-a902-52be0a2f3b54',
  '9f5f29f4-ed7c-4bb7-8dbd-ac2ebde34348',
  'ea61cb6f-57c6-4b64-9e8d-1469aa6d3c01'
)
on conflict (content_type, content_id, source_segment_id) do update
set link_status = excluded.link_status,
    evidence_note = excluded.evidence_note,
    updated_at = now();

update public.grounding_facts
set lesson_id = (select id from public.lessons where code = 'lsn-ush-001'),
    code = 'ush-start-small',
    question_sw = 'Mwandishi anashauri mtu aanzaje biashara mpya?',
    fact_sw =
      'Mwandishi anashauri kuanza kwa kiwango kidogo, kujifunza biashara na kurekebisha mapungufu kabla ya kuongeza mtaji.',
    status = 'published',
    risk_level = 'medium',
    reviewed_at = now(),
    updated_at = now()
where external_id = 'FAQ-USH-001';

update public.grounding_facts
set lesson_id = (select id from public.lessons where code = 'lsn-ush-002'),
    code = 'ush-mixed-farming',
    question_sw = 'Mwandishi anaeleza faida gani ya kilimo mseto?',
    fact_sw =
      'Katika uzoefu wa mwandishi, shughuli tofauti zinaweza kuleta mapato kwa nyakati tofauti na kupunguza athari ya hasara ya zao moja.',
    status = 'published',
    risk_level = 'medium',
    reviewed_at = now(),
    updated_at = now()
where external_id = 'FAQ-USH-003';

update public.grounding_facts
set lesson_id = (
      select id from public.lessons where code = 'mod-ush-03-reading-01'
    ),
    code = 'ush-three-business-pillars',
    question_sw = 'Nguzo tatu za biashara katika mfano wa mwandishi ni zipi?',
    fact_sw =
      'Nguzo tatu katika mfano wa mwandishi ni Process (mfumo au mchakato), People (watu au timu) na Product (bidhaa au huduma).',
    status = 'published',
    risk_level = 'medium',
    reviewed_at = now(),
    updated_at = now()
where external_id = 'FAQ-USH-008';

update public.grounding_facts
set status = 'archived',
    reviewed_at = null,
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-USH-01')
  and external_id not in ('FAQ-USH-001', 'FAQ-USH-003', 'FAQ-USH-008');

commit;

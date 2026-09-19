-- Publish a narrow, source-reviewed poultry biosecurity course.
-- Treatment recipes, diagnosis claims, quizzes, and fixed vaccine schedules
-- remain unpublished because they require veterinary and local regulatory review.

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
      select coalesce(
        jsonb_agg(to_jsonb(l) order by m.sort_order, l.sort_order),
        '[]'::jsonb
      )
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where m.course_id = c.id
    ),
    'grounding_facts', (
      select coalesce(
        jsonb_agg(to_jsonb(gf) order by gf.external_id),
        '[]'::jsonb
      )
      from public.grounding_facts gf
      where gf.course_id = c.id
    )
  ),
  '2026-07-16: before publishing the three-lesson poultry biosecurity pilot'
from public.courses c
where c.code = 'CRS-KUK-02'
  and not exists (
    select 1
    from public.content_course_revisions revision
    where revision.course_id = c.code
      and revision.reason =
        '2026-07-16: before publishing the three-lesson poultry biosecurity pilot'
  );

update public.source_documents
set page_count = 30,
    processing_status = 'approved',
    updated_at = now()
where id = '0df42d11-2747-4b7f-a4c9-f045f577ead4'
  and file_name = 'MAGONJWA YA KUKU TIBA ZAKE ZA ASILI.pdf';

insert into public.source_segments (
  source_document_id,
  page_start,
  page_end,
  section_title,
  segment_order,
  content_sw,
  content_hash,
  extraction_method,
  review_status,
  risk_level,
  reviewed_at,
  updated_at
)
values
  (
    '0df42d11-2747-4b7f-a4c9-f045f577ead4',
    12,
    12,
    'Kutenga kuku wapya na kutumia viatu vya banda',
    1,
    'Kuku wageni au kuku wa jirani wanaweza kuwa na maambukizi na kuyaeneza kwa kuku wako. Kama unataka kuingiza kuku wapya, watenge na kuku wako kwa muda wa wiki mbili au zaidi na uwachunguze dalili za ugonjwa. Tenga pia viatu au ndala zinazotumika kwa ajili ya kuingia bandani pekee.',
    '96f8967dd041a7ab4268420923cfa8097b183d7eb54a5a826beb2b64bbe2e146',
    'manual_pdf_review',
    'published',
    'medium',
    now(),
    now()
  ),
  (
    '0df42d11-2747-4b7f-a4c9-f045f577ead4',
    23,
    24,
    'Ratiba ya usafi, vifaa na mavazi ya kinga',
    2,
    'Panga ratiba za kila siku na kila juma za usafi. Ondoa kinyesi na takataka, hakikisha mzunguko mzuri wa hewa, kagua maji na malisho, badilisha matandazo machafu, safisha vifaa, na tumia mavazi ya kinga. Eneo la kuosha viatu karibu na mlango wa banda husaidia kuzuia kuleta vumbi au vijidudu ndani.',
    '8d9f114e92e3844511b2b419f348873a6acf742335baf39e9f372127ff6add7a',
    'manual_pdf_review',
    'published',
    'medium',
    now(),
    now()
  ),
  (
    '0df42d11-2747-4b7f-a4c9-f045f577ead4',
    27,
    27,
    'Ufuatiliaji wa afya na kumbukumbu',
    3,
    'Fanya uchunguzi wa mara kwa mara na uangalizi wa kila siku kwa kuangalia manyoya, tabia, uzito, ngozi na namna kuku wanavyotembea. Weka kumbukumbu za chanjo, matibabu na matokeo ya uchunguzi. Dalili za kiafya zinapojitokeza, wasiliana na mtaalamu wa mifugo kwa ushauri na matibabu.',
    '0afa8cd7e26b77a3981b19c4e2a325407da273bf3ca3782986dd284baaa4ff5a',
    'manual_pdf_review',
    'published',
    'medium',
    now(),
    now()
  )
on conflict (source_document_id, content_hash) do update
set page_start = excluded.page_start,
    page_end = excluded.page_end,
    section_title = excluded.section_title,
    content_sw = excluded.content_sw,
    extraction_method = excluded.extraction_method,
    review_status = excluded.review_status,
    risk_level = excluded.risk_level,
    reviewed_at = excluded.reviewed_at,
    updated_at = excluded.updated_at;

update public.course_modules
set title_sw = 'Usalama wa Banda na Ufuatiliaji wa Kila Siku',
    summary_sw =
      'Zuia magonjwa kuingia bandani, dumisha usafi, na tambua mabadiliko ya afya mapema.',
    status = 'published',
    risk_level = 'medium',
    source_link_status = 'linked',
    published_at = now(),
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-KUK-02')
  and code = 'MOD-KUK-03';

update public.course_modules
set status = 'archived',
    published_at = null,
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-KUK-02')
  and code <> 'MOD-KUK-03';

update public.lessons
set module_id = (
      select id
      from public.course_modules
      where course_id = (select id from public.courses where code = 'CRS-KUK-02')
        and code = 'MOD-KUK-03'
    ),
    title_sw = 'Tenga Kuku Wapya na Dhibiti Viatu',
    body_sw =
      'Kuku wapya wanaweza kuingiza maambukizi kwenye kundi. Watenganishe na kuku waliopo kwa angalau wiki mbili huku ukiangalia hali yao. Tumia viatu au ndala maalum za banda na epuka kuingia na viatu vilivyotumika nje. Hatua hizi ni za kuzuia maambukizi; dalili za ugonjwa zinahitaji ushauri wa mtaalamu wa mifugo.',
    lesson_type = 'reading',
    duration_minutes = 5,
    status = 'published',
    risk_level = 'medium',
    source_link_status = 'linked',
    sort_order = 10,
    published_at = now(),
    updated_at = now()
where id in (
  select l.id
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    and l.code = 'LSN-KUK-001'
);

update public.lessons
set module_id = (
      select id
      from public.course_modules
      where course_id = (select id from public.courses where code = 'CRS-KUK-02')
        and code = 'MOD-KUK-03'
    ),
    title_sw = 'Ratiba ya Usafi wa Banda na Vifaa',
    body_sw =
      'Panga kazi za kila siku na kila juma. Ondoa kinyesi na takataka, hakikisha hewa inazunguka, na kagua maji, malisho na vifaa. Badilisha matandazo machafu na safisha vifaa kabla ya kutumia kitakasa kilichoidhinishwa kwa kufuata maelekezo ya bidhaa au mtaalamu. Tumia mavazi ya kazi, glavu na barakoa pale penye vumbi, na weka sehemu ya kusafisha viatu karibu na mlango wa banda.',
    lesson_type = 'reading',
    duration_minutes = 6,
    status = 'published',
    risk_level = 'medium',
    source_link_status = 'linked',
    sort_order = 20,
    published_at = now(),
    updated_at = now()
where id in (
  select l.id
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    and l.code = 'LSN-KUK-002'
);

update public.lessons
set title_sw = 'Fuatilia Afya na Weka Kumbukumbu',
    body_sw =
      'Pitia kundi kila siku na uangalie tabia, manyoya, uzito, ngozi, ulaji, unywaji na namna kuku wanavyotembea. Weka kumbukumbu za chanjo, matibabu na matokeo ya uchunguzi ili mtaalamu aweze kuona historia ya kundi. Ukiona dalili zisizo za kawaida, ongezeko la vifo au matatizo ya kupumua, watenge kuku walioathirika na wasiliana na mtaalamu wa mifugo. Somo hili halitoi utambuzi wa ugonjwa, dawa au ratiba binafsi ya chanjo.',
    lesson_type = 'reading',
    duration_minutes = 5,
    status = 'published',
    risk_level = 'medium',
    source_link_status = 'linked',
    sort_order = 30,
    published_at = now(),
    updated_at = now()
where id in (
  select l.id
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    and l.code = 'MOD-KUK-03-READING-01'
);

update public.lessons
set status = 'archived',
    published_at = null,
    updated_at = now()
where id in (
  select l.id
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
)
and code not in (
  'LSN-KUK-001',
  'LSN-KUK-002',
  'MOD-KUK-03-READING-01'
);

delete from public.content_source_links
where (
    content_type = 'course'
    and content_id = (select id from public.courses where code = 'CRS-KUK-02')
  )
  or (
    content_type = 'module'
    and content_id in (
      select id
      from public.course_modules
      where course_id = (select id from public.courses where code = 'CRS-KUK-02')
    )
  )
  or (
    content_type = 'lesson'
    and content_id in (
      select l.id
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    )
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
  ss.id,
  ss.source_document_id,
  'linked',
  mapping.evidence_note,
  now()
from (
  values
    (
      'LSN-KUK-001',
      '96f8967dd041a7ab4268420923cfa8097b183d7eb54a5a826beb2b64bbe2e146',
      'PDF page 12 (printed page 7): quarantine for new birds and dedicated footwear.'
    ),
    (
      'LSN-KUK-002',
      '8d9f114e92e3844511b2b419f348873a6acf742335baf39e9f372127ff6add7a',
      'PDF pages 23-24 (printed pages 18-19): cleaning routines, equipment, protective clothing, and footbath.'
    ),
    (
      'MOD-KUK-03-READING-01',
      '0afa8cd7e26b77a3981b19c4e2a325407da273bf3ca3782986dd284baaa4ff5a',
      'PDF page 27 (printed page 22): daily monitoring, records, and veterinary consultation.'
    )
) as mapping(lesson_code, content_hash, evidence_note)
join public.lessons l on l.code = mapping.lesson_code
join public.course_modules m on m.id = l.module_id
join public.source_segments ss
  on ss.source_document_id = '0df42d11-2747-4b7f-a4c9-f045f577ead4'
  and ss.content_hash = mapping.content_hash
where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
on conflict (content_type, content_id, source_segment_id) do update
set link_status = excluded.link_status,
    evidence_note = excluded.evidence_note,
    updated_at = now();

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
  'Reviewed prevention and monitoring evidence from the poultry source book.',
  now()
from (
  select 'course'::text as content_type, c.id as content_id
  from public.courses c
  where c.code = 'CRS-KUK-02'
  union all
  select 'module'::text, m.id
  from public.course_modules m
  where m.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    and m.code = 'MOD-KUK-03'
) target
cross join public.source_segments ss
where ss.source_document_id = '0df42d11-2747-4b7f-a4c9-f045f577ead4'
  and ss.content_hash in (
    '96f8967dd041a7ab4268420923cfa8097b183d7eb54a5a826beb2b64bbe2e146',
    '8d9f114e92e3844511b2b419f348873a6acf742335baf39e9f372127ff6add7a',
    '0afa8cd7e26b77a3981b19c4e2a325407da273bf3ca3782986dd284baaa4ff5a'
  )
on conflict (content_type, content_id, source_segment_id) do update
set link_status = excluded.link_status,
    evidence_note = excluded.evidence_note,
    updated_at = now();

insert into public.grounding_facts (
  course_id,
  module_id,
  lesson_id,
  source_segment_id,
  code,
  fact_sw,
  question_sw,
  status,
  risk_level,
  import_source,
  external_id,
  reviewed_at,
  updated_at
)
select
  c.id,
  m.id,
  l.id,
  ss.id,
  mapping.code,
  mapping.fact_sw,
  mapping.question_sw,
  'published',
  'medium',
  'manual_pdf_review',
  mapping.external_id,
  now(),
  now()
from (
  values
    (
      'LSN-KUK-001',
      '96f8967dd041a7ab4268420923cfa8097b183d7eb54a5a826beb2b64bbe2e146',
      'kuku-quarantine-footwear',
      'Kuku wapya watengwe na kundi kwa angalau wiki mbili huku wakifuatiliwa, na viatu maalum vitumike kuingia bandani.',
      'Nizuieje magonjwa kuingia bandani ninapoleta kuku wapya?',
      'SAFE-KUK-001'
    ),
    (
      'LSN-KUK-002',
      '8d9f114e92e3844511b2b419f348873a6acf742335baf39e9f372127ff6add7a',
      'kuku-cleaning-routine',
      'Ratiba ya usafi ihusishe kuondoa kinyesi na takataka, kukagua maji na malisho, kubadilisha matandazo machafu, na kusafisha vifaa na viatu vya banda.',
      'Ratiba ya usafi wa banda la kuku iwe na mambo gani?',
      'SAFE-KUK-002'
    ),
    (
      'MOD-KUK-03-READING-01',
      '0afa8cd7e26b77a3981b19c4e2a325407da273bf3ca3782986dd284baaa4ff5a',
      'kuku-monitoring-records',
      'Uangalizi wa kila siku na kumbukumbu za afya, chanjo na matibabu husaidia kutambua mabadiliko mapema na kumpa mtaalamu wa mifugo historia ya kundi.',
      'Kwa nini nifuatilie kuku kila siku na kuweka kumbukumbu za afya na chanjo?',
      'SAFE-KUK-003'
    )
) as mapping(
  lesson_code,
  content_hash,
  code,
  fact_sw,
  question_sw,
  external_id
)
join public.courses c on c.code = 'CRS-KUK-02'
join public.course_modules m
  on m.course_id = c.id
  and m.code = 'MOD-KUK-03'
join public.lessons l
  on l.module_id = m.id
  and l.code = mapping.lesson_code
join public.source_segments ss
  on ss.source_document_id = '0df42d11-2747-4b7f-a4c9-f045f577ead4'
  and ss.content_hash = mapping.content_hash
on conflict (import_source, external_id) where external_id is not null do update
set course_id = excluded.course_id,
    module_id = excluded.module_id,
    lesson_id = excluded.lesson_id,
    source_segment_id = excluded.source_segment_id,
    code = excluded.code,
    fact_sw = excluded.fact_sw,
    question_sw = excluded.question_sw,
    status = excluded.status,
    risk_level = excluded.risk_level,
    reviewed_at = excluded.reviewed_at,
    updated_at = now();

update public.grounding_facts
set status = 'archived',
    reviewed_at = null,
    updated_at = now()
where course_id = (select id from public.courses where code = 'CRS-KUK-02')
  and (
    external_id is null
    or external_id not in ('SAFE-KUK-001', 'SAFE-KUK-002', 'SAFE-KUK-003')
  );

update public.courses
set title_sw = 'Usalama wa Banda na Ufuatiliaji wa Afya ya Kuku',
    summary_sw =
      'Mafunzo ya kuzuia maambukizi kwa kutenga kuku wapya, kusafisha banda na kufuatilia afya kila siku.',
    description_sw =
      'Kozi hii inalenga kinga na ufuatiliaji wa afya. Haitoi utambuzi wa ugonjwa, tiba za asili, dawa, vipimo au ratiba binafsi ya chanjo. Dalili za ugonjwa zinahitaji mtaalamu wa mifugo.',
    delivery_type = 'text',
    status = 'published',
    risk_level = 'medium',
    source_link_status = 'linked',
    published_at = now(),
    updated_at = now()
where code = 'CRS-KUK-02';

update public.learning_paths
set status = 'archived',
    published_at = null,
    updated_at = now()
where id in (
  select lpc.learning_path_id
  from public.learning_path_courses lpc
  where lpc.course_id = (select id from public.courses where code = 'CRS-KUK-02')
    and not exists (
      select 1
      from public.learning_path_courses other_course
      where other_course.learning_path_id = lpc.learning_path_id
        and other_course.course_id <> lpc.course_id
    )
);

update public.content_courses
set status = 'archived',
    updated_at = now()
where id = 'magonjwa-ya-kuku-tiba-asili'
   or payload ->> 'sourceCourseCode' = 'CRS-KUK-02';

commit;

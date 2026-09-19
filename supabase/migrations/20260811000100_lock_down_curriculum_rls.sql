-- The mobile app reads curriculum through the authenticated Node API. Direct
-- Supabase table access would bypass subscription checks, so remove every
-- client-facing grant and permissive policy left by earlier ingestion work.
-- The backend postgres/service roles bypass RLS and remain unaffected.

DO $$
DECLARE
  target_table TEXT;
  policy_record RECORD;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'source_documents',
    'source_segments',
    'ingestion_jobs',
    'categories',
    'courses',
    'course_modules',
    'lessons',
    'checklists',
    'quiz_questions',
    'faq_entries',
    'content_gaps',
    'learning_paths',
    'learning_path_courses',
    'content_source_links',
    'content_reviews',
    'content_change_log',
    'curriculum_import_batches',
    'curriculum_import_errors',
    'curriculum_staging_rows',
    'content_source_assets',
    'lesson_resources',
    'grounding_facts',
    'content_course_revisions'
  ]
  LOOP
    IF to_regclass(format('public.%I', target_table)) IS NULL THEN
      CONTINUE;
    END IF;

    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON TABLE public.%I FROM anon, authenticated',
      target_table
    );
    EXECUTE format(
      'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',
      target_table
    );

    FOR policy_record IN
      SELECT policyname
      FROM pg_policies
      WHERE schemaname = 'public' AND tablename = target_table
    LOOP
      EXECUTE format(
        'DROP POLICY %I ON public.%I',
        policy_record.policyname,
        target_table
      );
    END LOOP;

    EXECUTE format(
      'CREATE POLICY deny_direct_client_access ON public.%I
       FOR ALL TO public USING (false) WITH CHECK (false)',
      target_table
    );
  END LOOP;
END $$;

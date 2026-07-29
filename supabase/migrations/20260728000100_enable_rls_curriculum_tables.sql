-- Close direct anon/authenticated access to the curriculum tables.
--
-- These 11 tables shipped with RLS disabled, which left every row readable
-- AND writable by anyone holding the anon key that is embedded in the Android
-- APK. That is the entire paid curriculum, plus the ingestion staging tables.
--
-- The deny-all policy matches the pattern already used by the 13 tables in
-- server/store/schema.sql. It is safe for every legitimate caller because
-- none of them are subject to RLS:
--   * the Node API connects directly as `postgres` over SUPABASE_DATABASE_URL
--   * edge functions that touch these tables use serviceClient() (service role)
--   * validate-course-sources goes through validate_course_sources(), which is
--     SECURITY DEFINER owned by postgres
--   * the Flutter client never talks to Supabase directly; it calls the Node API
--
-- A policy is required rather than a bare ENABLE: enabling RLS with no policy
-- would deny the service role nothing but would leave no documented intent,
-- and the explicit policy keeps this consistent with the rest of the schema.

DO $$
DECLARE
  target_table TEXT;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'source_documents',
    'courses',
    'course_modules',
    'lessons',
    'learning_paths',
    'learning_path_courses',
    'curriculum_import_batches',
    'curriculum_import_errors',
    'curriculum_staging_rows',
    'content_source_assets',
    'lesson_resources'
  ]
  LOOP
    EXECUTE format(
      'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', target_table);
    EXECUTE format(
      'DROP POLICY IF EXISTS deny_direct_client_access ON public.%I',
      target_table);
    EXECUTE format(
      'CREATE POLICY deny_direct_client_access ON public.%I
         FOR ALL TO public USING (false) WITH CHECK (false)', target_table);
  END LOOP;
END $$;

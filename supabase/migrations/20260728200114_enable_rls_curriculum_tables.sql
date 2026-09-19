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
END $$;;

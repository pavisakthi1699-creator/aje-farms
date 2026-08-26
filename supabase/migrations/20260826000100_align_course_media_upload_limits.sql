-- Keep Storage enforcement aligned with the admin application's advertised
-- lesson-video formats and 200 MB limit.
update storage.buckets
set file_size_limit = 209715200,
    allowed_mime_types = array[
      'application/pdf',
      'video/mp4',
      'video/quicktime',
      'video/webm',
      'text/plain',
      'text/markdown',
      'application/json',
      'text/csv'
    ]
where id = 'source-documents';

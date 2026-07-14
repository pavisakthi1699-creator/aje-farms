import type { ContentRiskLevel, ContentStatus, ImportSource, LessonType, SourceLinkStatus } from "./content";

export interface SourceDocumentRow {
  id: string;
  title: string;
  language_code: string;
  source_type: string;
  storage_bucket: string;
  storage_path: string;
  file_name: string;
  checksum: string;
  page_count: number | null;
  version_number: number;
  processing_status: ContentStatus;
  uploaded_by: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SourceSegmentRow {
  id: string;
  source_document_id: string;
  page_start: number;
  page_end: number;
  section_title: string | null;
  segment_order: number;
  content_sw: string;
  content_hash: string;
  extraction_method: string;
  review_status: ContentStatus;
  risk_level: ContentRiskLevel;
  reviewed_by: string | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CourseRow {
  id: string;
  category_id: string | null;
  code: string;
  title_sw: string;
  summary_sw: string | null;
  description_sw: string | null;
  language_code: string;
  status: ContentStatus;
  risk_level: ContentRiskLevel;
  import_source: ImportSource;
  external_id: string | null;
  source_reference: string | null;
  source_link_status: SourceLinkStatus;
  prerequisite_course_id: string | null;
  sort_order: number;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ModuleRow {
  id: string;
  course_id: string;
  code: string;
  title_sw: string;
  summary_sw: string | null;
  status: ContentStatus;
  risk_level: ContentRiskLevel;
  import_source: ImportSource;
  external_id: string | null;
  source_reference: string | null;
  source_link_status: SourceLinkStatus;
  sort_order: number;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface LessonRow {
  id: string;
  module_id: string;
  code: string;
  title_sw: string;
  body_sw: string | null;
  lesson_type: LessonType;
  duration_minutes: number | null;
  status: ContentStatus;
  risk_level: ContentRiskLevel;
  import_source: ImportSource;
  external_id: string | null;
  source_reference: string | null;
  source_link_status: SourceLinkStatus;
  sort_order: number;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface ContentSourceLinkRow {
  id: string;
  content_type: "course" | "module" | "lesson" | "checklist" | "quiz_question" | "faq_entry";
  content_id: string;
  source_segment_id: string;
  source_document_id: string;
  link_status: SourceLinkStatus;
  evidence_note: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

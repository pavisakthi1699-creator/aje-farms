export type ContentStatus = "draft" | "needs_review" | "approved" | "published" | "archived" | "failed";
export type ContentRiskLevel = "normal" | "medium" | "high";
export type LessonType = "reading" | "video" | "pdf" | "checklist" | "quiz" | "practical_task" | "audio";
export type ImportSource = "manual" | "notebooklm" | "gemini_api" | "csv_import";
export type SourceLinkStatus = "linked" | "source_missing" | "pending_review";

export type ContentSourceType = "course" | "module" | "lesson" | "checklist" | "quiz_question" | "faq_entry";

export interface CurriculumImportRow {
  external_id?: string;
  item_type: "course" | "module" | "lesson" | "checklist" | "quiz" | "faq" | "content_gap" | "learning_path" | "learning_path_course";
  course_code?: string;
  module_code?: string;
  lesson_code?: string;
  learning_path_code?: string;
  code?: string;
  title_sw?: string;
  summary_sw?: string;
  body_sw?: string;
  question_sw?: string;
  answer_sw?: string;
  options_sw?: string[] | string;
  correct_answer?: string;
  explanation_sw?: string;
  items_sw?: string[] | string;
  source_reference?: string;
  source_segment_id?: string;
  sort_order?: number | string;
}

export interface CourseSourceValidationReport {
  course_id: string;
  valid: boolean;
  missing_source_links: Array<{
    content_type: ContentSourceType;
    content_id: string;
    title: string;
    source_link_status: SourceLinkStatus;
  }>;
  high_risk_needs_review: Array<{
    content_type: ContentSourceType;
    content_id: string;
    title: string;
    status: ContentStatus;
  }>;
}

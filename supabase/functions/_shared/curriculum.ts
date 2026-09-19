export type CurriculumItemType =
  | "course"
  | "module"
  | "lesson"
  | "fact"
  | "checklist"
  | "quiz"
  | "faq"
  | "content_gap"
  | "learning_path"
  | "learning_path_course";

export type CurriculumRow = {
  external_id?: string;
  record_type?: CurriculumItemType;
  item_type: CurriculumItemType;
  category_code?: string;
  category_name_sw?: string;
  category_description_sw?: string;
  course_code?: string;
  module_code?: string;
  lesson_code?: string;
  learning_path_code?: string;
  code?: string;
  title_sw?: string;
  summary_sw?: string;
  body_sw?: string;
  fact_sw?: string;
  question_sw?: string;
  answer_sw?: string;
  options_sw?: string[] | string;
  correct_answer?: string;
  explanation_sw?: string;
  items_sw?: string[] | string;
  source_reference?: string;
  source_reference_text?: string;
  source_segment_id?: string;
  status?: "draft" | "needs_review" | "approved" | "published" | "archived" | "failed";
  risk_level?: "normal" | "medium" | "high";
  delivery_type?: "video" | "text";
  lesson_type?: "reading" | "video" | "pdf" | "checklist" | "quiz" | "practical_task" | "audio";
  source_document_ids?: string[] | string;
  video_source_document_id?: string;
  transcript_source_document_id?: string;
  sort_order?: number | string;
};

export function parseCsv(text: string): CurriculumRow[] {
  const rows: string[][] = [];
  let field = "";
  let row: string[] = [];
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];
    if (char === '"' && inQuotes && next === '"') {
      field += '"';
      i += 1;
    } else if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === "," && !inQuotes) {
      row.push(field);
      field = "";
    } else if ((char === "\n" || char === "\r") && !inQuotes) {
      if (char === "\r" && next === "\n") i += 1;
      row.push(field);
      if (row.some((value) => value.trim() !== "")) rows.push(row);
      row = [];
      field = "";
    } else {
      field += char;
    }
  }

  row.push(field);
  if (row.some((value) => value.trim() !== "")) rows.push(row);

  const [headers = [], ...body] = rows;
  const normalizedHeaders = headers.map((header) => header.trim());
  return body.map((values) => {
    const record: Record<string, string> = {};
    normalizedHeaders.forEach((header, index) => {
      record[header] = values[index]?.trim() ?? "";
    });
    return record as CurriculumRow;
  });
}

export async function parseCurriculumRequest(req: Request): Promise<{ rows: CurriculumRow[]; raw: string; fileName?: string }> {
  const contentType = req.headers.get("content-type") ?? "";
  if (contentType.includes("multipart/form-data")) {
    const form = await req.formData();
    const file = form.get("file");
    if (!(file instanceof File)) {
      throw Object.assign(new Error("multipart/form-data requires a file field"), { status: 400 });
    }
    const raw = await file.text();
    return { rows: file.name.endsWith(".csv") ? parseCsv(raw) : rowsFromJson(raw), raw, fileName: file.name };
  }

  const raw = await req.text();
  if (contentType.includes("text/csv")) {
    return { rows: parseCsv(raw), raw };
  }
  return { rows: rowsFromJson(raw), raw };
}

function rowsFromJson(raw: string): CurriculumRow[] {
  const parsed = JSON.parse(raw);
  if (Array.isArray(parsed)) return parsed as CurriculumRow[];
  if (Array.isArray(parsed.rows)) return parsed.rows as CurriculumRow[];
  throw Object.assign(new Error("JSON body must be an array or contain a rows array"), { status: 400 });
}

export function parseJsonArray(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (typeof value !== "string" || value.trim() === "") return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [parsed];
  } catch {
    return value.split("|").map((item) => item.trim()).filter(Boolean);
  }
}

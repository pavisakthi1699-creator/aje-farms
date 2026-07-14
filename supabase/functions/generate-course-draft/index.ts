import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { codeFromText, requireEditor, serviceClient } from "../_shared/supabase.ts";

const RISK_TERMS = [
  "pesticide",
  "herbicide",
  "fertilizer dosage",
  "disease treatment",
  "livestock medicine",
  "prices",
  "costs",
  "profit",
  "financial advice",
  "kiuatilifu",
  "dawa ya kuua magugu",
  "mbolea",
  "dozi",
  "matibabu",
  "bei",
  "gharama",
  "faida",
];

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    await requireEditor(req);
    const { source_document_id } = await req.json();
    if (!source_document_id) return jsonResponse({ error: "source_document_id is required" }, 400);

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return jsonResponse({ error: "GEMINI_API_KEY secret is not configured" }, 500);

    const admin = serviceClient();
    const { data: document, error: documentError } = await admin
      .from("source_documents")
      .select("id, title")
      .eq("id", source_document_id)
      .single();
    if (documentError) throw documentError;

    const { data: segments, error: segmentsError } = await admin
      .from("source_segments")
      .select("id, page_start, page_end, section_title, segment_order, content_sw, risk_level")
      .eq("source_document_id", source_document_id)
      .order("segment_order", { ascending: true });
    if (segmentsError) throw segmentsError;
    if (!segments?.length) return jsonResponse({ error: "No source segments found for document" }, 422);

    const generated = await callGemini(apiKey, document.title, segments);
    const result = await saveGeneratedDraft(admin, document.title, generated);
    return jsonResponse(result);
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    return jsonResponse({ error: error instanceof Error ? error.message : "Draft generation failed" }, status);
  }
});

async function callGemini(apiKey: string, documentTitle: string, segments: Array<Record<string, unknown>>) {
  const prompt = [
    "You are building a Swahili-first agricultural curriculum from verified PDF source segments.",
    "Return strict JSON only. Do not use markdown.",
    "Schema: {\"categories\":[{\"name_sw\":\"\",\"code\":\"\",\"courses\":[{\"title_sw\":\"\",\"code\":\"\",\"summary_sw\":\"\",\"source_segment_ids\":[\"\"],\"modules\":[{\"title_sw\":\"\",\"code\":\"\",\"summary_sw\":\"\",\"source_segment_ids\":[\"\"],\"lessons\":[{\"title_sw\":\"\",\"code\":\"\",\"body_sw\":\"\",\"lesson_type\":\"reading\",\"source_segment_ids\":[\"\"]}],\"checklists\":[{\"title_sw\":\"\",\"code\":\"\",\"items_sw\":[\"\"],\"source_segment_ids\":[\"\"]}],\"quizzes\":[{\"question_sw\":\"\",\"code\":\"\",\"options_sw\":[\"\"],\"correct_answer\":\"\",\"explanation_sw\":\"\",\"source_segment_ids\":[\"\"]}],\"faq\":[{\"question_sw\":\"\",\"code\":\"\",\"answer_sw\":\"\",\"source_segment_ids\":[\"\"]}],\"content_gaps\":[{\"title_sw\":\"\",\"code\":\"\",\"description_sw\":\"\",\"source_reference\":\"\"}]}]}]}]}",
    "Every course, module, lesson, checklist, quiz, and FAQ object must include one or more source_segment_ids from the supplied segments.",
    "If evidence is insufficient, create a content_gaps item instead of inventing facts.",
    `Document title: ${documentTitle}`,
    `Source segments: ${JSON.stringify(segments)}`,
  ].join("\n\n");

  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.2,
      },
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gemini request failed: ${response.status} ${text.slice(0, 500)}`);
  }

  const payload = await response.json();
  const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error("Gemini returned no JSON text");
  return JSON.parse(text);
}

async function saveGeneratedDraft(admin: ReturnType<typeof serviceClient>, documentTitle: string, generated: any) {
  const created = { courses: 0, modules: 0, lessons: 0, checklists: 0, quizzes: 0, faq: 0, content_gaps: 0 };

  for (const category of generated.categories ?? []) {
    const categoryCode = category.code || codeFromText(category.name_sw ?? documentTitle, "generated-category");
    const { data: categoryRow, error: categoryError } = await admin
      .from("categories")
      .upsert({
        code: categoryCode,
        name_sw: category.name_sw ?? documentTitle,
        status: "draft",
      }, { onConflict: "code" })
      .select("id, code")
      .single();
    if (categoryError) throw categoryError;

    for (const course of category.courses ?? []) {
      const risk = riskFor(course);
      const courseCode = course.code || codeFromText(course.title_sw, "generated-course");
      const { data: courseRow, error: courseError } = await admin
        .from("courses")
        .upsert({
          category_id: categoryRow.id,
          code: courseCode,
          title_sw: course.title_sw,
          summary_sw: course.summary_sw ?? null,
          status: risk.status,
          risk_level: risk.risk_level,
          import_source: "gemini_api",
          external_id: `gemini:${courseCode}`,
          source_link_status: "pending_review",
        }, { onConflict: "import_source,external_id" })
        .select("id, code")
        .single();
      if (courseError) throw courseError;
      created.courses += 1;
      await linkMany(admin, "course", courseRow.id, course.source_segment_ids);

      for (const module of course.modules ?? []) {
        const moduleRisk = riskFor(module);
        const moduleCode = module.code || codeFromText(module.title_sw, "generated-module");
        const { data: moduleRow, error: moduleError } = await admin
          .from("course_modules")
          .upsert({
            course_id: courseRow.id,
            code: moduleCode,
            title_sw: module.title_sw,
            summary_sw: module.summary_sw ?? null,
            status: moduleRisk.status,
            risk_level: moduleRisk.risk_level,
            import_source: "gemini_api",
            external_id: `gemini:${courseRow.code}:${moduleCode}`,
            source_link_status: "pending_review",
          }, { onConflict: "import_source,external_id" })
          .select("id, code")
          .single();
        if (moduleError) throw moduleError;
        created.modules += 1;
        await linkMany(admin, "module", moduleRow.id, module.source_segment_ids);

        for (const lesson of module.lessons ?? []) {
          const lessonRisk = riskFor(lesson);
          const lessonCode = lesson.code || codeFromText(lesson.title_sw, "generated-lesson");
          const { data: lessonRow, error: lessonError } = await admin
            .from("lessons")
            .upsert({
              module_id: moduleRow.id,
              code: lessonCode,
              title_sw: lesson.title_sw,
              body_sw: lesson.body_sw ?? null,
              lesson_type: lesson.lesson_type ?? "reading",
              status: lessonRisk.status,
              risk_level: lessonRisk.risk_level,
              import_source: "gemini_api",
              external_id: `gemini:${moduleRow.code}:${lessonCode}`,
              source_link_status: "pending_review",
            }, { onConflict: "import_source,external_id" })
            .select("id, code")
            .single();
          if (lessonError) throw lessonError;
          created.lessons += 1;
          await linkMany(admin, "lesson", lessonRow.id, lesson.source_segment_ids);
        }

        for (const checklist of module.checklists ?? []) {
          const checklistRisk = riskFor(checklist);
          const checklistCode = checklist.code || codeFromText(checklist.title_sw, "generated-checklist");
          const { data: checklistRow, error: checklistError } = await admin
            .from("checklists")
            .upsert({
              course_id: courseRow.id,
              code: checklistCode,
              title_sw: checklist.title_sw,
              items_sw: checklist.items_sw ?? [],
              status: checklistRisk.status,
              risk_level: checklistRisk.risk_level,
              import_source: "gemini_api",
              external_id: `gemini:${moduleRow.code}:${checklistCode}`,
              source_link_status: "pending_review",
            }, { onConflict: "import_source,external_id" })
            .select("id, code")
            .single();
          if (checklistError) throw checklistError;
          created.checklists += 1;
          await linkMany(admin, "checklist", checklistRow.id, checklist.source_segment_ids);
        }

        for (const quiz of module.quizzes ?? []) {
          const quizRisk = riskFor(quiz);
          const quizCode = quiz.code || codeFromText(quiz.question_sw, "generated-quiz");
          const { data: quizRow, error: quizError } = await admin
            .from("quiz_questions")
            .upsert({
              course_id: courseRow.id,
              code: quizCode,
              question_sw: quiz.question_sw,
              options_sw: quiz.options_sw ?? [],
              correct_answer: quiz.correct_answer ?? null,
              explanation_sw: quiz.explanation_sw ?? null,
              status: quizRisk.status,
              risk_level: quizRisk.risk_level,
              import_source: "gemini_api",
              external_id: `gemini:${moduleRow.code}:${quizCode}`,
              source_link_status: "pending_review",
            }, { onConflict: "import_source,external_id" })
            .select("id, code")
            .single();
          if (quizError) throw quizError;
          created.quizzes += 1;
          await linkMany(admin, "quiz_question", quizRow.id, quiz.source_segment_ids);
        }

        for (const faq of module.faq ?? []) {
          const faqRisk = riskFor(faq);
          const faqCode = faq.code || codeFromText(faq.question_sw, "generated-faq");
          const { data: faqRow, error: faqError } = await admin
            .from("faq_entries")
            .upsert({
              course_id: courseRow.id,
              code: faqCode,
              question_sw: faq.question_sw,
              answer_sw: faq.answer_sw,
              status: faqRisk.status,
              risk_level: faqRisk.risk_level,
              import_source: "gemini_api",
              external_id: `gemini:${moduleRow.code}:${faqCode}`,
              source_link_status: "pending_review",
            }, { onConflict: "import_source,external_id" })
            .select("id, code")
            .single();
          if (faqError) throw faqError;
          created.faq += 1;
          await linkMany(admin, "faq_entry", faqRow.id, faq.source_segment_ids);
        }

        for (const gap of module.content_gaps ?? []) {
          const gapCode = gap.code || codeFromText(gap.title_sw, "generated-gap");
          const { error: gapError } = await admin.from("content_gaps").upsert({
            course_id: courseRow.id,
            module_id: moduleRow.id,
            code: gapCode,
            title_sw: gap.title_sw,
            description_sw: gap.description_sw ?? null,
            status: "draft",
            import_source: "gemini_api",
            external_id: `gemini:${moduleRow.code}:${gapCode}`,
            source_reference: gap.source_reference ?? null,
            source_link_status: "source_missing",
          }, { onConflict: "import_source,external_id" });
          if (gapError) throw gapError;
          created.content_gaps += 1;
        }
      }
    }
  }

  return { imported: created, status: "draft" };
}

async function linkMany(admin: ReturnType<typeof serviceClient>, contentType: string, contentId: string, sourceSegmentIds: string[] = []) {
  for (const sourceSegmentId of sourceSegmentIds) {
    const { data: segment, error } = await admin
      .from("source_segments")
      .select("id, source_document_id")
      .eq("id", sourceSegmentId)
      .maybeSingle();
    if (error) throw error;
    if (!segment) continue;
    await admin.from("content_source_links").upsert({
      content_type: contentType,
      content_id: contentId,
      source_segment_id: segment.id,
      source_document_id: segment.source_document_id,
      link_status: "pending_review",
    }, { onConflict: "content_type,content_id,source_segment_id" });
  }
}

function riskFor(value: unknown): { status: "draft" | "needs_review"; risk_level: "normal" | "high" } {
  const haystack = JSON.stringify(value ?? {}).toLowerCase();
  const high = RISK_TERMS.some((term) => haystack.includes(term.toLowerCase()));
  return high ? { status: "needs_review", risk_level: "high" } : { status: "draft", risk_level: "normal" };
}

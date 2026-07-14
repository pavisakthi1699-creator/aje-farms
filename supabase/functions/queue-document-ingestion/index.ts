import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { requireEditor, serviceClient, sha256Hex } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    const { user } = await requireEditor(req);
    const body = await req.json();
    const sourceDocumentId = body.source_document_id;
    const jobType = body.job_type ?? "extract_source_segments";
    if (!sourceDocumentId) return jsonResponse({ error: "source_document_id is required" }, 400);

    const admin = serviceClient();
    const { data: document, error: documentError } = await admin
      .from("source_documents")
      .select("id")
      .eq("id", sourceDocumentId)
      .maybeSingle();
    if (documentError) throw documentError;
    if (!document) return jsonResponse({ error: "source_document_id not found" }, 404);

    const { data: active, error: activeError } = await admin
      .from("ingestion_jobs")
      .select("*")
      .eq("source_document_id", sourceDocumentId)
      .eq("job_type", jobType)
      .in("status", ["queued", "running"])
      .maybeSingle();
    if (activeError) throw activeError;
    if (active) return jsonResponse({ job: active, deduped: true });

    const idempotencyKey = body.idempotency_key ?? await sha256Hex(`${sourceDocumentId}:${jobType}`);
    const { data: job, error: jobError } = await admin
      .from("ingestion_jobs")
      .upsert({
        source_document_id: sourceDocumentId,
        job_type: jobType,
        status: "queued",
        idempotency_key: idempotencyKey,
        requested_by: user.id,
        metadata: body.metadata ?? {},
      }, { onConflict: "idempotency_key" })
      .select()
      .single();
    if (jobError) throw jobError;

    return jsonResponse({ job, deduped: false });
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    return jsonResponse({ error: error instanceof Error ? error.message : "Unexpected queue failure" }, status);
  }
});

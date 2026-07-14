import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { requireEditor, serviceClient, sha256Hex } from "../_shared/supabase.ts";
import { parseCurriculumRequest } from "../_shared/curriculum.ts";
import { validateCurriculumRow } from "../_shared/curriculum_promotion.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    const { user } = await requireEditor(req);
    const { rows, raw, fileName } = await parseCurriculumRequest(req);
    const admin = serviceClient();
    const batchHash = await sha256Hex(raw);

    const { data: batch, error: batchError } = await admin
      .from("curriculum_import_batches")
      .upsert({
        import_source: "notebooklm",
        batch_hash: batchHash,
        file_name: fileName,
        row_count: rows.length,
        status: "draft",
        imported_by: user.id,
      }, { onConflict: "batch_hash" })
      .select()
      .single();

    if (batchError) throw batchError;

    // Keep imports idempotent by replacing previously staged rows for this batch hash.
    await admin.from("curriculum_staging_rows").delete().eq("batch_id", batch.id);
    await admin.from("curriculum_import_errors").delete().eq("batch_id", batch.id);

    let validCount = 0;
    let errorCount = 0;
    const staged: Array<{ row_number: number; item_type: string; validation_status: string }> = [];

    for (const [index, rawRow] of rows.entries()) {
      const rowNumber = index + 1;
      const itemType = rawRow.item_type ?? rawRow.record_type ?? "module";
      rawRow.item_type = itemType;
      const validation = validateCurriculumRow(rawRow);
      const validationStatus = validation.valid ? "valid" : "invalid";
      let validationMessage: string | null = null;
      if (!validation.valid) {
        validationMessage = validation.message;
      }

      await admin.from("curriculum_staging_rows").upsert({
        batch_id: batch.id,
        row_number: rowNumber,
        external_row_id: rawRow.external_id ?? null,
        item_type: itemType,
        row_data: rawRow,
        validation_status: validationStatus,
        error_code: validation.valid ? null : "invalid_row",
        error_message: validationMessage,
      }, { onConflict: "batch_id,row_number" });

      staged.push({
        row_number: rowNumber,
        item_type: itemType,
        validation_status: validationStatus,
      });

      if (validation.valid) {
        validCount += 1;
      } else {
        errorCount += 1;
        await admin.from("curriculum_import_errors").insert({
          batch_id: batch.id,
          row_number: rowNumber,
          external_row_id: rawRow.external_id ?? null,
          item_type: itemType,
          error_code: "invalid_row",
          error_message: validationMessage,
          raw_row: rawRow,
        });
      }
    }

    await admin
      .from("curriculum_import_batches")
      .update({
        valid_count: validCount,
        error_count: errorCount,
        status: errorCount > 0 ? "needs_review" : "approved",
        completed_at: new Date().toISOString(),
        metadata: {
          mode: "staged_only",
          promotion_required: true,
          staged_row_count: rows.length,
        },
      })
      .eq("id", batch.id);

    return jsonResponse({
      batch_id: batch.id,
      batch_hash: batchHash,
      valid_count: validCount,
      error_count: errorCount,
      staged_count: rows.length,
      staged,
      next_step: "POST /functions/v1/promote-staged-curriculum with { batch_id }",
    });
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    return jsonResponse({ error: error instanceof Error ? error.message : "Unexpected import failure" }, status);
  }
});

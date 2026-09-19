import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { requireEditor, serviceClient } from "../_shared/supabase.ts";
import { importRow, type PromotionResult } from "../_shared/curriculum_promotion.ts";
import type { CurriculumRow } from "../_shared/curriculum.ts";

type StagingRow = {
  id: string;
  row_number: number;
  item_type: string;
  external_row_id: string | null;
  row_data: CurriculumRow;
};

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    await requireEditor(req);
    const body = await req.json();
    const batchId = body.batch_id as string | undefined;
    const limit = Number(body.limit ?? 500);

    if (!batchId) return jsonResponse({ error: "batch_id is required" }, 400);

    const admin = serviceClient();
    const { data: batch, error: batchError } = await admin
      .from("curriculum_import_batches")
      .select("id, row_count, valid_count, error_count")
      .eq("id", batchId)
      .maybeSingle();
    if (batchError) throw batchError;
    if (!batch) return jsonResponse({ error: "batch_id not found" }, 404);

    const { data: rows, error: rowsError } = await admin
      .from("curriculum_staging_rows")
      .select("id, row_number, item_type, external_row_id, row_data")
      .eq("batch_id", batchId)
      .eq("validation_status", "valid")
      .order("row_number", { ascending: true })
      .limit(limit);
    if (rowsError) throw rowsError;

    const stagedRows = (rows ?? []) as StagingRow[];
    if (!stagedRows.length) {
      return jsonResponse({
        batch_id: batchId,
        promoted_count: 0,
        promotion_error_count: 0,
        promoted: [],
        message: "No valid staged rows found to promote",
      });
    }

    let promotedCount = 0;
    let promotionErrorCount = 0;
    const promoted: PromotionResult[] = [];

    for (const row of stagedRows) {
      try {
        const result = await importRow(admin, row.row_data, row.row_number);
        promoted.push(result);
        promotedCount += 1;

        await admin
          .from("curriculum_staging_rows")
          .update({
            validation_status: "promoted",
            promoted_content_type: result.item_type,
            promoted_content_id: result.id ?? null,
            promotion_result: result,
            promoted_at: new Date().toISOString(),
            error_code: null,
            error_message: null,
          })
          .eq("id", row.id);
      } catch (error) {
        promotionErrorCount += 1;
        const message = error instanceof Error ? error.message : String(error);

        await admin
          .from("curriculum_staging_rows")
          .update({
            validation_status: "invalid",
            error_code: "promotion_failed",
            error_message: message,
          })
          .eq("id", row.id);

        await admin.from("curriculum_import_errors").insert({
          batch_id: batchId,
          row_number: row.row_number,
          external_row_id: row.external_row_id,
          item_type: row.item_type,
          error_code: "promotion_failed",
          error_message: message,
          raw_row: row.row_data,
        });
      }
    }

    await admin
      .from("curriculum_import_batches")
      .update({
        status: promotionErrorCount > 0 ? "needs_review" : "published",
        completed_at: new Date().toISOString(),
        metadata: {
          mode: "staged_then_promoted",
          promoted_count: promotedCount,
          promotion_error_count: promotionErrorCount,
        },
      })
      .eq("id", batchId);

    return jsonResponse({
      batch_id: batchId,
      staged_count: stagedRows.length,
      promoted_count: promotedCount,
      promotion_error_count: promotionErrorCount,
      promoted,
    }, promotionErrorCount > 0 ? 207 : 200);
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    return jsonResponse({ error: error instanceof Error ? error.message : "Promotion failed" }, status);
  }
});

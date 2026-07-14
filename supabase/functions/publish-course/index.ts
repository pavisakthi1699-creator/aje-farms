import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { requireEditor, userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405);

  try {
    await requireEditor(req);
    const { course_id } = await req.json();
    if (!course_id) return jsonResponse({ error: "course_id is required" }, 400);

    const supabase = userClient(req);
    const { data, error } = await supabase.rpc("publish_course", { course_id_input: course_id });
    if (error) throw error;
    return jsonResponse(data, data?.published ? 200 : 422);
  } catch (error) {
    const status = (error as { status?: number }).status ?? 500;
    return jsonResponse({ error: error instanceof Error ? error.message : "Publish failed" }, status);
  }
});

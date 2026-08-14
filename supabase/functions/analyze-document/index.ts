import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  CLASSIFY_TOOL,
  DocumentClassification,
  MAX_IMAGE_BYTES,
  parseDocumentClassification,
  SYSTEM_PROMPT,
  validateStoragePath,
} from "./document_classifier.ts";

// AI document analysis for a Senior-captured photo (technical-decisions.md
// §1-7/§1-8: server-side AI, original deleted right after analysis). Mirrors
// analyze-message's structure: forced tool-call structured output, provider:
// Anthropic Messages API (ANTHROPIC_API_KEY secret) with vision input. The
// client uploads the photo to the `document-photos` Storage bucket first and
// only sends the storage path here — the API key and the download both stay
// server-side.

const AI_TIMEOUT_MS = 20000;
const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";
const BUCKET = "document-photos";

async function classifyWithAnthropic(
  apiKey: string,
  base64Image: string,
  mediaType: string,
): Promise<
  { ok: true; value: DocumentClassification } | { ok: false; reason: string }
> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), AI_TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      signal: controller.signal,
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 768,
        system: SYSTEM_PROMPT,
        tools: [CLASSIFY_TOOL],
        tool_choice: { type: "tool", name: "report_document_analysis" },
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: mediaType,
                  data: base64Image,
                },
              },
              {
                type: "text",
                text: "위 사진 속 문서를 분석해줘.",
              },
            ],
          },
        ],
      }),
    });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return { ok: false, reason: "ai_provider_timeout" };
    }
    console.error("analyze-document: fetch to Anthropic threw", e);
    return { ok: false, reason: "ai_provider_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `analyze-document: Anthropic responded ${response.status} ${response.statusText}`,
      errorBody.slice(0, 500),
    );
    return { ok: false, reason: "ai_provider_error" };
  }

  let body: unknown;
  try {
    body = await response.json();
  } catch {
    return { ok: false, reason: "ai_response_invalid" };
  }

  const content = (body as { content?: unknown })?.content;
  if (!Array.isArray(content)) {
    return { ok: false, reason: "ai_response_invalid" };
  }
  const toolUse = content.find(
    (block) =>
      block && typeof block === "object" &&
      (block as { type?: unknown }).type === "tool_use" &&
      (block as { name?: unknown }).name === "report_document_analysis",
  ) as { input?: unknown } | undefined;

  if (!toolUse) {
    return { ok: false, reason: "ai_response_invalid" };
  }

  return parseDocumentClassification(toolUse.input);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const caller = await verifyCaller(req);
  if ("error" in caller) {
    return json({ ok: false, reason: caller.error }, 401);
  }

  const body = await req.json().catch(() => null);
  const validatedPath = validateStoragePath(
    (body as { storagePath?: unknown })?.storagePath,
    caller.userId,
  );
  if (!validatedPath.ok) {
    return json({ ok: false, reason: validatedPath.reason }, 400);
  }
  const storagePath = validatedPath.value;

  try {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY")?.trim();
    if (!apiKey) {
      // No fabricated fallback — see technical-decisions.md §2 item 8. Still
      // inside the try so `finally` cleans up the already-uploaded photo
      // even though no AI call happens.
      return json({ ok: false, reason: "ai_provider_not_configured" }, 503);
    }

    const { data: file, error: downloadError } = await caller.serviceClient
      .storage
      .from(BUCKET)
      .download(storagePath);

    if (downloadError || !file) {
      return json({ ok: false, reason: "storage_download_failed" }, 502);
    }
    if (file.size > MAX_IMAGE_BYTES) {
      return json({ ok: false, reason: "image_too_large" }, 400);
    }

    const bytes = new Uint8Array(await file.arrayBuffer());
    const base64Image = encodeBase64(bytes);
    const mediaType = file.type && file.type.startsWith("image/")
      ? file.type
      : "image/jpeg";

    const classification = await classifyWithAnthropic(
      apiKey,
      base64Image,
      mediaType,
    );
    if (!classification.ok) {
      return json({ ok: false, reason: classification.reason }, 502);
    }
    const { summary, reliability, structuredFields } = classification.value;

    const { data: inserted, error: insertError } = await caller.serviceClient
      .from("analysis_results")
      .insert({
        elder_id: caller.userId,
        type: "document",
        risk_level: null,
        summary,
        source_excerpt: null,
        reliability,
        structured_fields: structuredFields,
      })
      .select(
        "id, elder_id, type, risk_level, summary, source_excerpt, reliability, structured_fields, created_at",
      )
      .single();

    if (insertError || !inserted) {
      return json({ ok: false, reason: "server_error" }, 500);
    }

    return json({
      ok: true,
      id: inserted.id,
      elderId: inserted.elder_id,
      type: inserted.type,
      riskLevel: inserted.risk_level,
      summary: inserted.summary,
      sourceExcerpt: inserted.source_excerpt,
      reliability: inserted.reliability,
      structuredFields: inserted.structured_fields,
      createdAt: inserted.created_at,
    });
  } finally {
    // Original photo must not outlive this request regardless of outcome
    // (§1-8 "원본 즉시 삭제", §2 item 9 — delete on failure too, not just
    // success, so a failed analysis never leaves an orphaned upload).
    await caller.serviceClient.storage.from(BUCKET).remove([storagePath]);
  }
});

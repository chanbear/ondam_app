import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  AiClassification,
  buildNotificationPayload,
  CLASSIFY_TOOL,
  parseAiClassification,
  RiskLevel,
  shouldNotifyGuardians,
  SYSTEM_PROMPT,
  validateMessageBody,
} from "./risk_classifier.ts";

// AI risk analysis for a Senior-received SMS/message (technical-decisions.md
// §1-7: "Android SMS → Backend → Risk Detection(AI 분석) → 위험도/주의사유/
// 요약 생성 → DB 저장 → 보호자 알림"). This is the first real AI-backed
// Edge Function in this project (document_scan's equivalent still returns
// UnavailableFailure — out of scope here). Provider: Anthropic Messages API
// (ANTHROPIC_API_KEY secret) using a forced tool call for structured output
// — see risk_classifier.ts's SYSTEM_PROMPT/CLASSIFY_TOOL comments for why
// this is also a meaningful prompt-injection mitigation, not just a
// convenience. The model's output is still independently allowlist-
// validated by `parseAiClassification` regardless of what it returns.

const AI_TIMEOUT_MS = 15000;
const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";

async function classifyWithAnthropic(
  apiKey: string,
  message: string,
): Promise<
  { ok: true; value: AiClassification } | { ok: false; reason: string }
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
        max_tokens: 512,
        system: SYSTEM_PROMPT,
        tools: [CLASSIFY_TOOL],
        tool_choice: { type: "tool", name: "classify_message_risk" },
        messages: [
          {
            role: "user",
            content: `<message>\n${message}\n</message>`,
          },
        ],
      }),
    });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return { ok: false, reason: "ai_provider_timeout" };
    }
    // Logged server-side only (Supabase Function Logs) for our own
    // debugging — never forwarded to the client. Safe to log: this is our
    // own fetch's exception, contains no secret material.
    console.error("analyze-message: fetch to Anthropic threw", e);
    return { ok: false, reason: "ai_provider_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    // Never forward the provider's raw error body to the CLIENT (may
    // contain request echoes/internal details) — only a generic reason
    // crosses that boundary. Logging it server-side (Function Logs) is
    // still safe and is the only way to diagnose a real failure, since the
    // API key itself never appears in Anthropic's own error response.
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `analyze-message: Anthropic responded ${response.status} ${response.statusText}`,
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
      (block as { name?: unknown }).name === "classify_message_risk",
  ) as { input?: unknown } | undefined;

  if (!toolUse) {
    return { ok: false, reason: "ai_response_invalid" };
  }

  return parseAiClassification(toolUse.input);
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
  const validated = validateMessageBody(body?.message);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }
  const message = validated.value;

  // .trim() defends against a stray leading/trailing newline or space in
  // the configured secret (a common copy-paste artifact — e.g. a trailing
  // "\n" from a terminal history or clipboard) making the raw value an
  // invalid HTTP header ByteString and failing `fetch()` before the
  // request ever reaches Anthropic. A real API key is always plain ASCII,
  // so trimming is safe and never changes a well-formed key.
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY")?.trim();
  if (!apiKey) {
    // No fabricated fallback classification — an unconfigured AI provider
    // is a real "cannot serve this request" state, not a green light to
    // guess. See technical-decisions.md §2 item 8.
    return json({ ok: false, reason: "ai_provider_not_configured" }, 503);
  }

  const classification = await classifyWithAnthropic(apiKey, message);
  if (!classification.ok) {
    return json({ ok: false, reason: classification.reason }, 502);
  }
  const { riskLevel, riskType, explanation, confidence } = classification.value;

  const { data: inserted, error: insertError } = await caller.serviceClient
    .from("analysis_results")
    .insert({
      elder_id: caller.userId,
      type: "message",
      risk_level: riskLevel,
      summary: explanation,
      source_excerpt: message,
      reliability: confidence,
      structured_fields: { riskType },
    })
    .select(
      "id, elder_id, type, risk_level, summary, source_excerpt, reliability, structured_fields, created_at",
    )
    .single();

  if (insertError || !inserted) {
    return json({ ok: false, reason: "server_error" }, 500);
  }

  let notifiedGuardianCount = 0;
  if (shouldNotifyGuardians(riskLevel as RiskLevel)) {
    const { data: links, error: linksError } = await caller.serviceClient
      .from("guardian_links")
      .select("guardian_id")
      .eq("elder_id", caller.userId)
      .eq("status", "accepted");

    if (!linksError && links) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const authorization = req.headers.get("Authorization")!;
      const payload = buildNotificationPayload({
        elderId: caller.userId,
        analysisResultId: inserted.id as string,
        riskLevel: riskLevel as RiskLevel,
        riskType,
        createdAt: inserted.created_at as string,
      });

      const results = await Promise.all(
        links.map(async (link) => {
          try {
            const res = await fetch(
              `${supabaseUrl}/functions/v1/send-notification`,
              {
                method: "POST",
                headers: {
                  "content-type": "application/json",
                  "Authorization": authorization,
                  "apikey": anonKey,
                },
                body: JSON.stringify({
                  targetUserId: link.guardian_id,
                  type: "risky_message",
                  payload,
                  sentVia: "push",
                }),
              },
            );
            return res.ok;
          } catch {
            return false;
          }
        }),
      );
      notifiedGuardianCount = results.filter(Boolean).length;
    }
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
    notifiedGuardianCount,
  });
});

import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import { notifyGuardians, shouldNotifyGuardians } from "../_shared/guardian_notify.ts";
import {
  AiClassification,
  applyRiskFloor,
  buildNotificationPayload,
  buildSystemPrompt,
  CLASSIFY_TOOL,
  parseAiClassification,
  RiskLevel,
  validateMessageBody,
} from "./risk_classifier.ts";
import { resolveLanguage, SupportedLanguage } from "../_shared/language.ts";

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
  lang: SupportedLanguage,
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
        system: buildSystemPrompt(lang),
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
  const lang = resolveLanguage(body?.language);

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

  const classification = await classifyWithAnthropic(apiKey, message, lang);
  if (!classification.ok) {
    return json({ ok: false, reason: classification.reason }, 502);
  }
  const {
    riskLevel,
    riskType,
    explanation,
    confidence,
    actionItems,
    importantDates,
    clarifyingQuestions,
  } = applyRiskFloor(message, classification.value, lang);

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

  // ONDAM 2.0 요구사항 27 — 위험도(caution/dangerous) 뿐 아니라 "정해진
  // 기한이 있는 내용"(importantDates 존재)도 독립적인 알림 조건이다. 기존
  // 위험도 기반 정책(caution/dangerous → 항상 알림)은 그대로 유지된다 —
  // shouldNotifyGuardians가 OR로만 조건을 넓힌다.
  let notifiedGuardianCount = 0;
  if (shouldNotifyGuardians(riskLevel as RiskLevel, importantDates.length > 0)) {
    const payload = buildNotificationPayload({
      elderId: caller.userId,
      analysisResultId: inserted.id as string,
      riskLevel: riskLevel as RiskLevel,
      riskType,
      createdAt: inserted.created_at as string,
    });
    notifiedGuardianCount = await notifyGuardians({
      serviceClient: caller.serviceClient,
      elderId: caller.userId,
      supabaseUrl: Deno.env.get("SUPABASE_URL")!,
      anonKey: Deno.env.get("SUPABASE_ANON_KEY")!,
      authorization: req.headers.get("Authorization")!,
      notificationType: "risky_message",
      payload,
    });
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
    // actionItems/importantDates/clarifyingQuestions are NOT persisted — no
    // `analysis_results` column exists for them (ONDAM 2.0 Phase 5: no
    // migration this phase), so they come straight from this request's
    // in-memory classification, not from `inserted`/a DB round-trip.
    actionItems,
    importantDates,
    clarifyingQuestions,
    createdAt: inserted.created_at,
    notifiedGuardianCount,
  });
});

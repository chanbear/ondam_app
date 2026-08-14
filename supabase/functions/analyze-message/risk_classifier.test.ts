// NOT AVAILABLE: this Deno test file has NOT been executed in this
// environment — the Deno CLI is not installed here (confirmed via
// `command -v deno`, and a prior attempt to install one via `npx deno-bin`
// hung/was unreliable — see Phase 8 Backend Agent's report). It is provided
// as a genuine, best-effort artifact for review and for execution once a
// Deno-capable environment (or `supabase functions serve`) is available —
// do NOT read its presence as "these behaviors were verified".
//
// Only imports from `risk_classifier.ts` (no Supabase/network/Deno.serve
// side effects) so it stays a pure unit test of the validation/allowlist
// logic — the actual Anthropic HTTP call in `index.ts` is deliberately not
// covered here since it cannot be exercised without a real API key either.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildNotificationPayload,
  MAX_MESSAGE_LENGTH,
  parseAiClassification,
  shouldNotifyGuardians,
  validateMessageBody,
} from "./risk_classifier.ts";

Deno.test("validateMessageBody rejects a non-string payload", () => {
  const result = validateMessageBody(12345);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_message");
});

Deno.test("validateMessageBody rejects an empty/whitespace-only message", () => {
  const result = validateMessageBody("   \n  ");
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_message");
});

Deno.test("validateMessageBody rejects an excessively long message", () => {
  const tooLong = "a".repeat(MAX_MESSAGE_LENGTH + 1);
  const result = validateMessageBody(tooLong);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "message_too_long");
});

Deno.test("validateMessageBody accepts and trims a normal message", () => {
  const result = validateMessageBody("  안녕하세요  ");
  assertEquals(result.ok, true);
  assertEquals((result as { value: string }).value, "안녕하세요");
});

Deno.test("parseAiClassification rejects a non-object tool input", () => {
  const result = parseAiClassification("not an object");
  assertEquals(result.ok, false);
});

Deno.test(
  "parseAiClassification rejects a riskLevel outside the allowlist — " +
    "the model returning an arbitrary string must never be trusted structurally",
  () => {
    const result = parseAiClassification({
      riskLevel: "extremely_dangerous", // not in RISK_LEVELS
      riskType: "smishing",
      explanation: "설명",
      confidence: "high",
    });
    assertEquals(result.ok, false);
    assertEquals((result as { reason: string }).reason, "ai_response_invalid");
  },
);

Deno.test(
  "parseAiClassification rejects a riskType outside the allowlist",
  () => {
    const result = parseAiClassification({
      riskLevel: "dangerous",
      riskType: "some_made_up_category",
      explanation: "설명",
      confidence: "high",
    });
    assertEquals(result.ok, false);
  },
);

Deno.test("parseAiClassification rejects a missing/empty explanation", () => {
  const result = parseAiClassification({
    riskLevel: "safe",
    riskType: "none",
    explanation: "   ",
    confidence: "low",
  });
  assertEquals(result.ok, false);
});

Deno.test("parseAiClassification accepts a well-formed classification", () => {
  const result = parseAiClassification({
    riskLevel: "dangerous",
    riskType: "smishing",
    explanation: "계좌 정지를 빙자한 전형적인 스미싱 문자예요.",
    confidence: "high",
  });
  assertEquals(result.ok, true);
  const value = (result as {
    value: { riskLevel: string; riskType: string; confidence: string };
  }).value;
  assertEquals(value.riskLevel, "dangerous");
  assertEquals(value.riskType, "smishing");
  assertEquals(value.confidence, "high");
});

Deno.test("shouldNotifyGuardians: safe never triggers a notification", () => {
  assertEquals(shouldNotifyGuardians("safe"), false);
});

Deno.test("shouldNotifyGuardians: caution and dangerous both trigger one", () => {
  assertEquals(shouldNotifyGuardians("caution"), true);
  assertEquals(shouldNotifyGuardians("dangerous"), true);
});

Deno.test(
  "buildNotificationPayload uses the elder_id/analysis_result_id snake_case " +
    "keys Guardian's NotificationItem.elderId/.analysisResultId read, and never " +
    "includes the raw SMS text",
  () => {
    const payload = buildNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "dangerous",
      riskType: "smishing",
      createdAt: "2026-01-01T00:00:00.000Z",
    });

    assertEquals(payload.elder_id, "elder-1");
    assertEquals(payload.analysis_result_id, "analysis-1");
    assertEquals(Object.prototype.hasOwnProperty.call(payload, "sourceExcerpt"), false);
    assertEquals(Object.prototype.hasOwnProperty.call(payload, "source_excerpt"), false);
  },
);

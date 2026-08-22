// NOT AVAILABLE: not executed in this environment (no Deno CLI — see the
// identical note in analyze-message/risk_classifier.test.ts). Provided as a
// best-effort artifact for review/future execution, not as verified
// behavior. Only imports from `document_classifier.ts` (no Deno.serve side
// effect), matching that file's rationale.

import { assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import {
  applyRiskFloor,
  buildDocumentNotificationPayload,
  DocumentClassification,
  MAX_FIELD_KEY_LENGTH,
  MAX_FIELD_VALUE_LENGTH,
  MAX_STRUCTURED_FIELDS,
  parseDocumentClassification,
  validateStoragePath,
} from "./document_classifier.ts";

Deno.test("validateStoragePath rejects a non-string/empty path", () => {
  const result = validateStoragePath(undefined, "user-1");
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_storage_path");
});

Deno.test(
  "validateStoragePath rejects a path outside the caller's own folder — " +
    "the Edge Function reads via service role, which bypasses bucket RLS, " +
    "so this check is the only thing stopping cross-user access here",
  () => {
    const result = validateStoragePath("someone-else/photo.jpg", "user-1");
    assertEquals(result.ok, false);
    assertEquals(
      (result as { reason: string }).reason,
      "invalid_storage_path",
    );
  },
);

Deno.test("validateStoragePath rejects path traversal", () => {
  const result = validateStoragePath("user-1/../user-2/photo.jpg", "user-1");
  assertEquals(result.ok, false);
});

Deno.test("validateStoragePath accepts the caller's own path", () => {
  const result = validateStoragePath("user-1/1700000000.jpg", "user-1");
  assertEquals(result.ok, true);
  assertEquals((result as { value: string }).value, "user-1/1700000000.jpg");
});

Deno.test("parseDocumentClassification rejects a non-object tool input", () => {
  const result = parseDocumentClassification("not an object");
  assertEquals(result.ok, false);
});

Deno.test("parseDocumentClassification rejects a missing/empty summary", () => {
  const result = parseDocumentClassification({
    summary: "   ",
    reliability: "high",
    structuredFields: {},
  });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "ai_response_invalid");
});

Deno.test(
  "parseDocumentClassification rejects a reliability outside the allowlist",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요.",
      reliability: "very_high",
      structuredFields: {},
      riskLevel: "safe",
    });
    assertEquals(result.ok, false);
  },
);

Deno.test(
  "parseDocumentClassification rejects a missing riskLevel — the model must always report one",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요.",
      reliability: "high",
      structuredFields: {},
    });
    assertEquals(result.ok, false);
    assertEquals((result as { reason: string }).reason, "ai_response_invalid");
  },
);

Deno.test(
  "parseDocumentClassification rejects a riskLevel outside the allowlist",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요.",
      reliability: "high",
      structuredFields: {},
      riskLevel: "extremely_dangerous",
    });
    assertEquals(result.ok, false);
  },
);

Deno.test(
  "parseDocumentClassification accepts a well-formed classification and preserves structured fields + riskLevel",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.",
      reliability: "high",
      structuredFields: { "금액": "32,000원", "납부기한": "2026-08-25" },
      riskLevel: "safe",
    });
    assertEquals(result.ok, true);
    const value = (result as {
      value: { structuredFields: Record<string, string>; riskLevel: string };
    }).value;
    assertEquals(value.structuredFields["금액"], "32,000원");
    assertEquals(value.structuredFields["납부기한"], "2026-08-25");
    assertEquals(value.riskLevel, "safe");
  },
);

Deno.test(
  "parseDocumentClassification drops non-string values and empty values instead of trusting the model's declared types",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: { "금액": 32000, "빈값": "" },
      riskLevel: "safe",
    });
    assertEquals(result.ok, true);
    const value = (result as {
      value: { structuredFields: Record<string, string> };
    }).value;
    // Coerced to string, not rejected outright — the model returning a
    // number for a schema-declared string field is a minor shape slip, not
    // an adversarial signal worth discarding the whole field over.
    assertEquals(value.structuredFields["금액"], "32000");
    assertEquals(Object.prototype.hasOwnProperty.call(value.structuredFields, "빈값"), false);
  },
);

Deno.test(
  "parseDocumentClassification caps the number of structured fields regardless of how many the model returns",
  () => {
    const many: Record<string, string> = {};
    for (let i = 0; i < MAX_STRUCTURED_FIELDS + 10; i++) {
      many[`필드${i}`] = `값${i}`;
    }
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "low",
      structuredFields: many,
      riskLevel: "safe",
    });
    assertEquals(result.ok, true);
    const value = (result as {
      value: { structuredFields: Record<string, string> };
    }).value;
    assertEquals(
      Object.keys(value.structuredFields).length,
      MAX_STRUCTURED_FIELDS,
    );
  },
);

Deno.test(
  "parseDocumentClassification truncates oversized keys/values instead of rejecting them",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "low",
      structuredFields: { ["키".repeat(100)]: "값".repeat(500) },
      riskLevel: "safe",
    });
    assertEquals(result.ok, true);
    const value = (result as {
      value: { structuredFields: Record<string, string> };
    }).value;
    const [key, val] = Object.entries(value.structuredFields)[0];
    assertEquals(key.length, MAX_FIELD_KEY_LENGTH);
    assertEquals(val.length, MAX_FIELD_VALUE_LENGTH);
  },
);

// --- applyRiskFloor (document) --------------------------------------------
// Mirrors analyze-message/risk_classifier.test.ts's applyRiskFloor cases —
// same shared signal detection (../_shared/risk_floor.ts), applied here to
// the AI's own summary + structuredFields text instead of a raw SMS body.

function safeClassification(
  overrides: Partial<DocumentClassification> = {},
): DocumentClassification {
  return {
    summary: "전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.",
    reliability: "medium",
    structuredFields: {},
    riskLevel: "safe",
    actionItems: [],
    importantDates: [],
    clarifyingQuestions: [],
    billingAmountKrw: null,
    billingDate: null,
    ...overrides,
  };
}

Deno.test(
  "Case 1: an ordinary document with no risk signals stays safe",
  () => {
    const ai = safeClassification({
      summary: "다음 달 정기 건강검진 안내문이에요.",
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "safe");
    assertEquals(result, ai);
  },
);

Deno.test(
  "Case 2: money request + personal-info request floors to at least caution",
  () => {
    const ai = safeClassification({
      summary: "요약",
      structuredFields: { "안내": "계좌번호를 알려주시면 입금해드립니다." },
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "caution");
  },
);

Deno.test(
  "Case 3: money request + external link floors to at least caution",
  () => {
    const ai = safeClassification({
      summary: "아래 링크에서 입금을 진행해 주세요. http://short.link/abc",
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "caution");
    assertNotEquals(result.riskLevel, "safe");
  },
);

Deno.test(
  "Case 4: money request + urgency floors to at least caution",
  () => {
    const ai = safeClassification({
      summary: "미납금을 오늘까지 납부하지 않으면 계정이 정지됩니다.",
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "caution");
  },
);

Deno.test(
  "Case 5: personal-info request + authentication-code request floors to at least caution",
  () => {
    const ai = safeClassification({
      summary: "본인 확인을 위해 주민등록번호와 인증번호를 입력해 주세요.",
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "caution");
  },
);

Deno.test(
  "Case 6: a single isolated signal word never forces caution by itself",
  () => {
    const ai = safeClassification({ summary: "이번 달 미납금 안내드립니다." });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "safe");
  },
);

Deno.test(
  "Case 7: riskLevel and reliability vary independently — floor never touches reliability",
  () => {
    const ai = safeClassification({
      summary: "미납금을 즉시 납부하지 않으면 법적 조치가 진행됩니다.",
      reliability: "low",
    });
    const result = applyRiskFloor(ai);
    assertEquals(result.riskLevel, "caution");
    assertEquals(result.reliability, "low");
  },
);

// --- ONDAM 2.0 Phase 5: actionItems/importantDates/clarifyingQuestions ----

Deno.test(
  "parseDocumentClassification parses actionItems/importantDates/clarifyingQuestions when present",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.",
      reliability: "high",
      structuredFields: {},
      riskLevel: "safe",
      actionItems: [{ title: "관리비 납부" }],
      importantDates: [
        { date: "2026-08-25", kind: "paymentDue", priority: "high" },
      ],
      clarifyingQuestions: ["이 고지서가 본인 명의가 맞나요?"],
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.actionItems, [
      { id: "action-0", title: "관리비 납부", completed: false },
    ]);
    assertEquals(value.importantDates, [
      { date: "2026-08-25", kind: "paymentDue", priority: "high" },
    ]);
    assertEquals(value.clarifyingQuestions, ["이 고지서가 본인 명의가 맞나요?"]);
  },
);

Deno.test(
  "parseDocumentClassification: 필드가 아예 없는 기존 응답도(구형 shape) 실패하지 않고 빈 배열로 채운다",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
      // actionItems/importantDates/clarifyingQuestions 키 자체가 없음
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.actionItems, []);
    assertEquals(value.importantDates, []);
    assertEquals(value.clarifyingQuestions, []);
  },
);

Deno.test(
  "parseDocumentClassification: 빈 배열은 있는 그대로 통과한다",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
      actionItems: [],
      importantDates: [],
      clarifyingQuestions: [],
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.actionItems, []);
    assertEquals(value.importantDates, []);
    assertEquals(value.clarifyingQuestions, []);
  },
);

Deno.test(
  "parseDocumentClassification: importantDates의 잘못된 kind/연도 없는 날짜는 이 항목만 버리고 나머지 응답은 그대로 성공한다",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
      actionItems: [],
      importantDates: [
        { date: "2026-08-25", kind: "not_a_real_kind", priority: "high" },
        { date: "08-25", kind: "paymentDue", priority: "high" }, // 연도 없음
        { date: "2026-08-25", kind: "paymentDue", priority: "high" }, // 정상
      ],
      clarifyingQuestions: [],
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.importantDates, [
      { date: "2026-08-25", kind: "paymentDue", priority: "high" },
    ]);
  },
);

Deno.test(
  "applyRiskFloor never downgrades or otherwise touches a non-safe riskLevel",
  () => {
    const ai: DocumentClassification = {
      summary: "특별한 신호가 없는 문서예요.",
      reliability: "low",
      structuredFields: {},
      riskLevel: "dangerous",
      actionItems: [],
      importantDates: [],
      clarifyingQuestions: [],
      billingAmountKrw: null,
      billingDate: null,
    };
    const result = applyRiskFloor(ai);
    assertEquals(result, ai);
  },
);

// --- PHASE 37: billingAmountKrw/billingDate --------------------------------

Deno.test(
  "parseDocumentClassification parses billingAmountKrw/billingDate when present",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.",
      reliability: "high",
      structuredFields: {},
      riskLevel: "safe",
      billingAmountKrw: 32000,
      billingDate: "2026-08-25",
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.billingAmountKrw, 32000);
    assertEquals(value.billingDate, "2026-08-25");
  },
);

Deno.test(
  "parseDocumentClassification defaults billingAmountKrw/billingDate to null when the model omits them",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.billingAmountKrw, null);
    assertEquals(value.billingDate, null);
  },
);

Deno.test(
  "parseDocumentClassification rejects a non-positive/non-finite billingAmountKrw instead of trusting it",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
      billingAmountKrw: -100,
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.billingAmountKrw, null);
  },
);

Deno.test(
  "parseDocumentClassification rejects a billingDate missing the year (never guesses one)",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: {},
      riskLevel: "safe",
      billingDate: "08-25",
    });
    assertEquals(result.ok, true);
    const value = (result as { value: DocumentClassification }).value;
    assertEquals(value.billingDate, null);
  },
);

// --- ONDAM 2.0 요구사항 18 — buildDocumentNotificationPayload -------------
// risk_classifier.test.ts의 buildNotificationPayload 테스트와 동일한 목적:
// Guardian 딥링크 계약(snake_case 키)을 지키는지, 그리고 위험도 기반 사유와
// 기한 기반 사유의 제목 문구가 요구사항대로 나뉘는지 확인한다.

Deno.test(
  "buildDocumentNotificationPayload uses the elder_id/analysis_result_id " +
    "snake_case keys Guardian's NotificationItem.elderId/.analysisResultId read",
  () => {
    const payload = buildDocumentNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "dangerous",
      hasImportantDates: false,
      createdAt: "2026-01-01T00:00:00.000Z",
    });

    assertEquals(payload.elder_id, "elder-1");
    assertEquals(payload.analysis_result_id, "analysis-1");
    assertEquals(payload.risk_level, "dangerous");
    assertEquals(payload.created_at, "2026-01-01T00:00:00.000Z");
  },
);

Deno.test(
  "buildDocumentNotificationPayload: 위험도(caution/dangerous)면 위험 문구를 쓴다",
  () => {
    const payload = buildDocumentNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "caution",
      hasImportantDates: false,
      createdAt: "2026-01-01T00:00:00.000Z",
    });
    assertEquals(payload.title, "위험한 문서가 감지되었어요");
  },
);

Deno.test(
  "buildDocumentNotificationPayload: safe인데 기한만 있는 경우엔 확인 문구를 쓴다",
  () => {
    const payload = buildDocumentNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "safe",
      hasImportantDates: true,
      createdAt: "2026-01-01T00:00:00.000Z",
    });
    assertEquals(payload.title, "확인이 필요한 문서가 있어요");
  },
);

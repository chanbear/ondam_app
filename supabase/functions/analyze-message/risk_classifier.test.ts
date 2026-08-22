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

import { assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import { shouldNotifyGuardians } from "../_shared/guardian_notify.ts";
import {
  AiClassification,
  applyRiskFloor,
  buildNotificationPayload,
  detectRuleSignals,
  MAX_MESSAGE_LENGTH,
  parseAiClassification,
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

// --- ONDAM 2.0 Phase 5: actionItems/importantDates/clarifyingQuestions ----

Deno.test(
  "parseAiClassification parses actionItems/importantDates/clarifyingQuestions when present",
  () => {
    const result = parseAiClassification({
      riskLevel: "caution",
      riskType: "other_scam",
      explanation: "설명",
      confidence: "medium",
      actionItems: [{ title: "발신 번호로 다시 연락하지 않기" }],
      importantDates: [
        { date: "2026-08-25", kind: "paymentDue", priority: "high" },
      ],
      clarifyingQuestions: ["이 번호로 실제 거래를 한 적이 있나요?"],
    });
    assertEquals(result.ok, true);
    const value = (result as { value: AiClassification }).value;
    assertEquals(value.actionItems, [
      { id: "action-0", title: "발신 번호로 다시 연락하지 않기", completed: false },
    ]);
    assertEquals(value.importantDates, [
      { date: "2026-08-25", kind: "paymentDue", priority: "high" },
    ]);
    assertEquals(value.clarifyingQuestions, ["이 번호로 실제 거래를 한 적이 있나요?"]);
  },
);

Deno.test(
  "parseAiClassification: 필드가 아예 없는 기존 응답도(구형 shape) 실패하지 않고 빈 배열로 채운다",
  () => {
    const result = parseAiClassification({
      riskLevel: "safe",
      riskType: "none",
      explanation: "설명",
      confidence: "medium",
      // actionItems/importantDates/clarifyingQuestions 키 자체가 없음
    });
    assertEquals(result.ok, true);
    const value = (result as { value: AiClassification }).value;
    assertEquals(value.actionItems, []);
    assertEquals(value.importantDates, []);
    assertEquals(value.clarifyingQuestions, []);
  },
);

Deno.test("parseAiClassification: 빈 배열은 있는 그대로 통과한다", () => {
  const result = parseAiClassification({
    riskLevel: "safe",
    riskType: "none",
    explanation: "설명",
    confidence: "medium",
    actionItems: [],
    importantDates: [],
    clarifyingQuestions: [],
  });
  assertEquals(result.ok, true);
  const value = (result as { value: AiClassification }).value;
  assertEquals(value.actionItems, []);
  assertEquals(value.importantDates, []);
  assertEquals(value.clarifyingQuestions, []);
});

Deno.test(
  "parseAiClassification: importantDates의 잘못된 kind/연도 없는 날짜는 이 항목만 버리고 나머지 응답은 그대로 성공한다",
  () => {
    const result = parseAiClassification({
      riskLevel: "safe",
      riskType: "none",
      explanation: "설명",
      confidence: "medium",
      actionItems: [],
      importantDates: [
        { date: "2026-08-25", kind: "not_a_real_kind", priority: "high" },
        { date: "08-25", kind: "paymentDue", priority: "high" }, // 연도 없음
        { date: "2026-08-25", kind: "paymentDue", priority: "high" }, // 정상
      ],
      clarifyingQuestions: [],
    });
    assertEquals(result.ok, true);
    const value = (result as { value: AiClassification }).value;
    assertEquals(value.importantDates, [
      { date: "2026-08-25", kind: "paymentDue", priority: "high" },
    ]);
  },
);

// ONDAM 2.0 요구사항 27 — 위험도 기반 정책(caution/dangerous → 항상 알림)은
// 그대로 유지하면서, "정해진 기한이 있는 내용"(importantDates 존재)을
// 독립적인 OR 조건으로 추가했는지 6가지 조합 전부를 확인한다.
Deno.test("shouldNotifyGuardians: safe + 기한 없음 → 기존 정책대로 알리지 않는다", () => {
  assertEquals(shouldNotifyGuardians("safe", false), false);
});

Deno.test("shouldNotifyGuardians: safe + 기한 있음 → 새 조건으로 알린다", () => {
  assertEquals(shouldNotifyGuardians("safe", true), true);
});

Deno.test("shouldNotifyGuardians: caution + 기한 없음 → 위험도만으로 알린다(기존 정책)", () => {
  assertEquals(shouldNotifyGuardians("caution", false), true);
});

Deno.test("shouldNotifyGuardians: dangerous + 기한 없음 → 위험도만으로 알린다(기존 정책)", () => {
  assertEquals(shouldNotifyGuardians("dangerous", false), true);
});

Deno.test("shouldNotifyGuardians: caution + 기한 있음 → 여전히 알린다(회귀 없음)", () => {
  assertEquals(shouldNotifyGuardians("caution", true), true);
});

Deno.test("shouldNotifyGuardians: dangerous + 기한 있음 → 여전히 알린다(회귀 없음)", () => {
  assertEquals(shouldNotifyGuardians("dangerous", true), true);
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

// ONDAM 2.0 PHASE 34 — 실서버 검증에서 발견한 버그: safe+기한 문자
// 알림에도 제목이 "위험 문자가 감지되었어요"로 고정돼 있던 것을 고쳤다.
// document_classifier.test.ts의 동일 테스트와 같은 목적.
Deno.test(
  "buildNotificationPayload: 위험도(caution/dangerous)면 위험 문구를 쓴다",
  () => {
    const payload = buildNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "caution",
      riskType: "other_scam",
      createdAt: "2026-01-01T00:00:00.000Z",
    });
    assertEquals(payload.title, "위험 문자가 감지되었어요");
  },
);

Deno.test(
  "buildNotificationPayload: safe인데 기한만 있어 알림이 가는 경우엔 위험 문구를 쓰지 않는다",
  () => {
    const payload = buildNotificationPayload({
      elderId: "elder-1",
      analysisResultId: "analysis-1",
      riskLevel: "safe",
      riskType: "none",
      createdAt: "2026-01-01T00:00:00.000Z",
    });
    assertEquals(payload.title, "확인이 필요한 문자가 있어요");
  },
);

// --- applyRiskFloor -------------------------------------------------------

function safeClassification(
  overrides: Partial<AiClassification> = {},
): AiClassification {
  return {
    riskLevel: "safe",
    riskType: "none",
    explanation: "일반적인 안내 문자로 보여요.",
    confidence: "medium",
    actionItems: [],
    importantDates: [],
    clarifyingQuestions: [],
    ...overrides,
  };
}

Deno.test(
  "Case 1: an ordinary informational message with no signals stays safe",
  () => {
    const ai = safeClassification();
    const result = applyRiskFloor(
      "안녕하세요, 다음 주 정기 검진 일정 안내드립니다.",
      ai,
    );
    assertEquals(result.riskLevel, "safe");
    assertEquals(result, ai);
  },
);

Deno.test(
  "Case 2: overdue-payment wording + urgency together floor to caution",
  () => {
    const ai = safeClassification();
    const result = applyRiskFloor(
      "미납금을 오늘까지 납부하지 않으면 계정이 정지됩니다.",
      ai,
    );
    assertEquals(result.riskLevel, "caution");
  },
);

Deno.test(
  "Case 3: money + personal info + external link floors to at least caution",
  () => {
    const ai = safeClassification();
    const result = applyRiskFloor(
      "아래 링크에서 본인 계좌번호를 입력하고 입금해 주세요. http://short.link/abc",
      ai,
    );
    assertEquals(result.riskLevel, "caution");
    assertNotEquals(result.riskLevel, "safe");
  },
);

Deno.test(
  "Case 4: the floor never downgrades an AI 'dangerous' classification",
  () => {
    const ai: AiClassification = {
      riskLevel: "dangerous",
      riskType: "smishing",
      explanation: "인증번호와 함께 송금을 요구하는 전형적인 스미싱이에요.",
      confidence: "high",
      actionItems: [],
      importantDates: [],
      clarifyingQuestions: [],
    };
    const result = applyRiskFloor(
      "인증번호를 알려주시면 바로 송금 처리해드릴게요.",
      ai,
    );
    assertEquals(result, ai);
  },
);

Deno.test(
  "a single isolated signal (only 'money', no second category) never triggers the floor",
  () => {
    const ai = safeClassification();
    const result = applyRiskFloor("이번 달 미납금 안내드립니다.", ai);
    assertEquals(
      [...detectRuleSignals("이번 달 미납금 안내드립니다.")],
      ["money"],
    );
    assertEquals(result.riskLevel, "safe");
  },
);

Deno.test(
  "Case 6: confidence is preserved as-is when the floor raises riskLevel — " +
    "riskLevel and confidence must vary independently",
  () => {
    const ai = safeClassification({ confidence: "low" });
    const result = applyRiskFloor(
      "미납금을 즉시 납부하지 않으면 법적 조치가 진행됩니다.",
      ai,
    );
    assertEquals(result.riskLevel, "caution");
    assertEquals(result.confidence, "low");
  },
);

Deno.test(
  "applyRiskFloor never touches a non-safe riskLevel, even without any rule signal",
  () => {
    const ai: AiClassification = {
      riskLevel: "caution",
      riskType: "other_scam",
      explanation: "모호하지만 의심스러운 문자예요.",
      confidence: "low",
      actionItems: [],
      importantDates: [],
      clarifyingQuestions: [],
    };
    const result = applyRiskFloor("특별한 신호가 없는 문자입니다.", ai);
    assertEquals(result, ai);
  },
);

Deno.test("detectRuleSignals finds each signal category independently", () => {
  assertEquals(detectRuleSignals("계좌로 입금해주세요.").has("money"), true);
  assertEquals(
    detectRuleSignals("주민등록번호를 알려주세요.").has("personalInfo"),
    true,
  );
  assertEquals(
    detectRuleSignals("인증번호를 입력해주세요.").has("authVerification"),
    true,
  );
  assertEquals(
    detectRuleSignals("아래 링크를 클릭하세요 http://a.b").has(
      "externalLink",
    ),
    true,
  );
  assertEquals(detectRuleSignals("오늘까지 처리해주세요.").has("urgency"), true);
  assertEquals(detectRuleSignals("평범한 문장입니다.").size, 0);
});

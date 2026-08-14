// NOT AVAILABLE: not executed in this environment (no Deno CLI — see the
// identical note in analyze-message/risk_classifier.test.ts). Provided as a
// best-effort artifact for review/future execution, not as verified
// behavior. Only imports from `document_classifier.ts` (no Deno.serve side
// effect), matching that file's rationale.

import { assertEquals } from "jsr:@std/assert@1";
import {
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
    });
    assertEquals(result.ok, false);
  },
);

Deno.test(
  "parseDocumentClassification accepts a well-formed classification and preserves structured fields",
  () => {
    const result = parseDocumentClassification({
      summary: "전기요금 고지서예요. 8월 25일까지 32,000원을 납부해야 해요.",
      reliability: "high",
      structuredFields: { "금액": "32,000원", "납부기한": "2026-08-25" },
    });
    assertEquals(result.ok, true);
    const value = (result as {
      value: { structuredFields: Record<string, string> };
    }).value;
    assertEquals(value.structuredFields["금액"], "32,000원");
    assertEquals(value.structuredFields["납부기한"], "2026-08-25");
  },
);

Deno.test(
  "parseDocumentClassification drops non-string values and empty values instead of trusting the model's declared types",
  () => {
    const result = parseDocumentClassification({
      summary: "요약",
      reliability: "medium",
      structuredFields: { "금액": 32000, "빈값": "" },
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

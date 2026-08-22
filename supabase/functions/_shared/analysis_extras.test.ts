// NOT AVAILABLE: not executed in this environment (no Deno CLI — see the
// identical note in analyze-message/risk_classifier.test.ts). Provided as a
// best-effort artifact for review/future execution, not as verified
// behavior. Only imports from `analysis_extras.ts` (no Deno.serve side
// effect).

import { assertEquals } from "jsr:@std/assert@1";
import {
  MAX_ACTION_ITEM_TITLE_LENGTH,
  MAX_ACTION_ITEMS,
  MAX_CLARIFYING_QUESTION_LENGTH,
  MAX_CLARIFYING_QUESTIONS,
  MAX_IMPORTANT_DATE_LABEL_LENGTH,
  MAX_IMPORTANT_DATES,
  parseActionItems,
  parseClarifyingQuestions,
  parseImportantDates,
} from "./analysis_extras.ts";

// --- parseActionItems ------------------------------------------------------

Deno.test("parseActionItems: not an array returns an empty array, not null/throw", () => {
  assertEquals(parseActionItems(undefined), []);
  assertEquals(parseActionItems(null), []);
  assertEquals(parseActionItems("not an array"), []);
});

Deno.test("parseActionItems: empty array in → empty array out", () => {
  assertEquals(parseActionItems([]), []);
});

Deno.test("parseActionItems: assigns a stable id and always forces completed=false regardless of model input", () => {
  const result = parseActionItems([
    { title: "관리비 납부", completed: true },
    { title: "주민센터 방문" },
  ]);
  assertEquals(result, [
    { id: "action-0", title: "관리비 납부", completed: false },
    { id: "action-1", title: "주민센터 방문", completed: false },
  ]);
});

Deno.test("parseActionItems: drops malformed entries instead of failing the whole array", () => {
  const result = parseActionItems([
    { title: "정상 항목" },
    { title: 123 }, // wrong type
    { notTitle: "x" }, // missing title
    "just a string",
    null,
    { title: "   " }, // blank after trim
  ]);
  assertEquals(result, [{ id: "action-0", title: "정상 항목", completed: false }]);
});

Deno.test(`parseActionItems: caps at ${MAX_ACTION_ITEMS} regardless of how many the model returns`, () => {
  const many = Array.from({ length: MAX_ACTION_ITEMS + 10 }, (_, i) => ({
    title: `항목 ${i}`,
  }));
  assertEquals(parseActionItems(many).length, MAX_ACTION_ITEMS);
});

Deno.test("parseActionItems: truncates an oversized title instead of rejecting it", () => {
  const result = parseActionItems([{ title: "가".repeat(500) }]);
  assertEquals(result[0].title.length, MAX_ACTION_ITEM_TITLE_LENGTH);
});

// --- parseImportantDates -----------------------------------------------

Deno.test("parseImportantDates: not an array returns an empty array", () => {
  assertEquals(parseImportantDates(undefined), []);
  assertEquals(parseImportantDates("nope"), []);
});

Deno.test("parseImportantDates: empty array in → empty array out", () => {
  assertEquals(parseImportantDates([]), []);
});

Deno.test("parseImportantDates: accepts a full YYYY-MM-DD date with a valid kind/priority", () => {
  const result = parseImportantDates([
    {
      date: "2026-08-25",
      kind: "paymentDue",
      label: "관리비 납부기한",
      priority: "high",
    },
  ]);
  assertEquals(result, [
    {
      date: "2026-08-25",
      kind: "paymentDue",
      priority: "high",
      label: "관리비 납부기한",
    },
  ]);
});

Deno.test("parseImportantDates: label is omitted (not null) when the model didn't provide one", () => {
  const result = parseImportantDates([
    { date: "2026-08-25", kind: "expiration", priority: "low" },
  ]);
  assertEquals(Object.prototype.hasOwnProperty.call(result[0], "label"), false);
});

Deno.test(
  "parseImportantDates: drops a bare month/day date with no year — never guesses one (§5 날짜 안전성)",
  () => {
    const result = parseImportantDates([
      { date: "08-25", kind: "paymentDue", priority: "high" },
      { date: "다음 주", kind: "visit", priority: "medium" },
    ]);
    assertEquals(result, []);
  },
);

Deno.test(
  "parseImportantDates: drops a date with an implausible/placeholder year instead of trusting it",
  () => {
    const result = parseImportantDates([
      { date: "0000-08-25", kind: "paymentDue", priority: "high" },
    ]);
    assertEquals(result, []);
  },
);

Deno.test(
  "parseImportantDates: drops a calendar-invalid date (e.g. Feb 30) instead of silently normalizing it",
  () => {
    const result = parseImportantDates([
      { date: "2026-02-30", kind: "visit", priority: "medium" },
    ]);
    assertEquals(result, []);
  },
);

Deno.test("parseImportantDates: drops an entry with an unknown kind/priority", () => {
  const result = parseImportantDates([
    { date: "2026-08-25", kind: "some_made_up_kind", priority: "high" },
    { date: "2026-08-25", kind: "paymentDue", priority: "extremely_urgent" },
  ]);
  assertEquals(result, []);
});

Deno.test(
  "parseImportantDates: a start/end period can be represented as two separate entries",
  () => {
    const result = parseImportantDates([
      {
        date: "2026-08-01",
        kind: "applicationPeriod",
        label: "신청 시작일",
        priority: "medium",
      },
      {
        date: "2026-08-15",
        kind: "applicationPeriod",
        label: "신청 마감일",
        priority: "high",
      },
    ]);
    assertEquals(result.length, 2);
    assertEquals(result[0].label, "신청 시작일");
    assertEquals(result[1].label, "신청 마감일");
  },
);

Deno.test(`parseImportantDates: caps at ${MAX_IMPORTANT_DATES}`, () => {
  const many = Array.from({ length: MAX_IMPORTANT_DATES + 10 }, (_, i) => ({
    date: "2026-08-25",
    kind: "other" as const,
    priority: "low" as const,
    label: `날짜 ${i}`,
  }));
  assertEquals(parseImportantDates(many).length, MAX_IMPORTANT_DATES);
});

Deno.test("parseImportantDates: truncates an oversized label", () => {
  const result = parseImportantDates([
    {
      date: "2026-08-25",
      kind: "other",
      priority: "low",
      label: "라".repeat(200),
    },
  ]);
  assertEquals(result[0].label?.length, MAX_IMPORTANT_DATE_LABEL_LENGTH);
});

// --- parseClarifyingQuestions --------------------------------------------

Deno.test("parseClarifyingQuestions: not an array returns an empty array", () => {
  assertEquals(parseClarifyingQuestions(undefined), []);
});

Deno.test("parseClarifyingQuestions: empty array in → empty array out", () => {
  assertEquals(parseClarifyingQuestions([]), []);
});

Deno.test("parseClarifyingQuestions: keeps well-formed strings, drops non-strings/blank", () => {
  const result = parseClarifyingQuestions([
    "이 문서가 본인 명의가 맞나요?",
    123,
    "   ",
    null,
  ]);
  assertEquals(result, ["이 문서가 본인 명의가 맞나요?"]);
});

Deno.test(`parseClarifyingQuestions: caps at ${MAX_CLARIFYING_QUESTIONS}`, () => {
  const many = Array.from(
    { length: MAX_CLARIFYING_QUESTIONS + 5 },
    (_, i) => `질문 ${i}`,
  );
  assertEquals(parseClarifyingQuestions(many).length, MAX_CLARIFYING_QUESTIONS);
});

Deno.test("parseClarifyingQuestions: truncates an oversized question", () => {
  const result = parseClarifyingQuestions(["질".repeat(500)]);
  assertEquals(result[0].length, MAX_CLARIFYING_QUESTION_LENGTH);
});

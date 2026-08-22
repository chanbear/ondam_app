// Shared "AI enrichment" shapes — actionItems/importantDates/
// clarifyingQuestions — reused by analyze-document/document_classifier.ts
// and analyze-message/risk_classifier.ts (ONDAM 2.0 Phase 5). Both functions
// return the exact same wire shape here because Flutter's
// AnalysisResultModel.fromJson (Phase 3, document_scan AND message_check)
// already parses one shared shape for both.
//
// Unlike riskLevel/summary/reliability/structuredFields (safety-critical —
// a malformed value there fails the whole classification, see
// parseDocumentClassification/parseAiClassification), these three are
// best-effort enrichment data: a missing field or one malformed array item
// never fails the overall AI response. We drop what we can't trust and keep
// the rest — same philosophy document_classifier.ts already applies to
// structuredFields entries.

export const IMPORTANT_DATE_KINDS = [
  "paymentDue",
  "visit",
  "applicationPeriod",
  "expiration",
  "reservation",
  "other",
] as const;
export type ImportantDateKind = (typeof IMPORTANT_DATE_KINDS)[number];

export const IMPORTANT_DATE_PRIORITIES = ["high", "medium", "low"] as const;
export type ImportantDatePriority = (typeof IMPORTANT_DATE_PRIORITIES)[number];

export type ActionItem = {
  id: string;
  title: string;
  completed: boolean;
};

export type ImportantDateEntry = {
  date: string; // YYYY-MM-DD — always a full, explicit calendar date.
  kind: ImportantDateKind;
  label?: string;
  priority: ImportantDatePriority;
};

export const MAX_ACTION_ITEMS = 5;
export const MAX_IMPORTANT_DATES = 5;
export const MAX_CLARIFYING_QUESTIONS = 3;
export const MAX_ACTION_ITEM_TITLE_LENGTH = 100;
export const MAX_IMPORTANT_DATE_LABEL_LENGTH = 60;
export const MAX_CLARIFYING_QUESTION_LENGTH = 200;

const FULL_DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function isOneOf<T extends string>(
  value: unknown,
  allowed: readonly T[],
): value is T {
  return typeof value === "string" &&
    (allowed as readonly string[]).includes(value);
}

// A full, explicit YYYY-MM-DD date — never accepts a bare month/day or a
// guessed year. Also rejects calendar-invalid dates (e.g. "2026-02-30")
// instead of trusting whatever the model wrote: `Date` silently normalizes
// day-of-month overflow, so we compare the round-trip instead of trusting
// the regex match alone.
function isValidFullDate(value: unknown): value is string {
  if (typeof value !== "string" || !FULL_DATE_PATTERN.test(value)) {
    return false;
  }
  const year = Number(value.slice(0, 4));
  // 이 앱은 한국에서 2020년대에 서비스되는 것을 전제한다 — 이 범위 밖의
  // 연도는 모델이 "연도 없음"을 표현하려고 placeholder를 넣은 것으로 보고
  // 거부한다(연도를 임의로 확정하지 않는다는 §5 규칙과 같은 정신).
  if (year < 2000 || year > 2100) return false;
  const parsed = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value;
}

export function parseActionItems(raw: unknown): ActionItem[] {
  if (!Array.isArray(raw)) return [];
  const items: ActionItem[] = [];
  for (const entry of raw) {
    if (items.length >= MAX_ACTION_ITEMS) break;
    if (entry === null || typeof entry !== "object") continue;
    const title = (entry as Record<string, unknown>).title;
    if (typeof title !== "string") continue;
    const trimmed = title.trim().slice(0, MAX_ACTION_ITEM_TITLE_LENGTH);
    if (trimmed.length === 0) continue;
    // id/completed are never taken from the model — assigned here so a
    // stable, always-false-on-creation value reaches the client regardless
    // of what (if anything) the model returned for them.
    items.push({ id: `action-${items.length}`, title: trimmed, completed: false });
  }
  return items;
}

export function parseImportantDates(raw: unknown): ImportantDateEntry[] {
  if (!Array.isArray(raw)) return [];
  const dates: ImportantDateEntry[] = [];
  for (const entry of raw) {
    if (dates.length >= MAX_IMPORTANT_DATES) break;
    if (entry === null || typeof entry !== "object") continue;
    const obj = entry as Record<string, unknown>;
    // 연도 없는/애매한 날짜는 여기서 조용히 버려진다 — 절대 임의로 채우지
    // 않는다(§5). 모델이 지시를 어기고 부분 날짜를 보내도 최종 응답에는
    // 나가지 않는다.
    if (!isValidFullDate(obj.date)) continue;
    if (!isOneOf(obj.kind, IMPORTANT_DATE_KINDS)) continue;
    if (!isOneOf(obj.priority, IMPORTANT_DATE_PRIORITIES)) continue;
    const label = typeof obj.label === "string" && obj.label.trim().length > 0
      ? obj.label.trim().slice(0, MAX_IMPORTANT_DATE_LABEL_LENGTH)
      : undefined;
    dates.push({
      date: obj.date as string,
      kind: obj.kind,
      priority: obj.priority,
      ...(label !== undefined ? { label } : {}),
    });
  }
  return dates;
}

export function parseClarifyingQuestions(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  const questions: string[] = [];
  for (const entry of raw) {
    if (questions.length >= MAX_CLARIFYING_QUESTIONS) break;
    if (typeof entry !== "string") continue;
    const trimmed = entry.trim().slice(0, MAX_CLARIFYING_QUESTION_LENGTH);
    if (trimmed.length === 0) continue;
    questions.push(trimmed);
  }
  return questions;
}

// Spliced into each classifier's own CLASSIFY_TOOL.input_schema.properties —
// same field names/shapes for both, since Flutter parses one shared wire
// shape either way. Deliberately does NOT ask the model for `id`/`completed`
// on actionItems (see parseActionItems) — fewer degrees of freedom for the
// model to get wrong, since we assign both ourselves regardless.
export const ANALYSIS_EXTRAS_SCHEMA_PROPERTIES = {
  actionItems: {
    type: "array",
    maxItems: MAX_ACTION_ITEMS,
    items: {
      type: "object",
      properties: {
        title: { type: "string", maxLength: MAX_ACTION_ITEM_TITLE_LENGTH },
      },
      required: ["title"],
    },
  },
  importantDates: {
    type: "array",
    maxItems: MAX_IMPORTANT_DATES,
    items: {
      type: "object",
      properties: {
        date: {
          type: "string",
          description:
            "YYYY-MM-DD — only when the FULL date including year is explicitly known or determinable from other text in the same document/message. Omit this item entirely otherwise.",
        },
        kind: { type: "string", enum: IMPORTANT_DATE_KINDS },
        label: { type: "string", maxLength: MAX_IMPORTANT_DATE_LABEL_LENGTH },
        priority: { type: "string", enum: IMPORTANT_DATE_PRIORITIES },
      },
      required: ["date", "kind", "priority"],
    },
  },
  clarifyingQuestions: {
    type: "array",
    maxItems: MAX_CLARIFYING_QUESTIONS,
    items: { type: "string", maxLength: MAX_CLARIFYING_QUESTION_LENGTH },
  },
} as const;

// Appended to each classifier's own SYSTEM_PROMPT — identical rules for
// both source types, kept in one place so the two prompts can't silently
// drift apart on caps/date-safety wording.
export const ANALYSIS_EXTRAS_PROMPT =
  `Additionally extract, as best-effort structured data — never fabricate; omit an item entirely rather than guessing:
- actionItems: concrete actions the reader needs to take, ONLY if directly supported by the text (e.g. "관리비 납부",
  "주민센터 방문"). Max 5. An ordinary informational document/message with nothing to act on gets an empty array.
- importantDates: a date ONLY when the FULL calendar date — day, month, AND year — is explicitly stated or
  unambiguously determinable from other text in the same document/message (e.g. a printed issue date elsewhere
  establishes the year). If only a month/day is given with no year anywhere, or the reference is vague ("다음 주",
  "이번 달 말", "빠른 시일 내", "며칠 이내"), do NOT invent a date — omit that item entirely (it may still appear in
  the summary text). Never default a missing year to the current year. For a date range (e.g. an application period
  with a start and end), emit up to two separate entries with the same kind and a distinct label (e.g. "신청
  시작일"/"신청 마감일") rather than one entry spanning both. kind must be exactly one of: paymentDue, visit,
  applicationPeriod, expiration, reservation, other. priority reflects actual urgency/importance. Max 5.
- clarifyingQuestions: questions the reader might reasonably want to ask about this specific document/message,
  grounded only in what it actually says — never introduce a new claimed fact inside a question. Max 3. Return an
  empty array if nothing meaningfully unclear remains.`;

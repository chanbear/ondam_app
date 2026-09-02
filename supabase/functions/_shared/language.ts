// Output-language support shared by analyze-document/analyze-message — the
// client sends the app's current UI language (core/locale/locale_provider.dart's
// 4-locale list: ko/en/ja/zh) so the AI writes its summary/explanation/labels
// in that language instead of always Korean (사용자 요청 — 언어를 바꾸면 분석
// 결과도 함께 바뀌어야 한다). Unknown/missing input falls back to "ko" — the
// app's original behavior before this existed, and every language the client
// can send is already in this list, so an unmatched value only ever means an
// older client build or a malformed request.

export const SUPPORTED_LANGUAGES = ["ko", "en", "ja", "zh"] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

const LANGUAGE_NAMES: Record<SupportedLanguage, string> = {
  ko: "Korean",
  en: "English",
  ja: "Japanese",
  zh: "Chinese",
};

export function resolveLanguage(raw: unknown): SupportedLanguage {
  return typeof raw === "string" &&
      (SUPPORTED_LANGUAGES as readonly string[]).includes(raw)
    ? (raw as SupportedLanguage)
    : "ko";
}

export function languageName(lang: SupportedLanguage): string {
  return LANGUAGE_NAMES[lang];
}

// Appended when the deterministic rule-floor (risk_floor.ts) raises a "safe"
// AI verdict to "caution" — same sentence in every classifier that uses this
// floor, translated per language rather than left hardcoded Korean regardless
// of the rest of the response's language.
const FLOOR_ADJUSTMENT_NOTE: Record<SupportedLanguage, (matched: string) => string> = {
  ko: (matched) => `(자동 점검: ${matched} 관련 표현이 함께 발견되어 주의로 조정했어요.)`,
  en: (matched) =>
    `(Automatic check: adjusted to caution because expressions related to ${matched} were both found.)`,
  ja: (matched) => `(自動チェック: ${matched} に関する表現が同時に見つかったため、注意に調整しました。)`,
  zh: (matched) => `（自动检查：同时发现与${matched}相关的表达，已调整为注意。）`,
};

export function floorAdjustmentNote(
  lang: SupportedLanguage,
  matched: string,
): string {
  return FLOOR_ADJUSTMENT_NOTE[lang](matched);
}

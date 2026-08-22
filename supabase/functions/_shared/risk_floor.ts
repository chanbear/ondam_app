// Deterministic risk-floor signal detection shared by both
// `analyze-message/risk_classifier.ts` and
// `analyze-document/document_classifier.ts`. Pure text-pattern matching — no
// Supabase/network/Deno.serve imports, unit-testable in isolation.
//
// The AI's own riskLevel judgment can flip between "safe" and "caution" on
// the same/near-identical borderline input across separate runs (no
// determinism guarantee from the provider). This floor stabilizes that: it
// never downgrades an AI "caution"/"dangerous" call, and never raises to
// "dangerous" by rule alone — it only raises a "safe" result to "caution",
// and only when at least two independent signal categories are both
// present. A single isolated keyword (e.g. just "납부기한") never triggers
// this, matching the "단순 키워드 하나로 과도하게 caution 되지 않는다" rule.

export const RISK_LEVELS = ["safe", "caution", "dangerous"] as const;
export type RiskLevel = (typeof RISK_LEVELS)[number];

export type RuleSignal =
  | "money"
  | "personalInfo"
  | "authVerification"
  | "externalLink"
  | "urgency";

const SIGNAL_PATTERNS: Record<RuleSignal, RegExp> = {
  money: /(송금|입금|계좌\s*이체|카드\s*정보|미납금|납부\s*요구|환급금)/,
  personalInfo: /(주민등록번호|주민번호|계좌번호|카드번호|비밀번호)/,
  authVerification: /(인증\s*번호|OTP|본인\s*인증)/i,
  externalLink: /(https?:\/\/|www\.|bit\.ly|QR\s*코드|앱\s*설치|원격\s*제어)/i,
  urgency: /(긴급|오늘까지|즉시|기한\s*내|미납\s*시|법적\s*조치|계정\s*정지|서비스\s*중단)/,
};

// Pairs called out explicitly by the risk-detection spec as "최소 caution".
export const CAUTION_FLOOR_COMBOS: readonly (readonly [RuleSignal, RuleSignal])[] = [
  ["money", "personalInfo"],
  ["money", "externalLink"],
  ["money", "urgency"],
  ["personalInfo", "authVerification"],
];

export function detectRuleSignals(text: string): Set<RuleSignal> {
  const found = new Set<RuleSignal>();
  for (
    const [signal, pattern] of Object.entries(SIGNAL_PATTERNS) as [
      RuleSignal,
      RegExp,
    ][]
  ) {
    if (pattern.test(text)) found.add(signal);
  }
  return found;
}

// Returns the first combo (in CAUTION_FLOOR_COMBOS order) that floors `text`
// from safe to caution, or null if none is present. Detection-only — the
// caller decides how to fold this into its own classification shape (message
// and document classifications differ), so this never mutates anything.
export function matchCautionFloor(
  text: string,
): readonly [RuleSignal, RuleSignal] | null {
  const signals = detectRuleSignals(text);
  return CAUTION_FLOOR_COMBOS.find(([a, b]) =>
    signals.has(a) && signals.has(b)
  ) ?? null;
}

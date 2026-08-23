// benefit_service_client.ts 상단 주석과 동일한 이유로, 상세조회 오퍼레이션
// 파라미터명도 미확인 초안이다. 목록 응답의 servId를 상세조회 키로 그대로
// 쓴다고 가정한다(이 API 계열의 일반적인 패턴).

export const LOCAL_GOV_DETAIL_ENDPOINT =
  "https://apis.data.go.kr/B554287/LocalGovernmentWelfareInformations/WlfareInfoOpenAPI";
export const CENTRAL_GOV_DETAIL_ENDPOINT =
  "https://apis.data.go.kr/B554287/NationalWelfareInformations/wlfareInfo";

export type Source = "local" | "central";

export type DetailRequest = { id: string; source: Source };

export type BenefitServiceDetailDto = {
  title: string;
  summary: string;
  supportTarget: string | null;
  applyMethod: string | null;
  contact: string | null;
  externalUrl: string | null;
};

export function validateDetailBody(
  raw: unknown,
): { ok: true; value: DetailRequest } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const obj = raw as Record<string, unknown>;
  const id = typeof obj.id === "string" ? obj.id.trim() : "";
  const source = obj.source;
  if (id.length === 0) return { ok: false, reason: "invalid_request" };
  if (source !== "local" && source !== "central") {
    return { ok: false, reason: "invalid_request" };
  }
  return { ok: true, value: { id, source } };
}

export function buildDetailRequestUrl(
  endpoint: string,
  serviceKey: string,
  id: string,
): string {
  const url = new URL(endpoint);
  url.searchParams.set("serviceKey", serviceKey);
  url.searchParams.set("callTp", "d");
  url.searchParams.set("servId", id);
  return url.toString();
}

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function mapDetailItem(
  raw: Record<string, unknown>,
): BenefitServiceDetailDto | null {
  const title = asTrimmedStringOrNull(raw.servNm);
  // 제목이 없으면 존재하지 않는 혜택을 지어내지 않고 null을 반환한다 —
  // index.ts가 이를 "not_found"로 취급한다.
  if (title === null) return null;
  return {
    title,
    summary: asTrimmedStringOrNull(raw.servDgst) ?? "",
    supportTarget: asTrimmedStringOrNull(raw.slctCritCn),
    applyMethod: asTrimmedStringOrNull(raw.aplyMtdCn) ??
      asTrimmedStringOrNull(raw.aplyMtdNm),
    contact: asTrimmedStringOrNull(raw.rprsCtadr),
    // 이 API에 외부 링크 필드가 있는지 확인되지 않아 항상 null — 지어내지
    // 않는다. 라이브 검증 후 실제 필드가 확인되면 연결한다.
    externalUrl: null,
  };
}

export function parseDetailResponse(
  raw: unknown,
): { ok: true; value: BenefitServiceDetailDto | null } | {
  ok: false;
  reason: string;
} {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const { header, body } = raw as Record<string, unknown>;
  const resultCode = header !== null && typeof header === "object"
    ? (header as Record<string, unknown>).resultCode
    : undefined;

  if (resultCode === "03") return { ok: true, value: null };
  if (resultCode !== "00" && resultCode !== "0") {
    return { ok: false, reason: "upstream_error" };
  }
  if (body === null || typeof body !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const items = (body as Record<string, unknown>).items;
  if (items === "" || items === null || items === undefined) {
    return { ok: true, value: null };
  }
  if (typeof items !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const rawItem = (items as Record<string, unknown>).item;
  if (rawItem === undefined || rawItem === "" || rawItem === null) {
    return { ok: true, value: null };
  }
  const first = Array.isArray(rawItem) ? rawItem[0] : rawItem;
  if (first === null || typeof first !== "object") {
    return { ok: true, value: null };
  }
  return { ok: true, value: mapDetailItem(first as Record<string, unknown>) };
}

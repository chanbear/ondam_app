// Pure validation/request-building/response-parsing logic for
// `search-benefit-services`, split out of `index.ts` for the same reason as
// `welfare_center_client.ts` — unit-testable without triggering
// `Deno.serve()`'s side effect.
//
// Data source: 공공데이터포털(data.go.kr) 한국사회보장정보원_지자체복지서비스
// (dataset 15108347) + 한국사회보장정보원_중앙부처복지서비스(dataset
// 15090532) Open API. 공식 페이지에서 "목록조회/상세조회 2개 오퍼레이션"
// 이라는 것만 확인했고, 로그인 없이는 SWAGGER 문서를 볼 수 없어 정확한
// 요청/응답 필드명은 확인하지 못했다 — 아래 필드명은 이 API 계열에 대한
// **최선 추정 초안**이다. welfare_center_client.ts의 PHASE 26→35와 동일하게,
// 실제 서비스키로 라이브 검증한 뒤 필드명을 교정해야 한다(ponytail: 검증
// 전까지는 최선 추정치 — 라이브 검증은 서비스키 발급 후 진행).
//
// 지역 필터: 지자체 API 항목에는 관할 시/도·시/군/구 필드(추정: ctpvNm/
// sggNm)가 있을 것으로 보고 시도하되, 없거나 매치 실패해도 항목 자체를
// 버리지 않는다(welfare_center의 "완전일치만 지원, 대체 파라미터 거부"
// 사례처럼 검증 전 지역 필터를 과신하지 않기 위함 — 결과가 조용히 0건이
// 되는 상황을 피한다). 중앙부처 API 항목은 전국 대상이라 지역 필드가 아예
// 없을 것으로 보고 필터하지 않는다.

export const LOCAL_GOV_ENDPOINT =
  "https://apis.data.go.kr/B554287/LocalGovernmentWelfareInformations/WlfareInfoOpenAPI";
export const CENTRAL_GOV_ENDPOINT =
  "https://apis.data.go.kr/B554287/NationalWelfareInformations/wlfareInfo";

export type RegionQuery = { sido: string; sigungu: string };

export type SearchRequest = {
  age: number;
  gender: "male" | "female";
  region: RegionQuery;
};

export type BenefitServiceDto = {
  id: string;
  title: string;
  summary: string;
};

export function validateSearchBody(
  raw: unknown,
): { ok: true; value: SearchRequest } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const obj = raw as Record<string, unknown>;
  const age = typeof obj.age === "number" ? obj.age : NaN;
  const gender = obj.gender;
  const region = obj.region;

  if (!Number.isFinite(age) || age <= 0 || age > 120) {
    return { ok: false, reason: "invalid_request" };
  }
  if (gender !== "male" && gender !== "female") {
    return { ok: false, reason: "invalid_request" };
  }
  if (region === null || typeof region !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const regionObj = region as Record<string, unknown>;
  const sido = typeof regionObj.sido === "string" ? regionObj.sido.trim() : "";
  const sigungu = typeof regionObj.sigungu === "string"
    ? regionObj.sigungu.trim()
    : "";
  if (sido.length === 0 || sigungu.length === 0) {
    return { ok: false, reason: "invalid_request" };
  }
  return { ok: true, value: { age, gender, region: { sido, sigungu } } };
}

// 65세를 경계로 "노년"/그 외 성인 생애주기로만 나눈다 — 이 앱의 사용자층
// (어르신)에서 의미 있는 경계는 사실상 이것뿐이라, 전체 생애주기 코드
// 표를 다 추정해서 틀리기보다 가장 확신 있는 경계 하나만 쓴다.
export function lifeStageCodeForAge(age: number): string {
  return age >= 65 ? "006" : "005";
}

export function buildRequestUrl(
  endpoint: string,
  serviceKey: string,
  pageNo: number,
  age: number,
): string {
  const url = new URL(endpoint);
  url.searchParams.set("serviceKey", serviceKey);
  url.searchParams.set("callTp", "list");
  url.searchParams.set("pageNo", String(pageNo));
  url.searchParams.set("numOfRows", "500");
  url.searchParams.set("lifeArray", lifeStageCodeForAge(age));
  return url.toString();
}

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

type RawItem = Record<string, unknown>;

function mapItem(raw: RawItem): BenefitServiceDto | null {
  const id = asTrimmedStringOrNull(raw.servId);
  const title = asTrimmedStringOrNull(raw.servNm);
  // id/제목 중 하나라도 없으면 목록에 의미 있게 표시할 수 없다 — 존재하지
  // 않는 혜택을 지어내지 않고 이 항목만 건너뛴다(welfare_center와 동일).
  if (id === null || title === null) return null;
  const summary = asTrimmedStringOrNull(raw.servDgst) ??
    asTrimmedStringOrNull(raw.aplyMtdNm) ?? "";
  return { id, title, summary };
}

// welfare_center와 같은 계열(한국사회보장정보원) API라 동일한 header/body
// 구조(response 래퍼 없음, resultCode "03"=결과없음)를 가정한다 — 확인
// 전까지는 최선 추정치(파일 상단 주석 참고).
export function parseSearchResponse(
  raw: unknown,
): { ok: true; value: BenefitServiceDto[] } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const { header, body } = raw as Record<string, unknown>;
  const resultCode = header !== null && typeof header === "object"
    ? (header as Record<string, unknown>).resultCode
    : undefined;

  if (resultCode === "03") return { ok: true, value: [] };
  if (resultCode !== "00" && resultCode !== "0") {
    return { ok: false, reason: "upstream_error" };
  }
  if (body === null || typeof body !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const items = (body as Record<string, unknown>).items;
  if (items === "" || items === null || items === undefined) {
    return { ok: true, value: [] };
  }
  if (typeof items !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const rawItem = (items as Record<string, unknown>).item;
  if (rawItem === undefined || rawItem === "" || rawItem === null) {
    return { ok: true, value: [] };
  }
  const rawList: unknown[] = Array.isArray(rawItem) ? rawItem : [rawItem];
  const results: BenefitServiceDto[] = [];
  for (const entry of rawList) {
    if (entry === null || typeof entry !== "object") continue;
    const mapped = mapItem(entry as RawItem);
    if (mapped !== null) results.push(mapped);
  }
  return { ok: true, value: results };
}

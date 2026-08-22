// Pure validation/request-building/response-parsing logic for
// `search-welfare-centers`, split out of `index.ts` for the same reason as
// `analyze-message/risk_classifier.ts`: unit-testable without triggering
// `Deno.serve()`'s side effect. No Deno.serve/network imports belong here.
//
// Data source: 공공데이터포털(data.go.kr) "전국마을회관및경로당표준데이터"
// (소관: 행정안전부/보건복지부 지자체 표준데이터, dataset id 15114136),
// Open API endpoint `tn_pubr_public_vill_hall_sen_cent_api`. 무료, 자동승인
// 서비스키 필요 — ONDAM 2.0 요구사항 30.
//
// ONDAM 2.0 PHASE 35 — 실제 서비스키로 라이브 검증한 결과, data.go.kr이
// 게시한 활용가이드(PHASE 26 근거)와 실제 API가 네 가지 지점에서 달랐다:
//   0. 최상위에 "response" 래퍼가 없다 — 문서는
//      `{"response":{"header":...,"body":...}}` 형태를 암시했지만 실제
//      응답은 `{"header":...,"body":...}`로 header/body가 곧바로
//      최상위에 온다.
//   1. 응답/요청 필드명이 UPPER_SNAKE_CASE가 아니라 camelCase다
//      (예: FLCT_NM이 아니라 flctNm).
//   2. resultCode "03"(resultMsg "NODATA_ERROR")은 오류가 아니라 "검색
//      결과 없음"을 뜻한다 — 이때 body는 아예 null로 온다.
//   3. lctnRoadNmAddr는 부분/LIKE 검색이 아니라 완전 일치(exact match)만
//      지원한다 — "서울특별시 강남구" 같은 시/도+시/군/구 접두사로는 절대
//      매치되지 않는다(전체 도로명주소 문자열이 정확히 같아야 함).
//      ctpvNm/sggNm/signguNm/emdNm/insttNm 등 대체 파라미터도 모두
//      거부되거나(INVALID_REQUEST_PARAMETER_ERROR) 서버 오류
//      (SERVICE_ERROR: UncategorizedSQLException)를 반환해 사용할 수
//      없었다. 그래서 서버 측 지역 필터를 포기하고, 페이지 단위로 받아
//      클라이언트(이 Edge Function) 쪽에서 주소 문자열에 시/도+시/군/구가
//      모두 포함되는지로 걸러낸다 — `matchesRegion` 참고.
//      ponytail: 전국 46,386건(2026-08-19 기준) 중 일부 페이지만 훑으므로
//      지역에 따라 결과를 못 찾을 수 있다 — 더 넓은 커버리지가 필요해지면
//      전용 지역코드 파라미터가 있는 다른 데이터셋으로 교체하거나 전체
//      페이지네이션을 도입해야 한다(이번 phase 범위 밖).

export const DATA_GO_KR_ENDPOINT =
  "https://api.data.go.kr/openapi/tn_pubr_public_vill_hall_sen_cent_api";

export type RegionQuery = {
  sido: string;
  sigungu: string;
};

export type WelfareCenterDto = {
  id: string;
  name: string;
  address: string;
  phoneNumber: string | null;
  latitude: number | null;
  longitude: number | null;
};

export function validateRegionBody(
  raw: unknown,
): { ok: true; value: RegionQuery } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "invalid_region" };
  }
  const obj = raw as Record<string, unknown>;
  const sido = typeof obj.sido === "string" ? obj.sido.trim() : "";
  const sigungu = typeof obj.sigungu === "string" ? obj.sigungu.trim() : "";
  if (sido.length === 0 || sigungu.length === 0) {
    return { ok: false, reason: "invalid_region" };
  }
  return { ok: true, value: { sido, sigungu } };
}

// 서버 측 지역 필터가 없으므로 페이지 단위로만 요청을 만든다 — 지역은
// 응답을 받은 뒤 `matchesRegion`으로 클라이언트 쪽에서 거른다.
export function buildRequestUrl(serviceKey: string, pageNo: number): string {
  const url = new URL(DATA_GO_KR_ENDPOINT);
  url.searchParams.set("serviceKey", serviceKey);
  url.searchParams.set("type", "json");
  url.searchParams.set("pageNo", String(pageNo));
  url.searchParams.set("numOfRows", "1000");
  return url.toString();
}

// 시/도와 시/군/구가 모두 주소 문자열에 포함돼야 매치로 본다 — 읍/면/동은
// 요구사항 31이 자유 입력이라 표기가 갈려(예: "역삼동" vs "역삼1동")
// 과도하게 좁히지 않는다.
export function matchesRegion(
  center: WelfareCenterDto,
  region: RegionQuery,
): boolean {
  return center.address.includes(region.sido) &&
    center.address.includes(region.sigungu);
}

type RawItem = Record<string, unknown>;

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function asFiniteNumberOrNull(value: unknown): number | null {
  const num = typeof value === "string" ? Number(value) : value;
  return typeof num === "number" && Number.isFinite(num) ? num : null;
}

function mapItem(raw: RawItem): WelfareCenterDto | null {
  const name = asTrimmedStringOrNull(raw.flctNm);
  const address = asTrimmedStringOrNull(raw.lctnRoadNmAddr) ??
    asTrimmedStringOrNull(raw.lctnLotnoAddr);
  // 시설명/주소 중 하나라도 없으면 목록에 의미 있게 표시할 수 없다 —
  // 존재하지 않는 경로당을 임의로 채워 넣지 않고 이 항목만 건너뛴다.
  if (name === null || address === null) return null;

  return {
    id: `${name}__${address}`,
    name,
    address,
    phoneNumber: asTrimmedStringOrNull(raw.telno),
    latitude: asFiniteNumberOrNull(raw.lat),
    longitude: asFiniteNumberOrNull(raw.lot),
  };
}

// 이 API의 실제 응답 포맷(PHASE 35 라이브 검증): header.resultCode/resultMsg
// + body.items.item(배열, 단건이면 객체, 0건이면 빈 문자열인 경우가 흔함,
// header/body 모두 최상위 — response 래퍼 없음) — 세 경우 모두 방어적으로
// 처리한다. resultCode "03"(NODATA_ERROR)은
// 실제 라이브 검증(PHASE 35)에서 확인된 "결과 없음" 응답이며, 이때 body
// 자체가 null로 온다 — 다른 오류 코드와 구분해서 정상적인 빈 목록으로
// 처리한다.
export function parseWelfareCenterResponse(
  raw: unknown,
): { ok: true; value: WelfareCenterDto[] } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  // 실제 라이브 응답(PHASE 35)에는 문서가 암시했던 최상위 "response" 래퍼가
  // 없다 — header/body가 곧바로 최상위에 온다:
  // {"header":{"resultCode":"00",...},"body":{...}}
  const { header, body } = raw as Record<string, unknown>;

  const resultCode = header !== null && typeof header === "object"
    ? (header as Record<string, unknown>).resultCode
    : undefined;

  if (resultCode === "03") {
    // NODATA_ERROR — 이 페이지/조건에 해당하는 데이터가 없다는 정상 응답.
    return { ok: true, value: [] };
  }
  if (resultCode !== "00" && resultCode !== "0") {
    return { ok: false, reason: "upstream_error" };
  }

  if (body === null || typeof body !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const items = (body as Record<string, unknown>).items;

  // 결과 0건: items가 빈 문자열이거나 아예 없는 경우도 정상적인 "결과
  // 없음"이지, 형식 오류가 아니다.
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
  const results: WelfareCenterDto[] = [];
  for (const entry of rawList) {
    if (entry === null || typeof entry !== "object") continue;
    const mapped = mapItem(entry as RawItem);
    if (mapped !== null) results.push(mapped);
  }
  return { ok: true, value: results };
}

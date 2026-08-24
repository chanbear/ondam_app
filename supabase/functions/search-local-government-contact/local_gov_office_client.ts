// Pure validation/request-building/response-parsing logic for
// `search-local-government-contact`, split out of `index.ts` for the same
// reason as `search-welfare-centers/welfare_center_client.ts`: unit-testable
// without triggering `Deno.serve()`'s side effect. No Deno.serve/network
// imports belong here.
//
// Data source: 공공데이터포털(data.go.kr) "행정안전부_읍면동 하부행정기관
// 현황"(dataset id 15059715,
// https://www.data.go.kr/data/15059715/fileData.do) — 전국 17개 시도·226개
// 시군구의 3,556개 읍면동 하부행정기관(행정복지센터/동 주민센터/읍면
// 사무소)의 시도·시군구·읍면동·우편번호·주소를 제공한다.
//
// ONDAM 2.0 — 이 기능을 설계하며 data.go.kr 페이지를 로그인 없이 확인한 결과
// (2026-08-23, welfare_center_client.ts의 PHASE 26과 동일한 "최선 추정"
// 상황):
//   0. 공식 "데이터 항목(컬럼) 정보" 표에 나열된 컬럼은 정확히
//      연번/시도/시군구/읍면동/우편번호/주소 6개뿐이다 — **전화번호도
//      기관명(시설명) 컬럼도 없다.** 이 기능을 요청한 스펙은 이 데이터셋에
//      전화번호가 포함된다고 가정했지만, 확인 결과 그렇지 않다. 가짜
//      전화번호를 채우지 않고 `phoneNumber`는 항상 null로 둔다 — 다른 데이터
//      소스가 연결되기 전까지의 알려진 한계다(ponytail: 전화번호가 꼭
//      필요해지면 시군구별로 흩어져 있는 개별 지자체 데이터셋을 별도로
//      통합하거나, 행정안전부에 전화번호 포함 표준데이터 신규 등록을
//      요청해야 한다 — 이번 phase 범위 밖).
//   1. 이 데이터셋은 `openapi.do` 페이지가 없다(404 확인) —
//      `search-welfare-centers`가 쓰는 `tn_pubr_*` 스타일의 별도 등록
//      Open API가 아니라, 공공데이터활용지원센터가 파일데이터를 3성급으로
//      자동 변환한 odcloud.kr 계열 Open API로만 제공된다(fileData.do
//      페이지의 "Open API" 탭 + "Swagger UI 명세서" 링크로 확인).
//   2. odcloud 계열 API는 데이터셋마다 고유한 `uddi:<uuid>` 식별자를 URL에
//      포함해야 하는데, 이 uuid는 data.go.kr 로그인 후 활용신청을 마쳐야
//      Swagger 문서에서 볼 수 있다 — 로그인 없이는 알아낼 수 없었다
//      (welfare_center_client.ts의 tn_pubr_* 엔드포인트와 달리, 이름
//      규칙으로 추측할 수 있는 값이 아니다). 아래 DATA_GO_KR_ENDPOINT의
//      uddi 부분은 **실제 값이 아니라 자리표시자**다 — 실제 서비스키로
//      로그인해 이 데이터셋의 활용신청 페이지에서 진짜 uddi를 확인한 뒤
//      반드시 교체해야 한다. 그 전까지는 요청이 실패하고, index.ts가
//      이를 upstream_error로 정직하게 매핑해 UI에 "정보를 불러오지
//      못했습니다"로 보여준다 — 가짜 데이터를 보여주지 않는다.
//   3. odcloud 3성급 API의 요청/응답 형식(page/perPage/serviceKey 쿼리,
//      "data" 배열, 컬럼명이 원본 그대로 한글 키)은 공공데이터포털의 표준
//      규격을 따른다고 가정했다 — 이 부분도 실제 서비스키로 라이브 검증이
//      필요하다(welfare_center가 PHASE 35에서 겪었던 것과 같은 종류의
//      보정이 있을 수 있다).

export const DATA_GO_KR_ENDPOINT =
  // PLACEHOLDER — 실제 uddi 값 확인 필요(위 주석 §2 참고).
  "https://api.odcloud.kr/api/15059715/v1/uddi:REPLACE_WITH_REAL_UDDI";

export type RegionQuery = {
  sido: string;
  sigungu: string;
  dong: string;
};

export type LocalGovOfficeDto = {
  sido: string;
  sigungu: string;
  dong: string;
  postalCode: string | null;
  address: string;
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
  const dong = typeof obj.dong === "string" ? obj.dong.trim() : "";
  if (sido.length === 0 || sigungu.length === 0 || dong.length === 0) {
    return { ok: false, reason: "invalid_region" };
  }
  return { ok: true, value: { sido, sigungu, dong } };
}

// odcloud 3성급 자동변환 API의 표준 쿼리 파라미터로 가정한다(라이브 검증
// 필요 — 위 파일 상단 주석 §3 참고). 서버 측 컬럼 필터(cond[...])는 쓰지
// 않는다 — welfare_center_client.ts와 같은 이유로, 사용자가 등록한 읍면동
// 자유 입력 표기가 데이터셋의 표준 명칭과 다를 수 있어 정확 일치 필터를
// 믿을 수 없다. 대신 페이지 단위로 받아 index.ts에서 `matchesRegion`으로
// 걸러낸다.
export function buildRequestUrl(serviceKey: string, pageNo: number): string {
  const url = new URL(DATA_GO_KR_ENDPOINT);
  url.searchParams.set("page", String(pageNo));
  url.searchParams.set("perPage", "1000");
  url.searchParams.set("serviceKey", serviceKey);
  return url.toString();
}

// 시도/시군구/읍면동이 모두 정확히 일치해야 매치로 본다 — 이 데이터셋은
// 행정동 표준 명칭을 쓰는 것으로 보여, welfare_center의 주소 부분일치와
// 달리 정확 일치로 시작한다. ponytail: 사용자가 등록한 자유 입력 읍면동
// 표기가 데이터셋과 다르면(예: "역삼동" vs "역삼1동") 못 찾을 수 있다 —
// 실사용에서 이 문제가 확인되면 부분 일치/유사매칭으로 완화해야 한다(이번
// phase 범위 밖).
export function matchesRegion(
  office: LocalGovOfficeDto,
  region: RegionQuery,
): boolean {
  return office.sido === region.sido &&
    office.sigungu === region.sigungu &&
    office.dong === region.dong;
}

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

type RawItem = Record<string, unknown>;

function mapItem(raw: RawItem): LocalGovOfficeDto | null {
  const sido = asTrimmedStringOrNull(raw["시도"]);
  const sigungu = asTrimmedStringOrNull(raw["시군구"]);
  const dong = asTrimmedStringOrNull(raw["읍면동"]);
  const address = asTrimmedStringOrNull(raw["주소"]);
  // 행정구역/주소 중 하나라도 없으면 목록에 의미 있게 표시하거나 지역과
  // 매칭할 수 없다 — 존재하지 않는 기관을 임의로 채우지 않고 이 항목만
  // 건너뛴다(welfare_center_client.ts의 mapItem과 동일한 원칙).
  if (sido === null || sigungu === null || dong === null || address === null) {
    return null;
  }
  return {
    sido,
    sigungu,
    dong,
    postalCode: asTrimmedStringOrNull(raw["우편번호"]),
    address,
  };
}

// odcloud.kr 3성급 자동변환 Open API의 표준 응답 형태로 가정한다(라이브
// 검증 필요 — 위 파일 상단 주석 §3 참고): {"data":[...], "currentCount":..,
// "matchCount":.., "page":.., "perPage":.., "totalCount":..}.
export function parseLocalGovOfficeResponse(
  raw: unknown,
): { ok: true; value: LocalGovOfficeDto[] } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const data = (raw as Record<string, unknown>).data;
  if (!Array.isArray(data)) {
    return { ok: false, reason: "upstream_invalid_response" };
  }

  const results: LocalGovOfficeDto[] = [];
  for (const entry of data) {
    if (entry === null || typeof entry !== "object") continue;
    const mapped = mapItem(entry as RawItem);
    if (mapped !== null) results.push(mapped);
  }
  return { ok: true, value: results };
}

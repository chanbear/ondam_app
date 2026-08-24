// NOT AVAILABLE: not executed in this environment (no Deno CLI — see the
// identical note in search-welfare-centers/welfare_center_client.test.ts).
// Provided as a best-effort artifact for review/future execution. Only
// imports from `local_gov_office_client.ts` (no Deno.serve side effect).

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildRequestUrl,
  LocalGovOfficeDto,
  matchesRegion,
  parseLocalGovOfficeResponse,
  validateRegionBody,
} from "./local_gov_office_client.ts";

// --- validateRegionBody ----------------------------------------------------

Deno.test("validateRegionBody: 시도·시군구·읍면동이 모두 있으면 통과한다", () => {
  const result = validateRegionBody({
    sido: "서울특별시",
    sigungu: "강남구",
    dong: "역삼동",
  });
  assertEquals(result.ok, true);
});

Deno.test("validateRegionBody: 읍면동이 없으면 invalid_region", () => {
  const result = validateRegionBody({
    sido: "서울특별시",
    sigungu: "강남구",
    dong: "",
  });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_region");
});

Deno.test("validateRegionBody: region 자체가 없으면 invalid_region", () => {
  const result = validateRegionBody(undefined);
  assertEquals(result.ok, false);
});

// --- buildRequestUrl ---------------------------------------------------

Deno.test("buildRequestUrl: 서비스키/페이지 번호/perPage를 담는다", () => {
  const url = buildRequestUrl("test-key", 2);
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("page"), "2");
  assertEquals(parsed.searchParams.get("perPage"), "1000");
});

// --- matchesRegion -----------------------------------------------------

Deno.test("matchesRegion: 시도/시군구/읍면동이 모두 정확히 일치해야 매치한다", () => {
  const office: LocalGovOfficeDto = {
    sido: "서울특별시",
    sigungu: "강남구",
    dong: "역삼동",
    postalCode: "06236",
    address: "서울특별시 강남구 테헤란로 지하 426",
  };
  assertEquals(
    matchesRegion(office, { sido: "서울특별시", sigungu: "강남구", dong: "역삼동" }),
    true,
  );
  assertEquals(
    matchesRegion(office, {
      sido: "서울특별시",
      sigungu: "강남구",
      dong: "역삼1동",
    }),
    false,
  );
  assertEquals(
    matchesRegion(office, { sido: "서울특별시", sigungu: "서초구", dong: "역삼동" }),
    false,
  );
});

// --- parseLocalGovOfficeResponse ---------------------------------------

Deno.test("정상 응답: data 배열을 한글 컬럼명 그대로 매핑한다", () => {
  const raw = {
    data: [
      {
        "시도": "서울특별시",
        "시군구": "강남구",
        "읍면동": "역삼동",
        "우편번호": "06236",
        "주소": "서울특별시 강남구 테헤란로 지하 426",
      },
    ],
    currentCount: 1,
    matchCount: 1,
    page: 1,
    perPage: 1000,
    totalCount: 3556,
  };
  const result = parseLocalGovOfficeResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: LocalGovOfficeDto[] }).value;
  assertEquals(value.length, 1);
  assertEquals(value[0].dong, "역삼동");
  assertEquals(value[0].postalCode, "06236");
});

Deno.test("결과 없음: data가 빈 배열이면 정상적인 빈 목록이다", () => {
  const result = parseLocalGovOfficeResponse({ data: [] });
  assertEquals(result.ok, true);
  assertEquals((result as { value: LocalGovOfficeDto[] }).value, []);
});

Deno.test("잘못된 데이터: raw가 객체가 아니면 upstream_invalid_response", () => {
  const result = parseLocalGovOfficeResponse("not an object");
  assertEquals(result.ok, false);
  assertEquals(
    (result as { reason: string }).reason,
    "upstream_invalid_response",
  );
});

Deno.test("잘못된 데이터: data 필드가 없거나 배열이 아니면 upstream_invalid_response", () => {
  for (const raw of [{ unexpected: true }, { data: "not an array" }]) {
    const result = parseLocalGovOfficeResponse(raw);
    assertEquals(result.ok, false);
    assertEquals(
      (result as { reason: string }).reason,
      "upstream_invalid_response",
    );
  }
});

Deno.test(
  "잘못된 데이터: 시도/시군구/읍면동/주소 중 하나라도 없는 행은 존재하지 않는 기관을 지어내지 않고 건너뛴다",
  () => {
    const raw = {
      data: [
        { "시도": "서울특별시" }, // 시군구/읍면동/주소 없음 — 버려야 한다
        {
          "시도": "서울특별시",
          "시군구": "강남구",
          "읍면동": "역삼동",
          "주소": "서울특별시 강남구 3",
        },
      ],
    };
    const result = parseLocalGovOfficeResponse(raw);
    assertEquals(result.ok, true);
    const value = (result as { value: LocalGovOfficeDto[] }).value;
    assertEquals(value.length, 1);
    assertEquals(value[0].dong, "역삼동");
  },
);

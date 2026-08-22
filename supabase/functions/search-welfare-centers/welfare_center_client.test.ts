// NOT AVAILABLE: not executed in this environment (no Deno CLI — see the
// identical note in analyze-message/risk_classifier.test.ts). Provided as a
// best-effort artifact for review/future execution. Only imports from
// `welfare_center_client.ts` (no Deno.serve side effect).
//
// ONDAM 2.0 PHASE 35 — 실제 서비스키로 라이브 검증한 뒤 필드명(camelCase)/
// resultCode "03"(NODATA_ERROR) 처리/지역 매칭 로직을 실제 API 응답에 맞게
// 갱신했다. welfare_center_client.ts 상단 주석 참고.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildRequestUrl,
  matchesRegion,
  parseWelfareCenterResponse,
  validateRegionBody,
  WelfareCenterDto,
} from "./welfare_center_client.ts";

// --- validateRegionBody ----------------------------------------------------

Deno.test("validateRegionBody: 시/도·시/군/구가 모두 있으면 통과한다", () => {
  const result = validateRegionBody({ sido: "서울특별시", sigungu: "강남구" });
  assertEquals(result.ok, true);
});

Deno.test("validateRegionBody: 시/군/구가 없으면 invalid_region", () => {
  const result = validateRegionBody({ sido: "서울특별시", sigungu: "" });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_region");
});

Deno.test("validateRegionBody: region 자체가 없으면 invalid_region", () => {
  const result = validateRegionBody(undefined);
  assertEquals(result.ok, false);
});

// --- buildRequestUrl (페이지 단위 요청 — 서버 측 지역 필터가 없다) ----------

Deno.test("buildRequestUrl: 서비스키/페이지 번호/한 번에 최대치를 담는다", () => {
  const url = buildRequestUrl("test-key", 3);
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("type"), "json");
  assertEquals(parsed.searchParams.get("pageNo"), "3");
  assertEquals(parsed.searchParams.get("numOfRows"), "1000");
});

// --- matchesRegion (지역별 검색 — 클라이언트 측 필터) -----------------------

Deno.test("matchesRegion: 시/도와 시/군/구가 모두 주소에 포함돼야 매치한다", () => {
  const center: WelfareCenterDto = {
    id: "1",
    name: "역삼경로당",
    address: "서울특별시 강남구 역삼로 1",
    phoneNumber: null,
    latitude: null,
    longitude: null,
  };
  assertEquals(
    matchesRegion(center, { sido: "서울특별시", sigungu: "강남구" }),
    true,
  );
  assertEquals(
    matchesRegion(center, { sido: "서울특별시", sigungu: "서초구" }),
    false,
  );
  assertEquals(
    matchesRegion(center, { sido: "부산광역시", sigungu: "강남구" }),
    false,
  );
});

// --- parseWelfareCenterResponse ---------------------------------------------

// PHASE 35 라이브 검증에서 확인된 실제 최상위 형태 — "response" 래퍼가
// 없다: {"header":{...},"body":...}
function envelope(body: unknown, resultCode = "00") {
  return { header: { resultCode }, body };
}

Deno.test("정상 검색: 배열 결과를 그대로 매핑한다(camelCase 필드)", () => {
  const raw = envelope({
    items: {
      item: [
        {
          flctNm: "역삼경로당",
          lctnRoadNmAddr: "서울특별시 강남구 역삼로 1",
          telno: "02-1234-5678",
          lat: "37.5",
          lot: "127.0",
        },
      ],
    },
  });
  const result = parseWelfareCenterResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: unknown[] }).value;
  assertEquals(value.length, 1);
  assertEquals((value[0] as { name: string }).name, "역삼경로당");
  assertEquals(
    (value[0] as { phoneNumber: string }).phoneNumber,
    "02-1234-5678",
  );
  assertEquals((value[0] as { latitude: number }).latitude, 37.5);
});

Deno.test("정상 검색: 단건 결과는 item이 배열이 아니라 객체로 와도 처리한다", () => {
  const raw = envelope({
    items: {
      item: {
        flctNm: "개포경로당",
        lctnRoadNmAddr: "서울특별시 강남구 개포로 2",
      },
    },
  });
  const result = parseWelfareCenterResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value.length, 1);
});

Deno.test(
  "결과 없음: resultCode가 03(NODATA_ERROR)이면 body가 null이어도 오류가 아니라 빈 목록이다"
  + " (PHASE 35 라이브 검증에서 확인된 실제 응답 형태)",
  () => {
    const raw = { header: { resultCode: "03", resultMsg: "NODATA_ERROR" }, body: null };
    const result = parseWelfareCenterResponse(raw);
    assertEquals(result.ok, true);
    assertEquals((result as { value: unknown[] }).value, []);
  },
);

Deno.test("결과 없음: items가 빈 문자열이면 형식 오류가 아니라 빈 목록이다", () => {
  const raw = envelope({ items: "" });
  const result = parseWelfareCenterResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value, []);
});

Deno.test(
  "API 오류: resultCode가 00/03이 아니면 upstream_error(실제 관측된 10=파라미터 오류, 99=서버 오류 포함)",
  () => {
    for (const code of ["10", "99"]) {
      const raw = envelope({ items: "" }, code);
      const result = parseWelfareCenterResponse(raw);
      assertEquals(result.ok, false, `resultCode ${code}`);
      assertEquals((result as { reason: string }).reason, "upstream_error");
    }
  },
);

Deno.test("잘못된 데이터: raw 자체가 객체가 아니면 upstream_invalid_response", () => {
  const result = parseWelfareCenterResponse("not an object");
  assertEquals(result.ok, false);
  assertEquals(
    (result as { reason: string }).reason,
    "upstream_invalid_response",
  );
});

Deno.test("잘못된 데이터: header/resultCode가 아예 없으면 upstream_error로 안전하게 실패한다", () => {
  const result = parseWelfareCenterResponse({ unexpected: true });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "upstream_error");
});

Deno.test(
  "잘못된 데이터: 시설명/주소가 둘 다 없는 항목은 존재하지 않는 경로당을 지어내지 않고 건너뛴다",
  () => {
    const raw = envelope({
      items: {
        item: [
          { telno: "02-0000-0000" }, // 이름/주소 없음 — 버려야 한다
          {
            flctNm: "정상경로당",
            lctnRoadNmAddr: "서울특별시 강남구 3",
          },
        ],
      },
    });
    const result = parseWelfareCenterResponse(raw);
    assertEquals(result.ok, true);
    const value = (result as { value: { name: string }[] }).value;
    assertEquals(value.length, 1);
    assertEquals(value[0].name, "정상경로당");
  },
);

Deno.test("잘못된 데이터: 위도/경도가 숫자가 아니면 null로 처리하고 항목 자체는 버리지 않는다", () => {
  const raw = envelope({
    items: {
      item: [
        {
          flctNm: "역삼경로당",
          lctnRoadNmAddr: "서울특별시 강남구 역삼로 1",
          lat: "잘못된값",
        },
      ],
    },
  });
  const result = parseWelfareCenterResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: { latitude: number | null }[] }).value;
  assertEquals(value[0].latitude, null);
});

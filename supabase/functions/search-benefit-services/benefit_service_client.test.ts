// NOT AVAILABLE: not executed in this environment (no Deno CLI — same as
// welfare_center_client.test.ts). Provided as a best-effort artifact for
// review/future execution.
//
// 응답 파싱(parseSearchResponse)이 검증하는 아이템 필드명 자체가
// benefit_service_client.ts 상단 주석에 적힌 대로 "미확인 초안"이다 —
// 실제 서비스키로 라이브 검증한 뒤 필드명이 바뀌면 이 테스트도
// welfare_center_client.test.ts의 PHASE 35 사례처럼 함께 갱신해야 한다.
// buildRequestUrl의 "type=json" 누락(정보 탭이 항상 비어 보이던 원인)은
// 이번에 고쳤고, 아래 테스트가 회귀를 막는다.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildRequestUrl,
  lifeStageCodeForAge,
  parseSearchResponse,
  validateSearchBody,
} from "./benefit_service_client.ts";

// --- validateSearchBody ------------------------------------------------------

Deno.test("validateSearchBody: 나이/성별/지역이 모두 있으면 통과한다", () => {
  const result = validateSearchBody({
    age: 72,
    gender: "female",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, true);
});

Deno.test("validateSearchBody: 나이가 범위를 벗어나면 invalid_request", () => {
  const result = validateSearchBody({
    age: 0,
    gender: "female",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_request");
});

Deno.test("validateSearchBody: 성별이 male/female이 아니면 invalid_request", () => {
  const result = validateSearchBody({
    age: 72,
    gender: "unknown",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, false);
});

Deno.test("validateSearchBody: 지역이 없으면 invalid_request", () => {
  const result = validateSearchBody({ age: 72, gender: "female" });
  assertEquals(result.ok, false);
});

// --- lifeStageCodeForAge ------------------------------------------------------

Deno.test("lifeStageCodeForAge: 65세 미만은 005, 65세 이상은 006", () => {
  assertEquals(lifeStageCodeForAge(64), "005");
  assertEquals(lifeStageCodeForAge(65), "006");
});

// --- buildRequestUrl -----------------------------------------------------------

Deno.test("buildRequestUrl: 서비스키/생애주기코드/페이지 번호를 담는다", () => {
  const url = buildRequestUrl("https://example.com/api", "test-key", 2, 70);
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("callTp"), "list");
  assertEquals(parsed.searchParams.get("pageNo"), "2");
  assertEquals(parsed.searchParams.get("lifeArray"), "006");
});

// BUG 회귀 테스트 — "type=json"이 빠지면 data.go.kr이 기본 XML로 응답해
// response.json()이 매번 실패하고(그 실패가 조용히 빈 결과로 삼켜져)
// "정보" 탭이 항상 비어 보였다. welfare_center_client.ts가 이미 검증한
// 패턴과 동일하게 이 파라미터를 요구한다.
Deno.test("buildRequestUrl: JSON 응답을 요청한다(type=json)", () => {
  const url = buildRequestUrl("https://example.com/api", "test-key", 1, 70);
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("type"), "json");
});

// --- parseSearchResponse ---------------------------------------------------------

function envelope(body: unknown, resultCode = "00") {
  return { header: { resultCode }, body };
}

Deno.test("정상 검색: 배열 결과를 그대로 매핑한다", () => {
  const raw = envelope({
    items: {
      item: [
        { servId: "WLF001", servNm: "기초연금", servDgst: "만 65세 이상 지원" },
      ],
    },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: unknown[] }).value;
  assertEquals(value.length, 1);
  assertEquals((value[0] as { title: string }).title, "기초연금");
});

Deno.test("정상 검색: 단건 결과는 item이 배열이 아니라 객체로 와도 처리한다", () => {
  const raw = envelope({
    items: { item: { servId: "WLF002", servNm: "무료 건강검진" } },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value.length, 1);
});

Deno.test("결과 없음: resultCode 03은 오류가 아니라 빈 목록이다", () => {
  const raw = { header: { resultCode: "03" }, body: null };
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value, []);
});

Deno.test("API 오류: resultCode가 00/03이 아니면 upstream_error", () => {
  const raw = envelope({ items: "" }, "99");
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "upstream_error");
});

Deno.test("잘못된 데이터: id/제목이 둘 다 없는 항목은 지어내지 않고 건너뛴다", () => {
  const raw = envelope({
    items: {
      item: [
        { servDgst: "이름 없는 항목" },
        { servId: "WLF003", servNm: "정상 항목" },
      ],
    },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: { title: string }[] }).value;
  assertEquals(value.length, 1);
  assertEquals(value[0].title, "정상 항목");
});

Deno.test("잘못된 데이터: raw 자체가 객체가 아니면 upstream_invalid_response", () => {
  const result = parseSearchResponse("not an object");
  assertEquals(result.ok, false);
  assertEquals(
    (result as { reason: string }).reason,
    "upstream_invalid_response",
  );
});

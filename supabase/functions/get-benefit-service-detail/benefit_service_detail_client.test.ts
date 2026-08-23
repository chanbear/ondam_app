// NOT AVAILABLE: not executed in this environment (no Deno CLI). See
// benefit_service_client.test.ts 상단 주석과 동일한 이유.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildDetailRequestUrl,
  parseDetailResponse,
  validateDetailBody,
} from "./benefit_service_detail_client.ts";

Deno.test("validateDetailBody: id/source가 모두 있으면 통과한다", () => {
  const result = validateDetailBody({ id: "WLF001", source: "local" });
  assertEquals(result.ok, true);
});

Deno.test("validateDetailBody: source가 local/central이 아니면 invalid_request", () => {
  const result = validateDetailBody({ id: "WLF001", source: "unknown" });
  assertEquals(result.ok, false);
});

Deno.test("validateDetailBody: id가 비어 있으면 invalid_request", () => {
  const result = validateDetailBody({ id: "", source: "local" });
  assertEquals(result.ok, false);
});

Deno.test("buildDetailRequestUrl: 서비스키/servId를 담는다", () => {
  const url = buildDetailRequestUrl(
    "https://example.com/api",
    "test-key",
    "WLF001",
  );
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("callTp"), "d");
  assertEquals(parsed.searchParams.get("servId"), "WLF001");
});

function envelope(body: unknown, resultCode = "00") {
  return { header: { resultCode }, body };
}

Deno.test("정상 상세: 단건 객체를 매핑한다", () => {
  const raw = envelope({
    items: {
      item: {
        servNm: "기초연금",
        servDgst: "만 65세 이상 지원",
        slctCritCn: "소득 하위 70%",
        aplyMtdCn: "주민센터 방문 신청",
        rprsCtadr: "129",
      },
    },
  });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as {
    value: { title: string; supportTarget: string | null } | null;
  }).value;
  assertEquals(value?.title, "기초연금");
  assertEquals(value?.supportTarget, "소득 하위 70%");
});

Deno.test("정상 상세: item이 배열로 와도 첫 항목을 사용한다", () => {
  const raw = envelope({ items: { item: [{ servNm: "기초연금" }] } });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals(
    (result as { value: { title: string } | null }).value?.title,
    "기초연금",
  );
});

Deno.test("결과 없음: resultCode 03이면 오류가 아니라 null이다", () => {
  const raw = { header: { resultCode: "03" }, body: null };
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown }).value, null);
});

Deno.test("제목이 없는 항목은 지어내지 않고 null을 반환한다", () => {
  const raw = envelope({ items: { item: { servDgst: "제목 없음" } } });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown }).value, null);
});

Deno.test("API 오류: resultCode가 00/03이 아니면 upstream_error", () => {
  const raw = envelope({ items: "" }, "99");
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "upstream_error");
});

import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  buildRequestUrl,
  matchesRegion,
  parseWelfareCenterResponse,
  validateRegionBody,
  WelfareCenterDto,
} from "./welfare_center_client.ts";

// ONDAM 2.0 요구사항 30 — 경로당 찾기. 공공데이터포털(data.go.kr)
// "전국마을회관및경로당표준데이터" Open API를 서버 측에서만 호출한다:
// 서비스키가 클라이언트에 절대 노출되지 않고(analyze-message의
// ANTHROPIC_API_KEY와 동일한 이유), 클라이언트는 좌표가 아니라 이미 저장된
// 행정구역 문자열(시/도·시/군/구)만 보낸다 — 위치 개인정보 원칙(§9): 현재
// 위치 좌표를 서버로 보내지 않는다.
//
// PHASE 35 — 실제 API에는 시/도·시/군/구 단위로 걸러주는 서버 측 필터가
// 없다(주소 필드는 완전 일치만 지원, 대체 파라미터는 전부 거부/오류) —
// welfare_center_client.ts 상단 주석 참고. 그래서 여러 페이지를 순서대로
// 받아 이 함수 안에서 주소 문자열로 걸러낸다. 충분한 결과를 찾으면 즉시
// 멈추고, 페이지 한도에 도달하면 그때까지 찾은 결과만 정직하게 반환한다
// (전국 데이터 전체를 다 훑지는 않는다 — ponytail: 알려진 한계, 위
// client.ts 주석의 업그레이드 경로 참고).

const REQUEST_TIMEOUT_MS = 10000;
// 실제 데이터(PHASE 35 라이브 검증)는 시/군/구 단위로 큰 연속 블록으로
// 묶여 있어(예: 성북구 전체가 8페이지, 강서구 전체가 9~10페이지) 페이지를
// 몇 개만 훑어서는 임의의 지역을 찾을 확률이 낮다 — 전체 47페이지(약
// 46,386건) 중 일부만 본다는 뜻이다. 페이지 하나는 실측 0.3초 내외로 빨라
// 10페이지도 총 3~5초 수준이라 이 정도까지는 늘렸다. 그래도 여전히 부분
// 커버리지다 — ponytail: 완전한 전국 커버리지가 필요해지면 전체
// 페이지네이션을 백그라운드로 인덱싱해 두는 구조(별도 테이블 캐시 등)로
// 바꿔야 한다(이번 phase 범위 밖).
const MAX_PAGES = 10;
const TARGET_RESULT_COUNT = 20;

async function fetchPage(
  serviceKey: string,
  pageNo: number,
): Promise<
  { ok: true; value: WelfareCenterDto[] } | { ok: false; reason: string }
> {
  const url = buildRequestUrl(serviceKey, pageNo);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch(url, { signal: controller.signal });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return { ok: false, reason: "upstream_timeout" };
    }
    console.error("search-welfare-centers: fetch to data.go.kr threw", e);
    return { ok: false, reason: "upstream_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `search-welfare-centers: data.go.kr responded ${response.status}`,
      errorBody.slice(0, 500),
    );
    return { ok: false, reason: "upstream_error" };
  }

  let rawJson: unknown;
  try {
    rawJson = await response.json();
  } catch {
    return { ok: false, reason: "upstream_invalid_response" };
  }

  return parseWelfareCenterResponse(rawJson);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const caller = await verifyCaller(req);
  if ("error" in caller) {
    return json({ ok: false, reason: caller.error }, 401);
  }

  const body = await req.json().catch(() => null);
  const validated = validateRegionBody(body?.region);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }

  // 사용자가 data.go.kr에서 직접 발급받아 Supabase project secret으로
  // 등록해야 하는 값 — 하드코딩하지 않는다(§8). 미설정 상태는 서버가 시도
  // 조차 하지 않고도 알 수 있는 "아직 준비 안 됨"이라, analyze-*의
  // ai_provider_not_configured와 동일한 패턴으로 처리한다.
  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const region = validated.value;
  const matched: WelfareCenterDto[] = [];

  for (let pageNo = 1; pageNo <= MAX_PAGES; pageNo++) {
    const page = await fetchPage(serviceKey, pageNo);
    if (!page.ok) {
      // 이미 몇 건이라도 찾았다면, 이후 페이지 하나의 일시적 오류 때문에
      // 지금까지 찾은 정직한 결과 전체를 오류로 덮어쓰지 않는다.
      if (matched.length > 0) break;
      return json({ ok: false, reason: page.reason }, 502);
    }
    if (page.value.length === 0) break; // 마지막 페이지(더 이상 데이터 없음).

    for (const center of page.value) {
      if (matchesRegion(center, region)) matched.push(center);
    }
    if (matched.length >= TARGET_RESULT_COUNT) break;
  }

  return json({ ok: true, results: matched });
});

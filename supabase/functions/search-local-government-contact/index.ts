import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  buildRequestUrl,
  LocalGovOfficeDto,
  matchesRegion,
  parseLocalGovOfficeResponse,
  validateRegionBody,
} from "./local_gov_office_client.ts";

// 고객 지원 화면의 "관할 시청/군청/구청/동 주민센터 연락처" 안내 — ONDAM
// 회사 자체 고객센터가 아니라, 어르신이 이미 등록한 지역의 관할 행정기관
// 정보다. 데이터 소스/알려진 한계(특히 전화번호 컬럼이 없다는 점)는
// local_gov_office_client.ts 상단 주석 참고 — `search-welfare-centers`와
// 동일한 이유로 서비스키는 클라이언트에 노출되지 않고, 클라이언트는 좌표가
// 아니라 이미 저장된 행정구역 문자열만 보낸다.

const REQUEST_TIMEOUT_MS = 10000;
// 전국 3,556건 — perPage 1000 기준 4페이지면 전체를 덮는다(welfare_center의
// 46,386건과 달리 부분 커버리지 문제가 없다).
const MAX_PAGES = 4;

async function fetchPage(
  serviceKey: string,
  pageNo: number,
): Promise<
  { ok: true; value: LocalGovOfficeDto[] } | { ok: false; reason: string }
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
    console.error(
      "search-local-government-contact: fetch to data.go.kr threw",
      e,
    );
    return { ok: false, reason: "upstream_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `search-local-government-contact: data.go.kr responded ${response.status}`,
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

  return parseLocalGovOfficeResponse(rawJson);
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

  // data.go.kr 활용신청으로 발급받는 값 — 하드코딩하지 않는다(§8).
  // search-welfare-centers와 같은 secret을 재사용한다(같은 data.go.kr
  // 계정의 공용 서비스키).
  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const region = validated.value;
  let match: LocalGovOfficeDto | null = null;

  for (let pageNo = 1; pageNo <= MAX_PAGES; pageNo++) {
    const page = await fetchPage(serviceKey, pageNo);
    if (!page.ok) {
      return json({ ok: false, reason: page.reason }, 502);
    }
    if (page.value.length === 0) break; // 마지막 페이지(더 이상 데이터 없음).

    match = page.value.find((office) => matchesRegion(office, region)) ??
      null;
    if (match !== null) break;
  }

  return json({
    ok: true,
    result: match === null ? null : {
      address: match.address,
      postalCode: match.postalCode,
      // 데이터 소스에 전화번호 컬럼이 없다(local_gov_office_client.ts 상단
      // 주석 참고) — 가짜 번호를 채우지 않고 항상 null로 둔다.
      phoneNumber: null,
    },
  });
});

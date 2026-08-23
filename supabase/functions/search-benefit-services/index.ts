import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  BenefitServiceDto,
  buildRequestUrl,
  CENTRAL_GOV_ENDPOINT,
  LOCAL_GOV_ENDPOINT,
  parseSearchResponse,
  validateSearchBody,
} from "./benefit_service_client.ts";

// ONDAM 2.0 — 나이/성별/지역 기반 맞춤 혜택 정보(정보 탭). 서버 측에서만
// data.go.kr을 호출한다(서비스키 비노출, search-welfare-centers와 동일
// 이유). 지자체+중앙부처 두 데이터셋을 병렬로 조회해 합친다.

const REQUEST_TIMEOUT_MS = 10000;
const MAX_PAGES_PER_SOURCE = 5;
const TARGET_RESULT_COUNT = 30;

type Source = "local" | "central";

async function fetchPage(
  endpoint: string,
  serviceKey: string,
  pageNo: number,
  age: number,
  source: Source,
): Promise<
  { ok: true; value: BenefitServiceDto[] } | { ok: false; reason: string }
> {
  const url = buildRequestUrl(endpoint, serviceKey, pageNo, age);
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
    console.error(`search-benefit-services: fetch to ${source} threw`, e);
    return { ok: false, reason: "upstream_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `search-benefit-services: ${source} responded ${response.status}`,
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
  return parseSearchResponse(rawJson);
}

async function fetchSource(
  endpoint: string,
  serviceKey: string,
  age: number,
  source: Source,
): Promise<Array<BenefitServiceDto & { source: Source }>> {
  const collected: Array<BenefitServiceDto & { source: Source }> = [];
  for (let pageNo = 1; pageNo <= MAX_PAGES_PER_SOURCE; pageNo++) {
    const page = await fetchPage(endpoint, serviceKey, pageNo, age, source);
    // 한 소스가 실패해도 다른 소스 결과는 정직하게 반환한다 — 이미 찾은
    // 결과가 있으면 그대로 두고, 없으면 이 소스는 빈 목록으로 취급한다.
    if (!page.ok) break;
    if (page.value.length === 0) break;
    collected.push(...page.value.map((item) => ({ ...item, source })));
    if (collected.length >= TARGET_RESULT_COUNT) break;
  }
  return collected;
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
  const validated = validateSearchBody(body);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }

  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const { age } = validated.value;
  const [local, central] = await Promise.all([
    fetchSource(LOCAL_GOV_ENDPOINT, serviceKey, age, "local"),
    fetchSource(CENTRAL_GOV_ENDPOINT, serviceKey, age, "central"),
  ]);

  return json({ ok: true, results: [...local, ...central] });
});

import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  buildDetailRequestUrl,
  CENTRAL_GOV_DETAIL_ENDPOINT,
  LOCAL_GOV_DETAIL_ENDPOINT,
  parseDetailResponse,
  validateDetailBody,
} from "./benefit_service_detail_client.ts";

const REQUEST_TIMEOUT_MS = 10000;

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
  const validated = validateDetailBody(body);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }

  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const { id, source } = validated.value;
  const endpoint = source === "local"
    ? LOCAL_GOV_DETAIL_ENDPOINT
    : CENTRAL_GOV_DETAIL_ENDPOINT;
  const url = buildDetailRequestUrl(endpoint, serviceKey, id);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(url, { signal: controller.signal });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return json({ ok: false, reason: "upstream_timeout" }, 502);
    }
    console.error("get-benefit-service-detail: fetch threw", e);
    return json({ ok: false, reason: "upstream_error" }, 502);
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `get-benefit-service-detail: upstream responded ${response.status}`,
      errorBody.slice(0, 500),
    );
    return json({ ok: false, reason: "upstream_error" }, 502);
  }

  let rawJson: unknown;
  try {
    rawJson = await response.json();
  } catch {
    return json({ ok: false, reason: "upstream_invalid_response" }, 502);
  }

  const parsed = parseDetailResponse(rawJson);
  if (!parsed.ok) return json({ ok: false, reason: parsed.reason }, 502);
  if (parsed.value === null) {
    return json({ ok: false, reason: "not_found" }, 404);
  }

  return json({ ok: true, result: { id, ...parsed.value } });
});

import { corsHeaders } from "./cors.ts";

// Every Edge Function response goes through this helper so the response
// shape and CORS headers stay consistent — handlers never build a Response
// by hand.
export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

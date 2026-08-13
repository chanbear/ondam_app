// Shared CORS headers for all Edge Functions in this project. Only the
// Flutter apps (via supabase_flutter, which sends no browser Origin
// restrictions of its own) call these functions, but CORS headers are still
// required because Supabase's Edge Runtime fronts every function with an
// HTTP gateway that performs a preflight OPTIONS check.
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

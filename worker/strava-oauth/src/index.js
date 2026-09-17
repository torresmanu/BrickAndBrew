/**
 * Strava OAuth token exchange. The iOS app never sees STRAVA_CLIENT_SECRET.
 *
 * Deploy: wrangler deploy
 * Secrets: wrangler secret put STRAVA_CLIENT_ID
 *          wrangler secret put STRAVA_CLIENT_SECRET
 */

const STRAVA_TOKEN_URL = "https://www.strava.com/oauth/token";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    if (!env.STRAVA_CLIENT_ID || !env.STRAVA_CLIENT_SECRET) {
      return json({ error: "Server is missing Strava credentials" }, 500);
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: "Expected JSON body" }, 400);
    }

    const params = new URLSearchParams();
    params.set("client_id", env.STRAVA_CLIENT_ID);
    params.set("client_secret", env.STRAVA_CLIENT_SECRET);

    if (path === "/token") {
      if (!payload.code || typeof payload.code !== "string") {
        return json({ error: "Missing authorization code" }, 400);
      }
      params.set("code", payload.code);
      params.set("grant_type", "authorization_code");
    } else if (path === "/refresh") {
      if (!payload.refresh_token || typeof payload.refresh_token !== "string") {
        return json({ error: "Missing refresh token" }, 400);
      }
      params.set("refresh_token", payload.refresh_token);
      params.set("grant_type", "refresh_token");
    } else {
      return json({ error: "Not found" }, 404);
    }

    const stravaResponse = await fetch(STRAVA_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params,
    });

    const text = await stravaResponse.text();
    return new Response(text, {
      status: stravaResponse.status,
      headers: {
        "Content-Type": "application/json",
        ...corsHeaders,
      },
    });
  },
};

function json(body, status) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

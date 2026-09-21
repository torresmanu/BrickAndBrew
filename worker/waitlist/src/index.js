/**
 * Public waitlist intake for the marketing site.
 * Stores one record per email in KV. Never returns the list over HTTP.
 *
 * Deploy: wrangler deploy
 * Binding: WAITLIST (KV)
 */

const EMAIL_MAX_LENGTH = 254;
const RATE_LIMIT_MAX = 8;
const RATE_LIMIT_SECONDS = 3600;
const ALLOWED_METHODS = "POST, OPTIONS";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";
    const cors = corsHeaders(origin);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (path !== "/waitlist") {
      return json({ error: "Not found" }, 404, cors);
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405, cors);
    }

    if (!isAllowedOrigin(origin)) {
      return json({ error: "Forbidden" }, 403, corsHeaders(""));
    }

    return handleJoin(request, env, cors);
  },
};

async function handleJoin(request, env, cors) {
  if (!env.WAITLIST) {
    return json({ error: "Waitlist is not configured" }, 503, cors);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "Expected JSON body" }, 400, cors);
  }

  // Honeypot: bots fill hidden fields. Pretend success so they move on.
  if (hasHoneypot(payload)) {
    return json({ ok: true }, 200, cors);
  }

  const email = normalizeEmail(payload.email);
  if (!email) {
    return json({ error: "Enter a valid email" }, 400, cors);
  }

  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const limited = await isRateLimited(env.WAITLIST, ip);
  if (limited) {
    return json({ error: "Too many attempts. Try again in a moment." }, 429, cors);
  }

  try {
    await stampRateLimit(env.WAITLIST, ip);

    const key = await emailKey(email);
    const existing = await env.WAITLIST.get(key);
    if (existing) {
      return json({ ok: true, alreadyJoined: true }, 200, cors);
    }

    const record = JSON.stringify({
      email,
      createdAt: new Date().toISOString(),
    });
    await env.WAITLIST.put(key, record);

    return json({ ok: true, alreadyJoined: false }, 201, cors);
  } catch (error) {
    console.error("waitlist write failed", error instanceof Error ? error.message : "unknown");
    return json({ error: "Could not save that email" }, 500, cors);
  }
}

function normalizeEmail(value) {
  if (typeof value !== "string") {
    return null;
  }
  const email = value.trim().toLowerCase();
  if (!email || email.length > EMAIL_MAX_LENGTH) {
    return null;
  }
  if (!EMAIL_PATTERN.test(email)) {
    return null;
  }
  return email;
}

function hasHoneypot(payload) {
  const trap = payload && payload.company;
  return typeof trap === "string" && trap.trim().length > 0;
}

async function emailKey(email) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(email));
  const hex = [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
  return `email:${hex}`;
}

async function isRateLimited(kv, ip) {
  const count = Number(await kv.get(rateKey(ip))) || 0;
  return count >= RATE_LIMIT_MAX;
}

async function stampRateLimit(kv, ip) {
  const count = (Number(await kv.get(rateKey(ip))) || 0) + 1;
  await kv.put(rateKey(ip), String(count), { expirationTtl: RATE_LIMIT_SECONDS });
}

function rateKey(ip) {
  return `rate:${ip}`;
}

function isAllowedOrigin(origin) {
  if (origin === "https://torresmanu.github.io") {
    return true;
  }
  try {
    const url = new URL(origin);
    return url.hostname === "localhost" || url.hostname === "127.0.0.1";
  } catch {
    return false;
  }
}

function corsHeaders(origin) {
  const allowOrigin = isAllowedOrigin(origin) ? origin : "https://torresmanu.github.io";
  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Methods": ALLOWED_METHODS,
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function json(body, status, cors) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...cors,
    },
  });
}

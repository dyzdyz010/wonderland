import type { NewCommentRow } from "./schema";

export type CommentValidationResult =
  | {
      ok: true;
      input: {
        threadKey: string;
        authorName: string;
        authorEmail: string;
        authorUrl: string | null;
        content: string;
        parentId: number | null;
        returnTo: string;
        turnstileToken: string;
      };
    }
  | { ok: false; status: number; error: string };

export type CommentInsertResult =
  | { ok: true; values: NewCommentRow; redirectPath: string }
  | { ok: false; status: number; error: string };

type BuildCommentInsertOptions = {
  threadKey: string;
  formData: FormData;
  request: Request;
  env: Record<string, unknown>;
  verifyTurnstile?: typeof verifyTurnstileToken;
};

const MAX_THREAD_KEY = 200;
const MAX_NAME = 80;
const MAX_URL = 300;
const MAX_COMMENT = 5000;
const THREAD_KEY_RE = /^[A-Za-z0-9][A-Za-z0-9._/-]*$/;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function normalizeCommentThreadKey(raw: string | undefined | null): string {
  const value = String(raw ?? "")
    .trim()
    .replace(/^\/+/, "")
    .replace(/\/+$/, "");

  if (
    !value ||
    value.length > MAX_THREAD_KEY ||
    value.includes("://") ||
    value.includes("?") ||
    value.includes("#") ||
    value.includes("//") ||
    !THREAD_KEY_RE.test(value)
  ) {
    throw new Error("Invalid comment thread");
  }

  return value;
}

function formString(formData: FormData, key: string): string {
  return String(formData.get(key) ?? "").trim();
}

function normalizeAuthorUrl(raw: string): string | null {
  if (!raw) return null;
  if (raw.length > MAX_URL) throw new Error("Website URL is too long");
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new Error("Website URL is invalid");
  }
  if (!["http:", "https:"].includes(url.protocol)) {
    throw new Error("Website URL must use http or https");
  }
  return url.toString();
}

function normalizeReturnPath(raw: string, threadKey: string): string {
  const fallback = `/article/${threadKey}/`;
  if (!raw || !raw.startsWith("/") || raw.startsWith("//") || raw.includes("://")) return fallback;
  const [pathOnly] = raw.split("#", 1);
  return pathOnly || fallback;
}

export function validateCommentFormInput(options: {
  threadKey: string;
  formData: FormData;
}): CommentValidationResult {
  let threadKey: string;
  try {
    threadKey = normalizeCommentThreadKey(options.threadKey);
  } catch {
    return { ok: false, status: 400, error: "Invalid comment thread" };
  }

  if (formString(options.formData, "website")) {
    return { ok: false, status: 400, error: "Comment rejected" };
  }

  const authorName = formString(options.formData, "author_name");
  const authorEmail = formString(options.formData, "author_email").toLowerCase();
  const rawAuthorUrl = formString(options.formData, "author_url");
  const content = formString(options.formData, "content");
  const rawParentId = formString(options.formData, "parent_id");
  const returnTo = normalizeReturnPath(formString(options.formData, "return_to"), threadKey);
  const turnstileToken = formString(options.formData, "cf-turnstile-response");

  if (!authorName) return { ok: false, status: 400, error: "Name is required" };
  if (authorName.length > MAX_NAME) return { ok: false, status: 400, error: "Name is too long" };
  if (authorEmail && !EMAIL_RE.test(authorEmail)) {
    return { ok: false, status: 400, error: "Email is invalid" };
  }
  if (!content) return { ok: false, status: 400, error: "Comment is required" };
  if (content.length > MAX_COMMENT) return { ok: false, status: 400, error: "Comment too long" };
  if (rawParentId) {
    return { ok: false, status: 400, error: "Replies are not supported yet" };
  }

  let authorUrl: string | null;
  try {
    authorUrl = normalizeAuthorUrl(rawAuthorUrl);
  } catch (error) {
    return { ok: false, status: 400, error: error instanceof Error ? error.message : "Website URL is invalid" };
  }

  return {
    ok: true,
    input: {
      threadKey,
      authorName,
      authorEmail,
      authorUrl,
      content,
      parentId: null,
      returnTo,
      turnstileToken,
    },
  };
}

function clientIp(request: Request): string {
  return (
    request.headers.get("CF-Connecting-IP") ||
    request.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() ||
    request.headers.get("X-Real-IP") ||
    ""
  );
}

export async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(hash)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function verifyTurnstileToken(
  token: string,
  secret: string,
  remoteIp?: string,
): Promise<boolean> {
  if (!token || !secret) return false;
  const body = new URLSearchParams();
  body.set("secret", secret);
  body.set("response", token);
  if (remoteIp) body.set("remoteip", remoteIp);

  const response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!response.ok) return false;
  const result = (await response.json()) as { success?: boolean };
  return result.success === true;
}

export async function buildCommentInsert(options: BuildCommentInsertOptions): Promise<CommentInsertResult> {
  const validation = validateCommentFormInput({
    threadKey: options.threadKey,
    formData: options.formData,
  });
  if (!validation.ok) return validation;

  const ip = clientIp(options.request);
  const secret = typeof options.env.TURNSTILE_SECRET_KEY === "string" ? options.env.TURNSTILE_SECRET_KEY : "";
  if (secret) {
    const verify = options.verifyTurnstile ?? verifyTurnstileToken;
    const verified = await verify(validation.input.turnstileToken, secret, ip || undefined);
    if (!verified) {
      return { ok: false, status: 400, error: "Human verification failed" };
    }
  }

  const now = Date.now();
  const emailHash = validation.input.authorEmail ? await sha256Hex(validation.input.authorEmail) : null;
  const ipHash = ip ? await sha256Hex(ip) : null;
  const userAgent = options.request.headers.get("User-Agent") || "";
  const userAgentHash = userAgent ? await sha256Hex(userAgent) : null;

  return {
    ok: true,
    redirectPath: `${validation.input.returnTo}#comments`,
    values: {
      thread_key: validation.input.threadKey,
      post_slug: validation.input.threadKey,
      author_name: validation.input.authorName,
      author_email: "",
      email_hash: emailHash,
      author_url: validation.input.authorUrl,
      content: validation.input.content,
      status: "approved",
      parent_id: validation.input.parentId,
      ip_hash: ipHash,
      user_agent_hash: userAgentHash,
      created_at: now,
      updated_at: now,
    },
  };
}

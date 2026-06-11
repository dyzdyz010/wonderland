import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import {
  buildCommentInsert,
  normalizeCommentThreadKey,
  validateCommentFormInput,
} from "../src/features/comments/validation";

function form(overrides: Record<string, string> = {}) {
  const data = new FormData();
  data.set("author_name", overrides.author_name ?? "Kris");
  data.set("author_email", overrides.author_email ?? "kris@example.com");
  data.set("author_url", overrides.author_url ?? "https://example.com");
  data.set("content", overrides.content ?? "This is a thoughtful comment.");
  data.set("return_to", overrides.return_to ?? "/zh/article/meta/2026/example/");
  for (const [key, value] of Object.entries(overrides)) {
    if (!["author_name", "author_email", "author_url", "content", "return_to"].includes(key)) {
      data.set(key, value);
    }
  }
  return data;
}

describe("comments validation", () => {
  test("normalizes i18nKey comment threads and rejects URL-like thread keys", () => {
    expect(normalizeCommentThreadKey("/meta/2026/example/")).toBe("meta/2026/example");
    expect(normalizeCommentThreadKey("mmo-server-from-scratch/2022/20220608-mmo-server-from-scratch(0)-introduction")).toBe(
      "mmo-server-from-scratch/2022/20220608-mmo-server-from-scratch(0)-introduction",
    );
    expect(() => normalizeCommentThreadKey("https://evil.example/post")).toThrow("Invalid comment thread");
  });

  test("validates comments without retaining raw email", async () => {
    const result = await buildCommentInsert({
      threadKey: "meta/2026/example",
      formData: form(),
      request: new Request("https://dyz.io/api/comments/meta/2026/example", {
        headers: {
          "CF-Connecting-IP": "203.0.113.10",
          "User-Agent": "Wonderland Test Browser",
        },
      }),
      env: {},
    });

    expect(result.ok).toBe(true);
    if (!result.ok) throw new Error(result.error);
    expect(result.values.thread_key).toBe("meta/2026/example");
    expect(result.values.status).toBe("approved");
    expect(result.values.author_email).toBe("");
    expect(result.values.email_hash).toMatch(/^[a-f0-9]{64}$/);
    expect(result.values.ip_hash).toMatch(/^[a-f0-9]{64}$/);
    expect(result.redirectPath).toBe("/zh/article/meta/2026/example/#comments");
  });

  test("stores an empty website as an empty string for legacy D1 compatibility", async () => {
    const result = await buildCommentInsert({
      threadKey: "meta/2026/example",
      formData: form({ author_url: "" }),
      request: new Request("https://dyz.io/api/comments/meta/2026/example"),
      env: {},
    });

    expect(result.ok).toBe(true);
    if (!result.ok) throw new Error(result.error);
    expect(result.values.author_url).toBe("");
  });

  test("rejects honeypot submissions and overly long comments", () => {
    expect(validateCommentFormInput({ threadKey: "meta/2026/example", formData: form({ website: "bot" }) }).ok).toBe(false);
    expect(validateCommentFormInput({ threadKey: "meta/2026/example", formData: form({ content: "x".repeat(5001) }) }).ok).toBe(false);
  });

  test("requires a Turnstile token when the secret is configured", async () => {
    const result = await buildCommentInsert({
      threadKey: "meta/2026/example",
      formData: form(),
      request: new Request("https://dyz.io/api/comments/meta/2026/example"),
      env: { TURNSTILE_SECRET_KEY: "secret" },
      verifyTurnstile: async () => false,
    });

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected Turnstile failure");
    expect(result.status).toBe(400);
    expect(result.error).toContain("verification");
  });
});

describe("D1 comment migrations", () => {
  test("initial migration is production-safe and contains no seed comments", () => {
    const initSql = readFileSync(new URL("../migrations/0001_init.sql", import.meta.url), "utf8");
    const hardenSql = readFileSync(new URL("../migrations/0002_harden_comments.sql", import.meta.url), "utf8");
    const allSql = `${initSql}\n${hardenSql}`;
    expect(allSql).not.toMatch(/\bDROP\s+TABLE\b/i);
    expect(allSql).not.toMatch(/\bINSERT\s+INTO\s+comments\b/i);
    expect(allSql).toMatch(/thread_key\s+TEXT\s+NOT\s+NULL/i);
    expect(allSql).toMatch(/status\s+TEXT\s+NOT\s+NULL/i);
  });
});

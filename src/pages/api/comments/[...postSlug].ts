import type { APIRoute } from "astro";
import { drizzle } from "drizzle-orm/d1";
import { commentsTable } from "../../../tables/comment";

export const prerender = false; // 确保端点是实时的（hybrid/static 模式下必写）

export const POST: APIRoute = async ({ request, params, locals, redirect }) => {
  const db = drizzle(locals.runtime.env.DB); // Cloudflare D1 绑定
  const postSlug = params.postSlug!;

  const data = await request.formData();

  const authorName = String(data.get("author_name") ?? "").trim();
  const authorEmail = String(data.get("author_email") ?? "").trim();
  const authorUrl = String(data.get("author_url") ?? "").trim();
  const content = String(data.get("content") ?? "").trim();

  // 基本输入验证
  if (!authorName || !authorEmail || !content) {
    return new Response("Missing required fields", { status: 400 });
  }
  if (content.length > 5000) {
    return new Response("Comment too long", { status: 400 });
  }

  await db.insert(commentsTable).values({
    post_slug: postSlug,
    author_name: authorName,
    author_email: authorEmail,
    author_url: authorUrl,
    content: content,
    created_at: Date.now(),
  });

  // 固定重定向路径，防止开放重定向
  return redirect(`/article/${postSlug}#comments`, 303);
};

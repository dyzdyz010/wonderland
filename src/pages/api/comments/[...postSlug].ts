import type { APIRoute } from "astro";
import { drizzle } from "drizzle-orm/d1";
import { commentsTable } from "../../../tables/comment";
import { getClientIP } from "../../../utils/comment";

export const prerender = false; // 确保端点是实时的（hybrid/static 模式下必写）

export const POST: APIRoute = async ({ request, params, locals, redirect }) => {
  const db = drizzle(locals.runtime.env.DB); // Cloudflare D1 绑定
  const postSlug = params.postSlug!;

  console.log("postSlug", postSlug);

  const data = await request.formData();
  console.log("data", data);
  await db.insert(commentsTable).values({
    post_slug: postSlug,
    author_name: String(data.get("author_name") ?? ""),
    author_email: String(data.get("author_email") ?? ""),
    author_url: String(data.get("author_url") ?? ""),
    content: String(data.get("content") ?? ""),
    created_at: Date.now(),
  });

  const back = String(data.get("return_to") ?? `/article/${postSlug}`);
  return redirect(`${back}#comments`, 303); // 提交后回跳
};

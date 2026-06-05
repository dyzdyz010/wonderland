import type { APIRoute } from "astro";
import { insertComment } from "../../../features/comments/db";
import { buildCommentInsert } from "../../../features/comments/validation";

export const prerender = false;

export const POST: APIRoute = async ({ request, params, locals, redirect }) => {
  const threadKey = params.postSlug;
  const formData = await request.formData();
  const runtimeEnv = locals.runtime?.env ?? {};

  const result = await buildCommentInsert({
    threadKey,
    formData,
    request,
    env: runtimeEnv,
  });

  if (!result.ok) {
    return new Response(result.error, { status: result.status });
  }

  try {
    await insertComment(runtimeEnv, result.values);
  } catch (error) {
    console.error("Failed to store comment", error);
    return new Response("Comments are temporarily unavailable", { status: 503 });
  }

  return redirect(result.redirectPath, 303);
};

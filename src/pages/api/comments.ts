import type { APIRoute } from "astro";

export const prerender = false; // 这个 API 需要 SSR

interface Comment {
  id?: number;
  article_id: string;
  author_name: string;
  author_email?: string;
  content: string;
  parent_id?: number;
  created_at?: string;
  status?: string;
  ip_address?: string;
}

// GET /api/comments?articleId=xxx
export const GET: APIRoute = async ({ request, locals }) => {
  const runtime = locals.runtime as any;
  const db = runtime?.env?.DB;

  if (!db) {
    return new Response(JSON.stringify({ error: "Database not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(request.url);
  const articleId = url.searchParams.get("articleId");

  if (!articleId) {
    return new Response(JSON.stringify({ error: "Article ID required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { results } = await db
      .prepare(
        `SELECT * FROM comments 
       WHERE article_id = ? AND status = 'approved' 
       ORDER BY created_at DESC`
      )
      .bind(articleId)
      .all();

    return new Response(JSON.stringify({ comments: results }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};

// POST /api/comments
export const POST: APIRoute = async ({ request, locals, clientAddress }) => {
  const runtime = locals.runtime as any;
  const db = runtime?.env?.DB;

  if (!db) {
    return new Response(JSON.stringify({ error: "Database not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body: Comment = await request.json();
    const { article_id, author_name, author_email, content, parent_id } = body;

    // 验证必填字段
    if (!article_id || !author_name || !content) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 内容验证
    if (content.length < 3 || content.length > 1000) {
      return new Response(
        JSON.stringify({
          error: "Comment must be between 3 and 1000 characters",
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // 获取 IP 地址
    const ipAddress =
      request.headers.get("CF-Connecting-IP") ||
      request.headers.get("X-Forwarded-For") ||
      clientAddress ||
      "unknown";

    // 插入评论
    const result = await db
      .prepare(
        `INSERT INTO comments (article_id, author_name, author_email, content, parent_id, ip_address, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`
      )
      .bind(
        article_id,
        author_name,
        author_email || null,
        content,
        parent_id || null,
        ipAddress
      )
      .run();

    return new Response(
      JSON.stringify({
        success: true,
        message: "Comment submitted for review",
        id: result.meta.last_row_id,
      }),
      {
        status: 201,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error: any) {
    console.error("Error saving comment:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
};

// OPTIONS 请求处理 CORS
export const OPTIONS: APIRoute = async () => {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
};

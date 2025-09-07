// 获取用户IP地址的函数
function getClientIP(request: Request): string {
  // Cloudflare 在这些 header 中提供真实IP
  const cfConnectingIP = request.headers.get("CF-Connecting-IP");
  const xForwardedFor = request.headers.get("X-Forwarded-For");
  const xRealIP = request.headers.get("X-Real-IP");

  // 优先使用 CF-Connecting-IP（Cloudflare专用）
  return (
    cfConnectingIP ||
    xForwardedFor?.split(",")[0].trim() ||
    xRealIP ||
    "unknown"
  );
}

export { getClientIP };

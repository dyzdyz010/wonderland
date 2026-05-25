export type NavigationActiveMatch = "exact" | "prefix";

export function normalizeNavigationPath(path: string): string {
  const [pathname = ""] = path.split(/[?#]/, 1);
  const normalized = pathname || "/";
  return normalized.endsWith("/") && normalized !== "/" ? normalized.slice(0, -1) : normalized;
}

export function isNavigationLinkActive(
  href: string,
  pathname: string,
  activeMatch: NavigationActiveMatch = "prefix",
): boolean {
  const normalizedHref = normalizeNavigationPath(href);
  const normalizedPath = normalizeNavigationPath(pathname);

  if (activeMatch === "exact") return normalizedHref === normalizedPath;
  return normalizedHref === normalizedPath || normalizedPath.startsWith(`${normalizedHref}/`);
}

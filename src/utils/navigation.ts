import { DEFAULT_LOCALE } from "../i18n/config";

export type NavigationActiveMatch = "exact" | "prefix";

export function normalizeNavigationPath(path: string): string {
  const [pathname = ""] = path.split(/[?#]/, 1);
  const normalized = pathname || "/";
  const withLeadingSlash = normalized.startsWith("/") ? normalized : `/${normalized}`;
  return withLeadingSlash.endsWith("/") && withLeadingSlash !== "/" ? withLeadingSlash.slice(0, -1) : withLeadingSlash;
}

export function isNavigationLinkActive(
  href: string,
  pathname: string,
  activeMatch: NavigationActiveMatch = "prefix",
): boolean {
  const normalizedHref = normalizeNavigationPath(href);
  const normalizedPath = normalizeNavigationPath(pathname);
  const defaultLocaleRoot = `/${DEFAULT_LOCALE}`;

  if (activeMatch === "exact") {
    return normalizedHref === normalizedPath || (normalizedPath === "/" && normalizedHref === defaultLocaleRoot);
  }
  return normalizedHref === normalizedPath || normalizedPath.startsWith(`${normalizedHref}/`);
}

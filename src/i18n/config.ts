export const LOCALES = ["zh", "en"] as const;
export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = "en";

export const LOCALE_NAMES: Record<Locale, string> = {
  zh: "中文",
  en: "English",
};

export const HTML_LANG: Record<Locale, string> = {
  zh: "zh-CN",
  en: "en",
};

export function isLocale(value: string | undefined | null): value is Locale {
  return LOCALES.includes(value as Locale);
}

export function assertLocale(value: string | undefined | null): Locale {
  if (isLocale(value)) return value;
  throw new Error(`[i18n] Unsupported locale: ${value ?? "<missing>"}`);
}

export function otherLocale(locale: Locale): Locale {
  return locale === "zh" ? "en" : "zh";
}

export function withLocale(locale: Locale, path = ""): string {
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  if (normalizedPath === "/") return `/${locale}/`;
  return `/${locale}${normalizedPath}`;
}

export function normalizeSlug(slug: string): string {
  return slug.replace(/^\/+|\/+$/g, "");
}

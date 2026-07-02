import { DEFAULT_LOCALE, LOCALES, type Locale, withLocale } from "./config";

export interface AlternateLink {
  locale: Locale | "x-default";
  href: string;
}

export function localizedAlternates(path: string, xDefaultLocale: Locale = DEFAULT_LOCALE): AlternateLink[] {
  const byLocale = LOCALES.map((locale) => ({ locale, href: withLocale(locale, path) }));
  return [...byLocale, { locale: "x-default", href: withLocale(xDefaultLocale, path) }];
}

export function ogLocale(locale: Locale): string {
  return locale === "zh" ? "zh_CN" : "en_US";
}
